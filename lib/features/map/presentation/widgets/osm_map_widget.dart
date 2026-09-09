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
                        width: 125,
                        height: 52,
                        child: GestureDetector(
                          onTap: m.onTap,
                          child: _MapPinBadge(
                            title: m.price.isNotEmpty ? m.price : m.title,
                            categoryName: m.categoryName,
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
  final String categoryName;
  final bool isUrgent;

  const _MapPinBadge({
    required this.title,
    this.categoryName = '',
    required this.isUrgent,
  });

  IconData _getCategoryIcon() {
    if (isUrgent) return Icons.flash_on_rounded;
    final cat = categoryName.toLowerCase();
    if (cat.contains('plomer') || cat.contains('gasfiter') || cat.contains('tuber')) {
      return Icons.plumbing_rounded;
    } else if (cat.contains('electr')) {
      return Icons.electrical_services_rounded;
    } else if (cat.contains('pintur')) {
      return Icons.format_paint_rounded;
    } else if (cat.contains('carpint')) {
      return Icons.carpenter_rounded;
    } else if (cat.contains('albañil') || cat.contains('construc') || cat.contains('obra') || cat.contains('lampa')) {
      return Icons.construction_rounded;
    } else if (cat.contains('limpiez') || cat.contains('aseo')) {
      return Icons.cleaning_services_rounded;
    } else if (cat.contains('cerraj')) {
      return Icons.lock_rounded;
    } else if (cat.contains('mecán') || cat.contains('auto')) {
      return Icons.build_rounded;
    } else if (cat.contains('jardin')) {
      return Icons.grass_rounded;
    }
    return Icons.construction_rounded; // Ícono de lampa / obra por defecto
  }

  Color _getBadgeColor() {
    if (isUrgent) return const Color(0xFFEF4444);
    final cat = categoryName.toLowerCase();
    if (cat.contains('plomer') || cat.contains('gasfiter')) {
      return const Color(0xFF0D6EFD);
    } else if (cat.contains('electr')) {
      return const Color(0xFFD97706);
    } else if (cat.contains('pintur')) {
      return const Color(0xFF7C3AED);
    } else if (cat.contains('carpint')) {
      return const Color(0xFF92400E);
    } else if (cat.contains('albañil') || cat.contains('construc')) {
      return const Color(0xFFEA580C);
    } else if (cat.contains('limpiez')) {
      return const Color(0xFF059669);
    } else if (cat.contains('cerraj')) {
      return const Color(0xFF4B5563);
    } else if (cat.contains('mecán')) {
      return const Color(0xFF1D4ED8);
    }
    return const Color(0xFF246BCE);
  }

  @override
  Widget build(BuildContext context) {
    final badgeColor = _getBadgeColor();
    final icon = _getCategoryIcon();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
          decoration: BoxDecoration(
            color: badgeColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.28),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: Colors.white,
                size: 14,
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
          color: badgeColor,
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
  final String categoryName;
  final bool isUrgent;
  final VoidCallback? onTap;

  const MapJobMarker({
    required this.id,
    required this.latitude,
    required this.longitude,
    required this.title,
    this.price = '',
    this.categoryName = '',
    this.isUrgent = false,
    this.onTap,
  });
}
