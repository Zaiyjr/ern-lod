import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/services/geocoding_service.dart';
import '../../../../core/services/location_service.dart';
import '../../../../core/theme/app_colors.dart';

/// Available map basemap styles without API key requirements.
enum AppMapType {
  streets,
  satellite,
  clean;

  String get label => switch (this) {
        streets => 'Streets (OSM)',
        satellite => 'Satellite (Esri)',
        clean => 'Clean navigation',
      };
}

/// A point chosen on the map together with its reverse-geocoded address.
class MapPointAddress {
  const MapPointAddress(this.point, this.address);

  final LatLng point;

  /// Human-readable address from OSM Nominatim, or a coordinate fallback
  /// when lookup fails.
  final String address;
}

/// Interactive OpenStreetMap background widget with real-time GPS tracking,
/// multiple map styles (Streets, Satellite, Clean), route polyline support,
/// and reverse-geocoded addresses.
class OsmMapBackground extends StatefulWidget {
  const OsmMapBackground({
    super.key,
    this.initialCenter = LocationService.defaultFallback,
    this.initialZoom = 15.5,
    this.enableRealtimeLocation = true,
    this.destinationPoint,
    this.onLocationChanged,
    this.onPickupAddressResolved,
    this.onPointSelected,
  });

  final LatLng initialCenter;
  final double initialZoom;
  final bool enableRealtimeLocation;

  /// Active destination point; when non-null, a route polyline is rendered
  /// and the camera bounds fit both pickup and destination.
  final LatLng? destinationPoint;

  final ValueChanged<LatLng>? onLocationChanged;

  /// Fires once the map resolves the GPS position to an address (and
  /// again whenever the rider moves beyond the throttle threshold).
  final ValueChanged<String>? onPickupAddressResolved;

  /// Fires when the rider taps the map to pick a location, carrying the
  /// tapped point and its resolved address.
  final void Function(MapPointAddress address)? onPointSelected;

  @override
  State<OsmMapBackground> createState() => _OsmMapBackgroundState();
}

class _OsmMapBackgroundState extends State<OsmMapBackground> {
  late final MapController _mapController;
  final LocationService _locationService = LocationService();
  final GeocodingService _geocodingService = GeocodingService();
  StreamSubscription<LatLng>? _locationSub;

  late LatLng _currentLocation;
  late List<LatLng> _mockDrivers;
  bool _hasRealLocation = false;
  bool _followUser = true;

  AppMapType _mapType = AppMapType.streets;

  /// Resolved GPS address event source — kept via callbacks only.
  bool _pickupGeocodeBusy = false;
  LatLng? _lastPickupGeocodePoint;

  /// Latest destination point picked by tapping the map.
  LatLng? _pickedPoint;
  bool _pickedGeocodeBusy = false;

  /// Minimum GPS movement before re-resolving the pickup address.
  static const double _geocodeMinDistanceMeters = 100;
  static const Distance _distance = Distance();

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

  @override
  void didUpdateWidget(covariant OsmMapBackground oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.destinationPoint != null &&
        widget.destinationPoint != oldWidget.destinationPoint) {
      _fitRouteBounds(_currentLocation, widget.destinationPoint!);
    }
  }

  void _fitRouteBounds(LatLng p1, LatLng p2) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      try {
        final bounds = LatLngBounds.fromPoints([p1, p2]);
        _mapController.fitCamera(
          CameraFit.bounds(
            bounds: bounds,
            padding: const EdgeInsets.only(
              top: 110,
              bottom: 360,
              left: 48,
              right: 48,
            ),
            maxZoom: 16.5,
          ),
        );
      } catch (e) {
        debugPrint('[OsmMapBackground] fitRouteBounds error: $e');
      }
    });
  }

  void _updateMockDrivers(LatLng center) {
    // Keep simulated drivers closer within visible street perimeter
    _mockDrivers = [
      LatLng(center.latitude + 0.0016, center.longitude + 0.0015),
      LatLng(center.latitude - 0.0014, center.longitude - 0.0016),
      LatLng(center.latitude + 0.0012, center.longitude - 0.0018),
      LatLng(center.latitude - 0.0017, center.longitude + 0.0014),
    ];
  }

  /// Reverse-geocodes the GPS address, throttled by movement distance so
  /// the free-tier Nominatim API is not hammered on every tick.
  Future<void> _resolvePickupAddress(LatLng position) async {
    if (widget.onPickupAddressResolved == null) return;
    if (_pickupGeocodeBusy) return;
    final last = _lastPickupGeocodePoint;
    if (last != null &&
        _distance.as(LengthUnit.Meter, last, position) <
            _geocodeMinDistanceMeters) {
      return;
    }
    _pickupGeocodeBusy = true;
    _lastPickupGeocodePoint = position;
    try {
      final address = await _geocodingService.reverseGeocodeShort(position);
      if (!mounted) return;
      if (address == null) return;
      setState(() {});
      widget.onPickupAddressResolved?.call(address);
    } finally {
      _pickupGeocodeBusy = false;
    }
  }

  /// Reverse-geocodes a tapped map point and reports it as the chosen destination.
  Future<void> _onMapTap(LatLng point) async {
    if (widget.onPointSelected == null) return;
    setState(() {
      _pickedPoint = point;
      _pickedGeocodeBusy = true;
      _followUser = false;
    });
    try {
      final address =
          await _geocodingService.reverseGeocodeShort(point, zoom: 19) ??
              _describePoint(point);
      if (!mounted) return;
      widget.onPointSelected?.call(MapPointAddress(point, address));
    } finally {
      if (mounted) {
        setState(() => _pickedGeocodeBusy = false);
      }
    }
  }

  static String _describePoint(LatLng point) =>
      'Pinned location (${point.latitude.toStringAsFixed(5)}, '
      '${point.longitude.toStringAsFixed(5)})';

  Future<void> _initRealtimeLocation() async {
    final initialPos = await _locationService.getCurrentLocation();
    if (initialPos != null && mounted) {
      setState(() {
        _currentLocation = initialPos;
        _hasRealLocation = true;
        _updateMockDrivers(initialPos);
      });
      if (widget.destinationPoint == null) {
        _mapController.move(initialPos, widget.initialZoom);
      } else {
        _fitRouteBounds(initialPos, widget.destinationPoint!);
      }
      widget.onLocationChanged?.call(initialPos);
      unawaited(_resolvePickupAddress(initialPos));
    }

    // Subscribe to continuous location updates
    try {
      _locationSub = _locationService.getRealtimeLocationStream().listen(
        (pos) {
          if (!mounted) return;
          setState(() {
            _currentLocation = pos;
            _hasRealLocation = true;
            _updateMockDrivers(pos);
          });
          if (_followUser && widget.destinationPoint == null) {
            _mapController.move(pos, _mapController.camera.zoom);
          }
          widget.onLocationChanged?.call(pos);
          unawaited(_resolvePickupAddress(pos));
        },
        onError: (err) {
          debugPrint('[OsmMapBackground] Stream listener error: $err');
        },
      );
    } catch (e) {
      debugPrint('[OsmMapBackground] Stream error: $e');
    }
  }

  void _cycleMapType() {
    setState(() {
      _mapType = switch (_mapType) {
        AppMapType.streets => AppMapType.satellite,
        AppMapType.satellite => AppMapType.clean,
        AppMapType.clean => AppMapType.streets,
      };
    });
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Layer: ${_mapType.label}'),
        duration: const Duration(milliseconds: 900),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _recenter() async {
    setState(() => _followUser = true);
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
    final effectiveDestination = widget.destinationPoint ?? _pickedPoint;

    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: _currentLocation,
            initialZoom: widget.initialZoom,
            minZoom: 3,
            maxZoom: 19,
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.all,
            ),
            onPositionChanged: (camera, hasGesture) {
              if (hasGesture && _followUser) {
                setState(() => _followUser = false);
              }
            },
            onTap: (tapPosition, point) => _onMapTap(point),
          ),
          children: [
            // 1. Clean basemap tile layer without watermark
            switch (_mapType) {
              AppMapType.streets => TileLayer(
                  key: const ValueKey('streets_layer'),
                  urlTemplate:
                      'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.ride_booking',
                  maxZoom: 19,
                ),
              AppMapType.satellite => TileLayer(
                  key: const ValueKey('satellite_layer'),
                  urlTemplate:
                      'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}',
                  userAgentPackageName: 'com.example.ride_booking',
                  maxZoom: 19,
                ),
              AppMapType.clean => TileLayer(
                  key: const ValueKey('clean_layer'),
                  urlTemplate:
                      'https://server.arcgisonline.com/ArcGIS/rest/services/World_Street_Map/MapServer/tile/{z}/{y}/{x}',
                  userAgentPackageName: 'com.example.ride_booking',
                  maxZoom: 19,
                ),
            },

            // 2. Open attribution
            RichAttributionWidget(
              attributions: [
                if (_mapType == AppMapType.streets)
                  const TextSourceAttribution(
                    '© OpenStreetMap contributors',
                    textStyle: TextStyle(
                      fontSize: 10,
                      color: AppColors.textSecondary,
                    ),
                  )
                else
                  const TextSourceAttribution(
                    '© Esri & contributors',
                    textStyle: TextStyle(
                      fontSize: 10,
                      color: AppColors.textSecondary,
                    ),
                  ),
              ],
            ),

            // 3. Route polyline when destination is chosen
            if (effectiveDestination != null)
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: [_currentLocation, effectiveDestination],
                    strokeWidth: 4.5,
                    color: AppColors.accent,
                    borderColor: Colors.white,
                    borderStrokeWidth: 1.5,
                  ),
                ],
              ),

            // 4. Markers: Rider GPS, Nearby Drivers & Destination Pin
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

                // Nearby simulated drivers
                ..._mockDrivers.map(
                  (pos) => Marker(
                    point: pos,
                    width: 34,
                    height: 34,
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.brand,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: Colors.white,
                          width: 1.5,
                        ),
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

                // Destination pin for the chosen point
                if (effectiveDestination != null)
                  Marker(
                    point: effectiveDestination,
                    width: 44,
                    height: 50,
                    child: _pickedGeocodeBusy
                        ? const Center(
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: AppColors.accent,
                              ),
                            ),
                          )
                        : Stack(
                            alignment: Alignment.topCenter,
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.brand,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 2,
                                  ),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Color(0x330F172A),
                                      blurRadius: 8,
                                      offset: Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.location_on_rounded,
                                  color: Colors.white,
                                  size: 22,
                                ),
                              ),
                              // Pointed tip toward ground position
                              Positioned(
                                bottom: 6,
                                child: Container(
                                  width: 6,
                                  height: 6,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: AppColors.brand,
                                  ),
                                ),
                              ),
                            ],
                          ),
                  ),
              ],
            ),
          ],
        ),

        // Floating map controls (Layer Switcher & Recenter GPS)
        Positioned(
          right: 16,
          bottom: widget.destinationPoint != null ? 370 : 310,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Map layer toggle
              InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: _cycleMapType,
                child: Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.line),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x1A0F172A),
                        blurRadius: 12,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Icon(
                    _mapType == AppMapType.satellite
                        ? Icons.satellite_alt_rounded
                        : Icons.layers_rounded,
                    color: _mapType == AppMapType.satellite
                        ? AppColors.accent
                        : AppColors.textPrimary,
                    size: 22,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              // Recenter GPS button
              InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: _recenter,
                child: Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.line),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x1A0F172A),
                        blurRadius: 12,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Icon(
                    _followUser
                        ? Icons.my_location_rounded
                        : Icons.location_searching_rounded,
                    color: _followUser
                        ? AppColors.accent
                        : AppColors.textSecondary,
                    size: 22,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
