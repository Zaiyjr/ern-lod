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

  /// Lookup cache keyed by ~0.1m-precision coordinates, so repeated
  /// GPS ticks near the same point don't spam the free-tier Nominatim
  /// endpoint.
  final Map<String, String?> _cache = {};

  static const String _authority = 'nominatim.openstreetmap.org';

  /// Per the OSM usage policy, requests must carry a meaningful UA.
  static const String _userAgent = 'com.example.ride_booking';

  /// Resolves [point] to a display address, or null on any failure.
  Future<String?> reverseGeocode(LatLng point, {int zoom = 18}) async {
    final key =
        '${point.latitude.toStringAsFixed(6)},${point.longitude.toStringAsFixed(6)}';
    if (_cache.containsKey(key)) return _cache[key];

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
      _cache[key] = address;
      return address;
    } catch (e) {
      debugPrint('[GeocodingService] Invalid response body: $e');
      return null;
    }
  }

  /// Ensures the shared [http.Client] is dropped for GC.
  void dispose() {
    _client.close();
  }
}
