import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

/// Real-time device location provider and stream manager.
class LocationService {
  static const LatLng defaultFallback = LatLng(13.7563, 100.5018); // Default fallback

  StreamSubscription<Position>? _positionSubscription;

  /// Determines device location permissions and fetches current position.
  Future<LatLng?> getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('[LocationService] Location services are disabled on device.');
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          debugPrint('[LocationService] Location permission denied by user.');
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        debugPrint('[LocationService] Location permissions are permanently denied.');
        return null;
      }

      // 1. Try quick last known position first for instant UI responsiveness
      final lastKnown = await Geolocator.getLastKnownPosition();
      if (lastKnown != null) {
        debugPrint('[LocationService] Using last known location: (${lastKnown.latitude}, ${lastKnown.longitude})');
      }

      // 2. Fetch fresh high/medium accuracy position
      try {
        final position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.medium,
            timeLimit: Duration(seconds: 6),
          ),
        );
        return LatLng(position.latitude, position.longitude);
      } catch (e) {
        debugPrint('[LocationService] Fresh location timed out or failed ($e), falling back to lastKnown: $lastKnown');
        if (lastKnown != null) {
          return LatLng(lastKnown.latitude, lastKnown.longitude);
        }
      }

      return null;
    } catch (e) {
      debugPrint('[LocationService] Error fetching location: $e');
      return null;
    }
  }

  /// Listens to real-time continuous location updates.
  Stream<LatLng> getRealtimeLocationStream({int distanceFilterMeters = 0}) async* {
    // 1. Ensure permission is granted before activating stream
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
      debugPrint('[LocationService] Cannot start stream: permission denied ($permission)');
      return;
    }

    late final LocationSettings settings;
    if (defaultTargetPlatform == TargetPlatform.iOS || defaultTargetPlatform == TargetPlatform.macOS) {
      settings = AppleSettings(
        accuracy: LocationAccuracy.best,
        distanceFilter: distanceFilterMeters,
        activityType: ActivityType.automotiveNavigation,
        pauseLocationUpdatesAutomatically: false,
        showBackgroundLocationIndicator: false,
      );
    } else {
      settings = LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: distanceFilterMeters,
      );
    }

    yield* Geolocator.getPositionStream(locationSettings: settings)
        .map((pos) => LatLng(pos.latitude, pos.longitude));
  }

  void dispose() {
    _positionSubscription?.cancel();
  }
}


