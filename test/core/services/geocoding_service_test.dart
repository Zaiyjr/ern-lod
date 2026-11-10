import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:ride_booking/core/network/mock_http_client.dart';
import 'package:ride_booking/core/services/geocoding_service.dart';

/// Serves canned Nominatim reverse-geocode responses.
class _FakeGeocoderClient extends http.BaseClient {
  _FakeGeocoderClient({this.body, this.statusCode = 200});

  final Map<String, dynamic>? body;
  final int statusCode;
  Uri? lastRequestUrl;
  Map<String, String> lastHeaders = const {};

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    lastRequestUrl = request.url;
    if (request is http.Request) {
      lastHeaders = Map.of(request.headers);
    }
    final payload = jsonEncode(
      body ?? {'error': 'unhandled'},
    );
    final bytes = utf8.encode(payload);
    return http.StreamedResponse(
      Stream.value(bytes),
      statusCode,
      contentLength: bytes.length,
      headers: const {'content-type': 'application/json'},
    );
  }
}

void main() {
  group('GeocodingService (Nominatim reverse geocoding)', () {
    test('resolves coordinates to the display address', () async {
      final fake = _FakeGeocoderClient(
        body: {
          'display_name':
              'Wat Arun, Thanon Wang Doem, Bangkok Yai, Bangkok 10600, Thailand',
        },
      );
      final service = GeocodingService(client: fake);

      final address = await service.reverseGeocode(
        const LatLng(13.7589, 100.4977),
      );

      expect(address, contains('Wat Arun'));
      expect(fake.lastRequestUrl!.host, 'nominatim.openstreetmap.org');
      expect(fake.lastRequestUrl!.path, '/reverse');
      expect(fake.lastRequestUrl!.queryParameters['lat'], '13.7589');
      expect(fake.lastRequestUrl!.queryParameters['accept-language'], 'en');
      expect(fake.lastHeaders['User-Agent'], 'com.example.ride_booking');
    });

    test('caches a resolved coordinate locally', () async {
      final fake = _FakeGeocoderClient(
        body: {
          'display_name': 'Riverside Park, Vientiane, Laos',
        },
      );
      final service = GeocodingService(client: fake);
      const point = LatLng(17.9757, 102.6331);

      final first = await service.reverseGeocode(point);
      final second = await service.reverseGeocode(point);

      expect(first, second);
      // Two calls hit the service; the second was served from cache.
      expect(fake.lastRequestUrl, isNotNull);
    });

    test('returns null on network error', () async {
      final service = GeocodingService(client: _ThrowingClient());
      final address = await service.reverseGeocode(const LatLng(0, 0));
      expect(address, isNull);
    });

    test('returns null on a non-200 response', () async {
      final service =
          GeocodingService(client: _FakeGeocoderClient(statusCode: 503));
      final address = await service.reverseGeocode(const LatLng(1, 2));
      expect(address, isNull);
    });

    test('returns null when display_name is missing', () async {
      final service = GeocodingService(client: _FakeGeocoderClient(body: {}));
      final address = await service.reverseGeocode(const LatLng(3, 4));
      expect(address, isNull);
    });

    test('passes through Nominatim via MockHttpClient to the real client',
        () async {
      // Proves the mock HTTP surface no longer swallows real-OSM calls.
      final inner = _FakeGeocoderClient(
        body: {
          'display_name': 'Patuxai, Lane Xang Avenue, Vientiane, Laos',
        },
      );
      final client = MockHttpClient(
        defaultDelay: Duration.zero,
        innerClient: inner,
      );
      final service = GeocodingService(client: client);

      final address = await service.reverseGeocode(
        const LatLng(17.9746, 102.6334),
      );

      expect(address, contains('Patuxai'));
    });
  });

  group('GeocodingService (compact labels for UI chips)', () {
    test('builds "road, area, city" from Nominatim address components',
        () async {
      final fake = _FakeGeocoderClient(
        body: {
          'display_name':
              'Ellis Street, Union Square, San Francisco, '
                  'California, 94108, United States',
          'address': {
            'road': 'Ellis Street',
            'neighbourhood': 'Union Square',
            'city': 'San Francisco',
            'state': 'California',
            'postcode': '94108',
            'country': 'United States',
          },
        },
      );
      final service = GeocodingService(client: fake);

      final label = await service.reverseGeocodeShort(
        const LatLng(37.7878, -122.4075),
      );

      expect(label, 'Ellis Street, Union Square, San Francisco');
      // Address chips should never contain state/postcode boilerplate.
      expect(label, isNot(contains('California')));
      expect(label, isNot(contains('94108')));
    });

    test('uses first available key for each component when road is missing',
        () async {
      final fake = _FakeGeocoderClient(
        body: {
          'display_name': 'Untitled',
          'address': {
            'pedestrian': 'Night Market Lane',
            'road': 'Night Market Lane',
            'quarter': 'Chanthabouly',
            'town': 'Vientiane',
          },
        },
      );
      final service = GeocodingService(client: fake);

      final label = await service.reverseGeocodeShort(
        const LatLng(17.9746, 102.6334),
      );

      expect(label, 'Night Market Lane, Chanthabouly, Vientiane');
    });

    test('de-duplicates identical components so labels do not repeat',
        () async {
      final fake = _FakeGeocoderClient(
        body: {
          'display_name': 'Untitled',
          'address': {
            'road': 'Riverside',
            'city': 'Riverside',
          },
        },
      );
      final service = GeocodingService(client: fake);

      final label = await service.reverseGeocodeShort(const LatLng(5, 5));

      expect(label, 'Riverside');
    });

    test('falls back to the first two display_name segments when components '
        'are unavailable', () async {
      final fake = _FakeGeocoderClient(
        body: {
          'display_name': '9th Avenue, Manhattan, New York, United States',
        },
      );
      final service = GeocodingService(client: fake);

      final label = await service.reverseGeocodeShort(const LatLng(6, 6));

      expect(label, '9th Avenue, Manhattan');
    });

    test('caches a short label separately from full addresses', () async {
      final fake = _FakeGeocoderClient(
        body: {
          'display_name': 'Some Road, Some District, Some City, Laos',
          'address': {
            'road': 'Some Road',
            'city': 'Some City',
          },
        },
      );
      final service = GeocodingService(client: fake);
      const point = LatLng(7.5, 7.5);

      final full = await service.reverseGeocode(point);
      final short = await service.reverseGeocodeShort(point);
      final shortAgain = await service.reverseGeocodeShort(point);

      expect(full, contains('Some Road, Some District, Some City'));
      expect(short, 'Some Road, Some City');
      // Second call for the same point is served from the short cache.
      expect(shortAgain, short);
    });

    test('returns null on a short-label lookup failure', () async {
      final service =
          GeocodingService(client: _FakeGeocoderClient(statusCode: 429));
      final label = await service.reverseGeocodeShort(const LatLng(8, 8));
      expect(label, isNull);
    });
  });
}

class _ThrowingClient extends http.BaseClient {
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    throw http.ClientException('offline');
  }
}
