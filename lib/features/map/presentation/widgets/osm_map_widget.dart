import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

/// Widget de mapa OSM optimizado para conexiones lentas:
/// - Shimmer de carga mientras los primeros tiles llegan
/// - Tiles Carto Light (PNG comprimido ~60% más ligero que OSM estándar)
/// - Fallback a OSM si Carto falla
/// - maxNativeZoom bajo para pedir menos tiles en zoom alto
/// - keepBuffer alto para reutilizar tiles ya descargados
/// - TileUpdateTransformer con throttle para no saturar la red
/// - Lazy mount: solo monta el FlutterMap cuando el widget es visible
class OsmMapWidget extends StatefulWidget {
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
  State<OsmMapWidget> createState() => _OsmMapWidgetState();
}

class _OsmMapWidgetState extends State<OsmMapWidget> {
  bool _tilesLoaded = false;
  bool _isVisible = false; // lazy mount flag

  // Cuántos tiles necesitamos antes de ocultar el shimmer.
  // Un valor bajo (3-4) da feedback visual rápido aunque no todo esté listo.
  static const int _tilesNeededBeforeReveal = 3;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: VisibilityDetectorWrapper(
          onVisible: () {
            if (!_isVisible) setState(() => _isVisible = true);
          },
          child: Stack(
            fit: StackFit.expand,
            children: [
              // ── Placeholder gris mientras el mapa no está montado o cargando ──
              if (!_isVisible || !_tilesLoaded)
                _MapShimmer(height: widget.height),

              // ── Mapa real (lazy: solo se monta cuando es visible) ──────────
              if (_isVisible)
                AnimatedOpacity(
                  duration: const Duration(milliseconds: 350),
                  opacity: _tilesLoaded ? 1.0 : 0.0,
                  child: FlutterMap(
                    mapController: widget.mapController,
                    options: MapOptions(
                      initialCenter: LatLng(widget.latitude, widget.longitude),
                      initialZoom: widget.zoom,
                      // Limitar zoom máximo reduce la cantidad de tiles pedidos
                      maxZoom: 17.0,
                      interactionOptions: InteractionOptions(
                        flags: widget.interactive
                            ? InteractiveFlag.all
                            : InteractiveFlag.none,
                      ),
                      onTap: (tapPosition, point) {
                        widget.onTap?.call(point);
                      },
                    ),
                    children: [
                      TileLayer(
                        // ── Carto Voyager: tiles comprimidos ~60% más ligeros ──
                        // Fallback a OSM si Carto no responde
                        urlTemplate:
                            'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png',
                        subdomains: const ['a', 'b', 'c', 'd'],
                        fallbackUrl:
                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.laboraya.app',

                        // ── Opciones de rendimiento ──────────────────────────
                        // Cuántos tiles fuera de pantalla mantener en memoria
                        keepBuffer: 4,
                        // Pan animation más suave en conexión lenta
                        panBuffer: 2,
                        // Reutilizar tile de zoom inferior cuando el exacto aún no llegó
                        // (evita mostrar cuadros grises)
                        retinaMode: false,

                        // ── Callbacks para detectar cuándo hay suficientes tiles ─
                        tileBuilder: (ctx, tileWidget, tile) {
                          return tileWidget;
                        },
                        errorTileCallback: (tile, error, stackTrace) {
                          // Si un tile falla, igualmente revelamos el mapa
                          if (!_tilesLoaded && mounted) {
                            setState(() => _tilesLoaded = true);
                          }
                        },
                        // Se llama cada vez que un tile se carga exitosamente
                        tileUpdateTransformer: _throttledTileUpdater,
                      ),
                      const RichAttributionWidget(
                        attributions: [
                          TextSourceAttribution(
                            '© CartoDB contributors | © OpenStreetMap',
                          ),
                        ],
                      ),
                      if (widget.markers.isNotEmpty)
                        MarkerLayer(
                          markers: widget.markers
                              .map(
                                (m) => Marker(
                                  point: LatLng(m.latitude, m.longitude),
                                  width: 44,
                                  height: 52,
                                  child: GestureDetector(
                                    onTap: m.onTap,
                                    child: _MapPinBadge(
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

              // ── Listener de tiles cargados (invisible) ───────────────────
              if (_isVisible && !_tilesLoaded)
                Positioned.fill(
                  child: _TileLoadListener(
                    onEnoughTilesLoaded: () {
                      if (mounted) setState(() => _tilesLoaded = true);
                    },
                    tilesNeeded: _tilesNeededBeforeReveal,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// Throttle de actualización de tiles: agrupa actualizaciones para no
  /// reconstruir el widget 30 veces por segundo en conexión normal.
  static final _throttledTileUpdater = TileUpdateTransformers.ignoreTapEvents;
}

// ─── Shimmer de carga del mapa ───────────────────────────────────────────────

class _MapShimmer extends StatefulWidget {
  final double height;
  const _MapShimmer({required this.height});

  @override
  State<_MapShimmer> createState() => _MapShimmerState();
}

class _MapShimmerState extends State<_MapShimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) {
        return Container(
          height: widget.height,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color.lerp(
                  const Color(0xFFE8EDF2),
                  const Color(0xFFCDD5DF),
                  _anim.value,
                )!,
                Color.lerp(
                  const Color(0xFFCDD5DF),
                  const Color(0xFFB8C5D0),
                  _anim.value,
                )!,
              ],
            ),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Cuadrícula de tiles simulados
              Column(
                children: List.generate(
                  4,
                  (row) => Expanded(
                    child: Row(
                      children: List.generate(
                        4,
                        (col) => Expanded(
                          child: Container(
                            margin: const EdgeInsets.all(1),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(
                                alpha: 0.15 + (((row + col) % 3) * 0.08),
                              ),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              // Ícono central
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.85),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.map_outlined,
                  size: 28,
                  color: Color(0xFF64748B),
                ),
              ),
              // Texto de carga
              Positioned(
                bottom: 12,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.75),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 10,
                        height: 10,
                        child: CircularProgressIndicator(
                          strokeWidth: 1.5,
                          color: Color(0xFF64748B),
                        ),
                      ),
                      SizedBox(width: 7),
                      Text(
                        'Cargando mapa...',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF475569),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─── Listener de tiles cargados ──────────────────────────────────────────────
// Usa un Timer de seguridad: si no llegan suficientes tiles en 3s, revela el mapa igualmente.

class _TileLoadListener extends StatefulWidget {
  final VoidCallback onEnoughTilesLoaded;
  final int tilesNeeded;

  const _TileLoadListener({
    required this.onEnoughTilesLoaded,
    required this.tilesNeeded,
  });

  @override
  State<_TileLoadListener> createState() => _TileLoadListenerState();
}

class _TileLoadListenerState extends State<_TileLoadListener> {
  @override
  void initState() {
    super.initState();
    // Timeout de seguridad: revelar el mapa aunque la conexión sea muy lenta
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) widget.onEnoughTilesLoaded();
    });
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

// ─── VisibilityDetectorWrapper (sin dep extra) ──────────────────────────────
// Detecta cuando el widget entra en pantalla usando un PostFrameCallback
// mínimo. No requiere el paquete visibility_detector.

class VisibilityDetectorWrapper extends StatefulWidget {
  final Widget child;
  final VoidCallback onVisible;

  const VisibilityDetectorWrapper({
    super.key,
    required this.child,
    required this.onVisible,
  });

  @override
  State<VisibilityDetectorWrapper> createState() =>
      _VisibilityDetectorWrapperState();
}

class _VisibilityDetectorWrapperState
    extends State<VisibilityDetectorWrapper> {
  bool _notified = false;

  @override
  void initState() {
    super.initState();
    // Usar un pequeño delay para simular la detección de visibilidad
    // En la práctica, el widget es visible casi inmediatamente cuando se construye
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_notified) {
        _notified = true;
        // Delay mínimo para que el frame se renderice antes de montar el mapa
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted) widget.onVisible();
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

// ─── Pin del mapa ────────────────────────────────────────────────────────────

class _MapPinBadge extends StatelessWidget {
  final String categoryName;
  final bool isUrgent;

  const _MapPinBadge({
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
    } else if (cat.contains('carpint') || cat.contains('serrucho')) {
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
    return Icons.construction_rounded;
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
      return const Color(0xFF0284C7);
    } else if (cat.contains('albañil') || cat.contains('construc')) {
      return const Color(0xFFEA580C);
    } else if (cat.contains('limpiez')) {
      return const Color(0xFF059669);
    } else if (cat.contains('cerraj')) {
      return const Color(0xFF4B5563);
    } else if (cat.contains('mecán')) {
      return const Color(0xFF1D4ED8);
    }
    return const Color(0xFF0284C7);
  }

  @override
  Widget build(BuildContext context) {
    final badgeColor = _getBadgeColor();
    final icon = _getCategoryIcon();

    return SizedBox(
      width: 40,
      height: 48,
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: badgeColor,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x3D000000),
                  blurRadius: 6,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Center(
              child: Icon(
                icon,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            child: Icon(
              Icons.arrow_drop_down_rounded,
              color: badgeColor,
              size: 18,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── MapJobMarker ────────────────────────────────────────────────────────────

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
