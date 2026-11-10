import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

/// Reverse geocoding via the OpenStreetMap Nominatim API: turns map/GPS
/// coordinates into a human-readable address ("real-time address").
///
/// Requests use the OSM tile user-agent policy (com.example.ride_booking).
class GeocodingService {
  GeocodingService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  /// Lookup caches keyed by ~0.1m-precision coordinates, so repeated GPS
  /// ticks near the same point don't spam the free-tier Nominatim
  /// endpoint. [fullCache] holds display addresses; [shortCache] holds
  /// compact road/area/city labels for UI chips.
  final Map<String, String?> _fullCache = {};
  final Map<String, String?> _shortCache = {};

  static const String _authority = 'nominatim.openstreetmap.org';

  /// Per the OSM usage policy, requests must carry a meaningful UA.
  static const String _userAgent = 'com.example.ride_booking';

  /// Resolves [point] to a display address, or null on any failure.
  Future<String?> reverseGeocode(LatLng point, {int zoom = 18}) async {
    final key =
        '${point.latitude.toStringAsFixed(6)},${point.longitude.toStringAsFixed(6)}';
    if (_fullCache.containsKey(key)) return _fullCache[key];

    final uri = Uri.https(_authority, '/reverse', {
      'format': 'jsonv2',
      'lat': point.latitude.toString(),
      'lon': point.longitude.toString(),
      'zoom': '$zoom',
      'addressdetails': '1',
      'accept-language': 'en',
    });

    http.Response response;
    try {
      response = await _client.get(
        uri,
        headers: {'User-Agent': _userAgent, 'Accept': 'application/json'},
      );
    } catch (e) {
      debugPrint('[GeocodingService] Reverse geocode failed: $e');
      return null;
    }

    if (response.statusCode != 200) {
      debugPrint('[GeocodingService] Reverse geocode '
          'status ${response.statusCode}');
      return null;
    }

    try {
      final body = jsonDecode(utf8.decode(response.bodyBytes))
          as Map<String, dynamic>;
      final address = (body['display_name'] as String?)?.trim();
      _fullCache[key] = address;
      return address;
    } catch (e) {
      debugPrint('[GeocodingService] Invalid response body: $e');
      return null;
    }
  }

  /// Same lookup as [reverseGeocode] but returns a compact label built
  /// from Nominatim address components (road · area · city), e.g.
  /// "Ellis Street, Union Square, San Francisco" — sized for UI chips.
  Future<String?> reverseGeocodeShort(LatLng point, {int zoom = 18}) async {
    final key =
        '${point.latitude.toStringAsFixed(6)},${point.longitude.toStringAsFixed(6)}';
    if (_shortCache.containsKey(key)) return _shortCache[key];

    final uri = Uri.https(_authority, '/reverse', {
      'format': 'jsonv2',
      'lat': point.latitude.toString(),
      'lon': point.longitude.toString(),
      'zoom': '$zoom',
      'addressdetails': '1',
      'accept-language': 'en',
    });

    http.Response response;
    try {
      response = await _client.get(
        uri,
        headers: {'User-Agent': _userAgent, 'Accept': 'application/json'},
      );
    } catch (e) {
      debugPrint('[GeocodingService] Short geocode failed: $e');
      return null;
    }

    if (response.statusCode != 200) {
      debugPrint('[GeocodingService] Short geocode status ${response.statusCode}');
      return null;
    }

    try {
      final body = jsonDecode(utf8.decode(response.bodyBytes))
          as Map<String, dynamic>;
      final fallback = (body['display_name'] as String?)
          ?.split(',')
          .map((part) => part.trim())
          .where((part) => part.isNotEmpty)
          .take(2)
          .join(', ');
      final address = _compactAddress(body['address']) ?? fallback;
      _shortCache[key] = address;
      return address;
    } catch (e) {
      debugPrint('[GeocodingService] Invalid response body: $e');
      return null;
    }
  }

  /// Builds "road, area, city" from the Nominatim address-components map.
  static String? _compactAddress(Object? raw) {
    if (raw is! Map<String, dynamic>) return null;
    final road = _firstOf(raw, const [
      'road',
      'pedestrian',
      'footway',
      'residential',
    ]);
    final area = _firstOf(raw, const [
      'neighbourhood',
      'suburb',
      'city_district',
      'quarter',
    ]);
    final city = _firstOf(raw, const [
      'city',
      'town',
      'village',
      'municipality',
    ]);
    // Dedupe while preserving order (same component can appear at
    // multiple keys, e.g. road == pedestrian).
    final parts = <String>[];
    for (final part in [?road, ?area, ?city]) {
      if (!parts.contains(part)) {
        parts.add(part);
      }
    }
    return parts.isEmpty ? null : parts.join(', ');
  }

  static String? _firstOf(Map<String, dynamic> map, List<String> keys) {
    for (final key in keys) {
      final value = map[key];
      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }
    }
    return null;
  }

  /// Ensures the shared [http.Client] is dropped for GC.
  void dispose() {
    _client.close();
  }
}
