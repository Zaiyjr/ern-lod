import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/services/geocoding_service.dart';
import '../../../../core/services/location_service.dart';
import '../../../../core/theme/app_colors.dart';

/// A point chosen on the map together with its reverse-geocoded address.
class MapPointAddress {
  const MapPointAddress(this.point, this.address);

  final LatLng point;

  /// Human-readable address from OSM Nominatim, or a coordinate fallback
  /// when lookup fails (rarely null in practice).
  final String address;
}

/// Interactive OpenStreetMap background widget with real-time GPS tracking
/// and reverse-geocoded addresses:
/// - Resolves the GPS position to a human-readable address whenever the
///   rider moves more than [_geocodeMinDistanceMeters] (throttled).
/// - Lets a rider tap the map to choose a destination point; the tap is
///   reverse-geocoded and delivered through [onPointSelected].
class OsmMapBackground extends StatefulWidget {
  const OsmMapBackground({
    super.key,
    this.initialCenter = LocationService.defaultFallback,
    this.initialZoom = 15.0,
    this.enableRealtimeLocation = true,
    this.onLocationChanged,
    this.onPickupAddressResolved,
    this.onPointSelected,
  });

  final LatLng initialCenter;
  final double initialZoom;
  final bool enableRealtimeLocation;
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

  void _updateMockDrivers(LatLng center) {
    _mockDrivers = [
      LatLng(center.latitude + 0.0035, center.longitude + 0.0032),
      LatLng(center.latitude - 0.0031, center.longitude - 0.0038),
      LatLng(center.latitude + 0.0048, center.longitude - 0.0026),
      LatLng(center.latitude - 0.0020, center.longitude + 0.0045),
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
      // Compact label so the sheet chip stays 1–2 lines.
      final address = await _geocodingService.reverseGeocodeShort(position);
      if (!mounted) return;
      if (address == null) return;
      setState(() {}); // allow pick-state UI to refresh
      widget.onPickupAddressResolved?.call(address);
    } finally {
      _pickupGeocodeBusy = false;
    }
  }

  /// Reverse-geocodes a tapped map point and reports it as the chosen
  /// destination.
  Future<void> _onMapTap(LatLng point) async {
    if (widget.onPointSelected == null) return;
    setState(() {
      _pickedPoint = point;
      _pickedGeocodeBusy = true;
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

  /// Coordinate fallback so a destination pick can never dead-end when
  /// the lookup service is unavailable.
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
      _mapController.move(initialPos, widget.initialZoom);
      widget.onLocationChanged?.call(initialPos);
      unawaited(_resolvePickupAddress(initialPos));
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
            // Tap-to-pick: reverse-geocode the tapped point so the sheet
            // shows the real address, not coordinates.
            onTap: (tapPosition, point) => _onMapTap(point),
          ),
          children: [
            // 1. CARTO Positron tile layer — the calm, light basemap style
            // ride apps use; avoids OSM Carto's noisy survey look.
            TileLayer(
              urlTemplate:
                  'https://basemaps.cartocdn.com/light_all/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.ride_booking',
            ),

            // 1b. Required source attribution (OSM + CARTO usage terms).
            RichAttributionWidget(
              attributions: [
                TextSourceAttribution(
                  '© OpenStreetMap contributors',
                  textStyle: const TextStyle(
                    fontSize: 10,
                    color: AppColors.textSecondary,
                  ),
                ),
                TextSourceAttribution(
                  '© CARTO',
                  textStyle: const TextStyle(
                    fontSize: 10,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
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

                // Destination pin for the point the rider tapped
                if (_pickedPoint != null)
                  Marker(
                    point: _pickedPoint!,
                    width: 40,
                    height: 46,
                    child: _pickedGeocodeBusy
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: AppColors.accent,
                            ),
                          )
                        : Stack(
                            alignment: Alignment.topCenter,
                            children: [
                              Container(
                                width: 34,
                                height: 34,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.accent,
                                  boxShadow: [
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
                                  size: 20,
                                ),
                              ),
                              // Pointed tip toward the map position
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.accent,
                                ),
                              ),
                            ],
                          ),
                  ),
              ],
            ),
          ],
        ),

        // Recenter Floating Action Button (Thumb Zone right side).
        // Sits above the tallest sheet state so the idle panel never
        // covers it.
        Positioned(
          right: 16,
          bottom: 350,
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
