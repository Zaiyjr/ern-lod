import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/theme/app_colors.dart';

/// Real interactive OpenStreetMap background widget with CartoDB Dark Matter
/// styling to maintain the dark aesthetics from the original design mockup.
class OsmMapBackground extends StatefulWidget {
  const OsmMapBackground({
    super.key,
    this.initialCenter = const LatLng(13.7563, 100.5018), // Default: Bangkok city
    this.initialZoom = 14.5,
  });

  final LatLng initialCenter;
  final double initialZoom;

  @override
  State<OsmMapBackground> createState() => _OsmMapBackgroundState();
}

class _OsmMapBackgroundState extends State<OsmMapBackground> {
  late final MapController _mapController;

  // Simulated nearby driver cars
  late final List<LatLng> _mockDrivers;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _mockDrivers = [
      LatLng(
        widget.initialCenter.latitude + 0.0042,
        widget.initialCenter.longitude + 0.0035,
      ),
      LatLng(
        widget.initialCenter.latitude - 0.0038,
        widget.initialCenter.longitude - 0.0048,
      ),
      LatLng(
        widget.initialCenter.latitude + 0.0065,
        widget.initialCenter.longitude - 0.0031,
      ),
      LatLng(
        widget.initialCenter.latitude - 0.0022,
        widget.initialCenter.longitude + 0.0058,
      ),
    ];
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: widget.initialCenter,
        initialZoom: widget.initialZoom,
        minZoom: 4,
        maxZoom: 19,
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.all,
        ),
      ),
      children: [
        // 1. OpenStreetMap tile layer styled to dark mode
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.ride_booking',
          tileBuilder: (context, tileWidget, tile) {
            // Invert and hue-adjust standard OSM tiles to match our sleek dark mockup theme
            return ColorFiltered(
              colorFilter: const ColorFilter.matrix(<double>[
                -0.75, 0.00,  0.00, 0.0, 235,
                 0.00, -0.75, 0.00, 0.0, 235,
                 0.00, 0.00, -0.65, 0.0, 245,
                 0.00, 0.00,  0.00, 1.0, 0,
              ]),
              child: tileWidget,
            );
          },
        ),

        // 2. Markers for Rider location and nearby driver cars
        MarkerLayer(
          markers: [
            // Rider location pin
            Marker(
              point: widget.initialCenter,
              width: 50,
              height: 50,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.accent.withAlpha(55),
                    ),
                  ),
                  Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFF1F5FB),
                      border: Border.all(
                        color: AppColors.accent,
                        width: 3.5,
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black45,
                          blurRadius: 8,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Nearby driver vehicle markers
            ..._mockDrivers.map(
              (pos) => Marker(
                point: pos,
                width: 32,
                height: 32,
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: const Color(0xFF60A5FA),
                      width: 1.5,
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black54,
                        blurRadius: 6,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.directions_car_filled,
                    color: Color(0xFF60A5FA),
                    size: 18,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
