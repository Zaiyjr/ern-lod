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
        // 1. OpenStreetMap tile layer styled to crisp light cartography
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.ride_booking',
        ),

        // 2. Markers for Rider location and nearby driver cars
        MarkerLayer(
          markers: [
            // Rider location pin with blue ambient glow
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
                      color: AppColors.accent.withAlpha(50),
                    ),
                  ),
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

            // Nearby driver vehicle markers
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
    );
  }
}
