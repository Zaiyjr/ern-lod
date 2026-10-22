import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/services/location_service.dart';
import '../../../../core/theme/app_colors.dart';

/// Interactive OpenStreetMap background widget with real-time GPS tracking.
class OsmMapBackground extends StatefulWidget {
  const OsmMapBackground({
    super.key,
    this.initialCenter = LocationService.defaultFallback,
    this.initialZoom = 15.0,
    this.enableRealtimeLocation = true,
    this.onLocationChanged,
  });

  final LatLng initialCenter;
  final double initialZoom;
  final bool enableRealtimeLocation;
  final ValueChanged<LatLng>? onLocationChanged;

  @override
  State<OsmMapBackground> createState() => _OsmMapBackgroundState();
}

class _OsmMapBackgroundState extends State<OsmMapBackground> {
  late final MapController _mapController;
  final LocationService _locationService = LocationService();
  StreamSubscription<LatLng>? _locationSub;

  late LatLng _currentLocation;
  late List<LatLng> _mockDrivers;
  bool _hasRealLocation = false;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _currentLocation = widget.initialCenter;
    _updateMockDrivers(_currentLocation);

    if (widget.enableRealtimeLocation) {
      _initRealtimeLocation();
    }
  }

  void _updateMockDrivers(LatLng center) {
    _mockDrivers = [
      LatLng(center.latitude + 0.0035, center.longitude + 0.0032),
      LatLng(center.latitude - 0.0031, center.longitude - 0.0038),
      LatLng(center.latitude + 0.0048, center.longitude - 0.0026),
      LatLng(center.latitude - 0.0020, center.longitude + 0.0045),
    ];
  }

  Future<void> _initRealtimeLocation() async {
    final initialPos = await _locationService.getCurrentLocation();
    if (initialPos != null && mounted) {
      setState(() {
        _currentLocation = initialPos;
        _hasRealLocation = true;
        _updateMockDrivers(initialPos);
      });
      _mapController.move(initialPos, widget.initialZoom);
      widget.onLocationChanged?.call(initialPos);
    }

    // Subscribe to ongoing position stream with auto-follow
    try {
      _locationSub = _locationService.getRealtimeLocationStream().listen(
        (pos) {
          if (!mounted) return;
          setState(() {
            _currentLocation = pos;
            _hasRealLocation = true;
            _updateMockDrivers(pos);
          });
          // Smoothly pan camera as device moves
          _mapController.move(pos, _mapController.camera.zoom);
          widget.onLocationChanged?.call(pos);
        },
        onError: (err) {
          debugPrint('[OsmMapBackground] Stream listener error: $err');
        },
      );
    } catch (e) {
      debugPrint('[OsmMapBackground] Stream error: $e');
    }
  }


  void _recenter() async {
    // If we haven't obtained real location yet, trigger a fresh request with user feedback
    if (!_hasRealLocation) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Locating your position...'),
          duration: Duration(seconds: 1),
        ),
      );
      final fresh = await _locationService.getCurrentLocation();
      if (fresh != null && mounted) {
        setState(() {
          _currentLocation = fresh;
          _hasRealLocation = true;
          _updateMockDrivers(fresh);
        });
        _mapController.move(fresh, 16.0);
        widget.onLocationChanged?.call(fresh);
        return;
      }
    }
    _mapController.move(_currentLocation, 16.0);
  }


  @override
  void dispose() {
    _locationSub?.cancel();
    _locationService.dispose();
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: _currentLocation,
            initialZoom: widget.initialZoom,
            minZoom: 4,
            maxZoom: 19,
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.all,
            ),
          ),
          children: [
            // 1. OpenStreetMap Tile Layer
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.ride_booking',
            ),

            // 2. Markers: Rider GPS Position & Simulated Nearby Drivers
            MarkerLayer(
              markers: [
                // Real-time Rider GPS location marker
                Marker(
                  point: _currentLocation,
                  width: 54,
                  height: 54,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Ambient pulsing wave
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.accent.withAlpha(45),
                        ),
                      ),
                      // Core crisp marker
                      Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          border: Border.all(
                            color: AppColors.accent,
                            width: 3.5,
                          ),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x330F172A),
                              blurRadius: 8,
                              offset: Offset(0, 3),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Nearby drivers
                ..._mockDrivers.map(
                  (pos) => Marker(
                    point: pos,
                    width: 34,
                    height: 34,
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.brand,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x260F172A),
                            blurRadius: 8,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.directions_car_filled,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),

        // Recenter Floating Action Button (Thumb Zone right side)
        Positioned(
          right: 16,
          bottom: 270,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: _recenter,
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.line),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x1A0F172A),
                    blurRadius: 14,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(
                _hasRealLocation
                    ? Icons.my_location_rounded
                    : Icons.location_searching_rounded,
                color: _hasRealLocation ? AppColors.accent : AppColors.textSecondary,
                size: 22,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
