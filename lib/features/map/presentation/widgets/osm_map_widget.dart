import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class OsmMapWidget extends StatelessWidget {
  final double latitude;
  final double longitude;
  final double zoom;
  final List<MapJobMarker> markers;
  final Function(LatLng)? onTap;
  final MapController? mapController;
  final bool interactive;
  final double height;

  const OsmMapWidget({
    super.key,
    this.latitude = -12.0464,
    this.longitude = -77.0428,
    this.zoom = 14.0,
    this.markers = const [],
    this.onTap,
    this.mapController,
    this.interactive = true,
    this.height = 200,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: FlutterMap(
          mapController: mapController,
          options: MapOptions(
            initialCenter: LatLng(latitude, longitude),
            initialZoom: zoom,
            interactionOptions: InteractionOptions(
              flags: interactive ? InteractiveFlag.all : InteractiveFlag.none,
            ),
            onTap: (tapPosition, point) {
              onTap?.call(point);
            },
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.laboraya.app',
            ),
            const RichAttributionWidget(
              attributions: [
                TextSourceAttribution(
                  '© OpenStreetMap contributors',
                ),
              ],
            ),
            if (markers.isNotEmpty)
              MarkerLayer(
                markers: markers
                    .map(
                      (m) => Marker(
                        point: LatLng(m.latitude, m.longitude),
                        width: 110,
                        height: 50,
                        child: GestureDetector(
                          onTap: m.onTap,
                          child: _MapPinBadge(
                            title: m.price.isNotEmpty ? m.price : m.title,
                            isUrgent: m.isUrgent,
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
          ],
        ),
      ),
    );
  }
}

class _MapPinBadge extends StatelessWidget {
  final String title;
  final bool isUrgent;

  const _MapPinBadge({required this.title, required this.isUrgent});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: isUrgent ? const Color(0xFFF58232) : const Color(0xFF246BCE),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isUrgent ? Icons.flash_on_rounded : Icons.work_rounded,
                color: Colors.white,
                size: 13,
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        Icon(
          Icons.arrow_drop_down_rounded,
          color: isUrgent ? const Color(0xFFF58232) : const Color(0xFF246BCE),
          size: 18,
        ),
      ],
    );
  }
}

class MapJobMarker {
  final String id;
  final double latitude;
  final double longitude;
  final String title;
  final String price;
  final bool isUrgent;
  final VoidCallback? onTap;

  const MapJobMarker({
    required this.id,
    required this.latitude,
    required this.longitude,
    required this.title,
    this.price = '',
    this.isUrgent = false,
    this.onTap,
  });
}
