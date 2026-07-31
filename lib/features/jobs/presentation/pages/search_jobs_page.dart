import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:laboraya_app/core/constants/app_colors.dart';
import 'package:laboraya_app/core/services/location_service.dart';
import 'package:laboraya_app/features/home/presentation/widgets/job_card.dart';
import 'package:laboraya_app/features/jobs/presentation/providers/jobs_provider.dart';
import 'package:laboraya_app/features/map/presentation/widgets/osm_map_widget.dart';

class SearchJobsPage extends ConsumerStatefulWidget {
  const SearchJobsPage({super.key});

  @override
  ConsumerState<SearchJobsPage> createState() => _SearchJobsPageState();
}

class _SearchJobsPageState extends ConsumerState<SearchJobsPage> {
  final _searchCtrl  = TextEditingController();
  final _sheetCtrl   = DraggableScrollableController();
  Timer? _debounce;
  bool _searchOpen   = false;

  // Tamaños del panel (fracción de pantalla)
  // _minSize debe dejar solo el handle visible justo encima del navbar (~80px)
  static const double _minSize  = 0.09;
  static const double _midSize  = 0.50;
  static const double _maxSize  = 0.88;

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    _sheetCtrl.dispose();
    super.dispose();
  }

  void _onSearch(String q) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 450), () {
      ref.read(jobsProvider.notifier).setSearchQuery(q.trim());
    });
  }

  void _toggleSearch() {
    setState(() => _searchOpen = !_searchOpen);
    if (!_searchOpen) {
      _searchCtrl.clear();
      ref.read(jobsProvider.notifier).setSearchQuery('');
    }
  }

  @override
  Widget build(BuildContext context) {
    final jobsState = ref.watch(jobsProvider);
    final top       = MediaQuery.of(context).padding.top;
    final screenH   = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // ── 1. MAPA pantalla completa ────────────────────────
          Positioned.fill(
            child: RepaintBoundary(
              child: OsmMapWidget(
                latitude: -12.1186,
                longitude: -77.0318,
                zoom: 13,
                height: screenH,
                markers: jobsState.jobs
                    .where((j) => j.latitude != null && j.longitude != null)
                    .map((j) => MapJobMarker(
                          id: j.id,
                          latitude: j.latitude!,
                          longitude: j.longitude!,
                          title: j.title,
                          price: j.formattedBudget,
                          isUrgent: j.isUrgent,
                          onTap: () {},
                        ))
                    .toList(),
              ),
            ),
          ),

          // ── 2. ÍCONO LUPA (esquina superior derecha) ─────────
          Positioned(
            top: top + 12,
            right: 16,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: _searchOpen
                  // Barra de búsqueda expandida
                  ? _SearchBar(
                      key: const ValueKey('bar'),
                      ctrl: _searchCtrl,
                      onSearch: _onSearch,
                      onClose: _toggleSearch,
                    )
                  // Solo lupa
                  : _SearchIcon(
                      key: const ValueKey('icon'),
                      onTap: _toggleSearch,
                    ),
            ),
          ),

          // ── 3. PANEL DESLIZABLE ──────────────────────────────
          DraggableScrollableSheet(
            controller: _sheetCtrl,
            initialChildSize: _minSize,
            minChildSize: _minSize,
            maxChildSize: _maxSize,
            snap: true,
            snapSizes: const [_minSize, _midSize, _maxSize],
            builder: (ctx, scrollCtrl) => _BottomPanel(
              scrollController: scrollCtrl,
              jobsState: jobsState,
              onJobTap: (id) => context.push('/jobs/$id'),
              onRefresh: () =>
                  ref.read(jobsProvider.notifier).loadJobs(refresh: true),
            ),
          ),

          // ── 4. BOTÓN GPS (esquina inferior derecha, encima del panel) ──
          Positioned(
            right: 16,
            bottom: screenH * _minSize + 16,
            child: _GpsLocationButton(
              onTap: () async {
                try {
                  final result = await LocationService.getCurrentLocation();
                  if (!mounted) return;
                  if (result != null) {
                    // Recargar trabajos y centrar mapa en ubicación actual
                    ref.read(jobsProvider.notifier).loadJobs(refresh: true);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                            'Mostrando trabajos cerca de ${result.district}'),
                        backgroundColor: AppColors.success,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                          e.toString().replaceAll('Exception: ', '')),
                      backgroundColor: AppColors.error,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Botón GPS de ubicación actual ───────────────────────────────────────────

class _GpsLocationButton extends StatefulWidget {
  final VoidCallback onTap;
  const _GpsLocationButton({required this.onTap});

  @override
  State<_GpsLocationButton> createState() => _GpsLocationButtonState();
}

class _GpsLocationButtonState extends State<_GpsLocationButton> {
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _loading ? null : () async {
        setState(() => _loading = true);
        widget.onTap();
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) setState(() => _loading = false);
      },
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: _loading
            ? const Padding(
                padding: EdgeInsets.all(14),
                child: CircularProgressIndicator(
                    strokeWidth: 2.5, color: AppColors.primary),
              )
            : const Icon(Icons.my_location_rounded,
                color: AppColors.primary, size: 24),
      ),
    );
  }
}

// ─── Ícono de lupa ────────────────────────────────────────────────────────────

class _SearchIcon extends StatelessWidget {
  final VoidCallback onTap;
  const _SearchIcon({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: const Icon(
          Icons.search_rounded,
          color: AppColors.primary,
          size: 22,
        ),
      ),
    );
  }
}

// ─── Barra de búsqueda expandida ─────────────────────────────────────────────

class _SearchBar extends StatelessWidget {
  final TextEditingController ctrl;
  final ValueChanged<String> onSearch;
  final VoidCallback onClose;
  const _SearchBar(
      {super.key,
      required this.ctrl,
      required this.onSearch,
      required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width - 32,
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 14,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          const SizedBox(width: 12),
          const Icon(Icons.search_rounded,
              color: AppColors.primary, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: ctrl,
              autofocus: true,
              style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14,
                  color: AppColors.textPrimary),
              decoration: const InputDecoration(
                hintText: 'Buscar trabajo o zona...',
                hintStyle: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    color: AppColors.textHint),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                isDense: true,
              ),
              onChanged: onSearch,
              textInputAction: TextInputAction.search,
            ),
          ),
          IconButton(
            onPressed: onClose,
            icon: const Icon(Icons.close_rounded,
                color: AppColors.textHint, size: 18),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          ),
        ],
      ),
    );
  }
}

// ─── Panel deslizable inferior ────────────────────────────────────────────────

class _BottomPanel extends StatelessWidget {
  final ScrollController scrollController;
  final JobsState jobsState;
  final ValueChanged<String> onJobTap;
  final Future<void> Function() onRefresh;

  const _BottomPanel({
    required this.scrollController,
    required this.jobsState,
    required this.onJobTap,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final jobs = jobsState.jobs;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 16,
            offset: Offset(0, -3),
          ),
        ],
      ),
      child: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: onRefresh,
        child: CustomScrollView(
          controller: scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // ── Handle + contador ──────────────────────────────
            SliverToBoxAdapter(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Handle
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      margin:
                          const EdgeInsets.only(top: 10, bottom: 10),
                      decoration: BoxDecoration(
                        color: AppColors.border,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  // Contador — solo visible cuando el panel está expandido
                  if (jobs.isNotEmpty)
                    Padding(
                      padding:
                          const EdgeInsets.fromLTRB(16, 0, 16, 10),
                      child: Row(
                        children: [
                          Text(
                            '${jobs.length} trabajos encontrados',
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const Spacer(),
                          const Text(
                            'Más recientes ↓',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),

            // ── Loading ────────────────────────────────────────
            if (jobsState.isLoading && jobs.isEmpty)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.only(top: 24),
                  child: Center(
                    child: CircularProgressIndicator(
                        color: AppColors.primary),
                  ),
                ),
              ),

            // ── Sin resultados ─────────────────────────────────
            if (!jobsState.isLoading && jobs.isEmpty)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.only(top: 24),
                  child: Center(
                    child: Text(
                      'No hay trabajos disponibles',
                      style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 13,
                          color: AppColors.textHint),
                    ),
                  ),
                ),
              ),

            // ── Lista de trabajos ──────────────────────────────
            if (jobs.isNotEmpty)
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (ctx, i) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: JobCard(
                        job: jobs[i],
                        onTap: () => onJobTap(jobs[i].id),
                      ),
                    ),
                    childCount: jobs.length,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
