import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:laboraya_app/core/constants/app_colors.dart';
import 'package:laboraya_app/core/services/location_service.dart';
import 'package:laboraya_app/features/favorites/presentation/providers/favorites_provider.dart';
import 'package:laboraya_app/features/jobs/domain/entities/job_entity.dart';
import 'package:laboraya_app/features/jobs/presentation/providers/jobs_provider.dart';
import 'package:laboraya_app/features/map/presentation/widgets/osm_map_widget.dart';
import 'package:laboraya_app/features/profile/presentation/providers/profile_provider.dart';

class SearchJobsPage extends ConsumerStatefulWidget {
  const SearchJobsPage({super.key});

  @override
  ConsumerState<SearchJobsPage> createState() => _SearchJobsPageState();
}

class _SearchJobsPageState extends ConsumerState<SearchJobsPage> {
  final _searchCtrl = TextEditingController();
  final _sheetCtrl = DraggableScrollableController();
  Timer? _debounce;
  bool _searchOpen = false;

  // Tamaños del panel (fracción de pantalla)
  // _minSize bajo (0.065) permite ocultar el panel para ver el mapa 100% COMPLETO
  static const double _minSize = 0.065;
  static const double _initialSize = 0.35;
  static const double _midSize = 0.60;
  static const double _maxSize = 0.88;

  String _currentSort = 'Más recientes';

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

  void _showJobModal(BuildContext context, JobEntity job) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => _JobMapModalContent(job: job),
    );
  }

  void _showSortOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Text(
                'Ordenar trabajos por',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 12),
              ListTile(
                title: const Text('Más recientes', style: TextStyle(fontFamily: 'Poppins', fontSize: 14)),
                trailing: _currentSort == 'Más recientes' ? const Icon(Icons.check, color: AppColors.primary) : null,
                onTap: () {
                  setState(() => _currentSort = 'Más recientes');
                  Navigator.pop(ctx);
                },
              ),
              ListTile(
                title: const Text('Menor precio', style: TextStyle(fontFamily: 'Poppins', fontSize: 14)),
                trailing: _currentSort == 'Menor precio' ? const Icon(Icons.check, color: AppColors.primary) : null,
                onTap: () {
                  setState(() => _currentSort = 'Menor precio');
                  Navigator.pop(ctx);
                },
              ),
              ListTile(
                title: const Text('Mayor precio', style: TextStyle(fontFamily: 'Poppins', fontSize: 14)),
                trailing: _currentSort == 'Mayor precio' ? const Icon(Icons.check, color: AppColors.primary) : null,
                onTap: () {
                  setState(() => _currentSort = 'Mayor precio');
                  Navigator.pop(ctx);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final jobsState = ref.watch(jobsProvider);
    final profile = ref.watch(profileProvider).value;
    var otherJobs = jobsState.jobs
        .where((j) => !j.isMine(myId: profile?.id, myName: profile?.fullName))
        .toList();

    // Ordenar trabajos según selección
    if (_currentSort == 'Menor precio') {
      otherJobs.sort((a, b) => (a.budgetMin ?? 0).compareTo(b.budgetMin ?? 0));
    } else if (_currentSort == 'Mayor precio') {
      otherJobs.sort((a, b) => (b.budgetMax ?? b.budgetMin ?? 0).compareTo(a.budgetMax ?? a.budgetMin ?? 0));
    } else {
      otherJobs.sort((a, b) => (b.publishedAt ?? b.createdAt).compareTo(a.publishedAt ?? a.createdAt));
    }

    final top = MediaQuery.of(context).padding.top;
    final screenH = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // ── 1. MAPA pantalla completa ────────────────────────
          Positioned.fill(
            child: RepaintBoundary(
              child: OsmMapWidget(
                latitude: -12.0464,
                longitude: -77.0428,
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
                          categoryName: j.categoryName,
                          isUrgent: j.isUrgent,
                          onTap: () => _showJobModal(context, j),
                        ))
                    .toList(),
              ),
            ),
          ),

          // ── 2. BARRA SUPERIOR FLOTANTE ESTILO PÍLDORA (Diseño idéntico a la imagen) ──
          Positioned(
            top: top + 10,
            left: 16,
            right: 16,
            child: Row(
              children: [
                // Botón menú / atrás
                GestureDetector(
                  onTap: () {
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.go('/');
                    }
                  },
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.menu_rounded,
                      color: Color(0xFF0F172A),
                      size: 22,
                    ),
                  ),
                ),
                const SizedBox(width: 10),

                // Píldora de búsqueda central
                Expanded(
                  child: GestureDetector(
                    onTap: _toggleSearch,
                    child: Container(
                      height: 44,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: _searchOpen
                          ? TextField(
                              controller: _searchCtrl,
                              autofocus: true,
                              style: const TextStyle(fontFamily: 'Poppins', fontSize: 13),
                              decoration: InputDecoration(
                                hintText: 'Buscar trabajo o servicio...',
                                hintStyle: const TextStyle(fontFamily: 'Poppins', fontSize: 13, color: Color(0xFF94A3B8)),
                                border: InputBorder.none,
                                isDense: true,
                                suffixIcon: IconButton(
                                  icon: const Icon(Icons.close, size: 18),
                                  onPressed: _toggleSearch,
                                ),
                              ),
                              onChanged: _onSearch,
                            )
                          : Row(
                              children: [
                                const Icon(Icons.search_rounded, color: Color(0xFF64748B), size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Buscar en esta área',
                                        style: TextStyle(
                                          fontFamily: 'Poppins',
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF0F172A),
                                          height: 1.1,
                                        ),
                                      ),
                                      Text(
                                        '${otherJobs.length} trabajos cerca',
                                        style: const TextStyle(
                                          fontFamily: 'Poppins',
                                          fontSize: 10,
                                          color: Color(0xFF64748B),
                                          height: 1.1,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),

                // Botón GPS superior derecho
                GestureDetector(
                  onTap: () async {
                    final messenger = ScaffoldMessenger.of(context);
                    try {
                      final result = await LocationService.getCurrentLocation();
                      if (!mounted) return;
                      if (result != null) {
                        ref.read(jobsProvider.notifier).loadJobs(refresh: true);
                        messenger.showSnackBar(
                          SnackBar(
                            content: Text('Mostrando trabajos cerca de ${result.district}'),
                            backgroundColor: AppColors.success,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    } catch (e) {
                      if (!mounted) return;
                      messenger.showSnackBar(
                        SnackBar(
                          content: Text(e.toString().replaceAll('Exception: ', '')),
                          backgroundColor: AppColors.error,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  },
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.my_location_rounded,
                      color: Color(0xFF0F172A),
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── 3. PANEL DESLIZABLE INFERIOR ──────────────────────
          DraggableScrollableSheet(
              controller: _sheetCtrl,
              initialChildSize: _initialSize,
              minChildSize: _minSize,
              maxChildSize: _maxSize,
              snap: true,
              snapSizes: const [_minSize, _initialSize, _midSize, _maxSize],
              builder: (ctx, scrollCtrl) => _BottomPanel(
                scrollController: scrollCtrl,
                jobsState: jobsState,
                jobs: otherJobs,
                currentSort: _currentSort,
                onSortTap: _showSortOptions,
                onJobTap: (id) => context.push('/jobs/$id'),
                onRefresh: () =>
                    ref.read(jobsProvider.notifier).loadJobs(refresh: true),
              ),
          ),
        ],
      ),
    );
  }
}

// ─── Botón GPS flotante ───────────────────────────────────────────────────────

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
      onTap: _loading
          ? null
          : () async {
              setState(() => _loading = true);
              widget.onTap();
              await Future.delayed(const Duration(seconds: 2));
              if (mounted) setState(() => _loading = false);
            },
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: _loading
            ? const Padding(
                padding: EdgeInsets.all(12),
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: AppColors.primary,
                ),
              )
            : const Icon(
                Icons.my_location_rounded,
                color: AppColors.primary,
                size: 22,
              ),
      ),
    );
  }
}



// ─── Panel deslizable inferior ────────────────────────────────────────────────

class _BottomPanel extends StatelessWidget {
  final ScrollController scrollController;
  final JobsState jobsState;
  final List<JobEntity> jobs;
  final String currentSort;
  final VoidCallback onSortTap;
  final ValueChanged<String> onJobTap;
  final Future<void> Function() onRefresh;

  const _BottomPanel({
    required this.scrollController,
    required this.jobsState,
    required this.jobs,
    required this.currentSort,
    required this.onSortTap,
    required this.onJobTap,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Color(0x18000000),
            blurRadius: 18,
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
            // ── Handle + Encabezado idéntico al diseño ──────────────
            SliverToBoxAdapter(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Handle
                  Center(
                    child: Container(
                      width: 38,
                      height: 4,
                      margin: const EdgeInsets.only(top: 10, bottom: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFCBD5E1),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  // Encabezado: "X trabajos encontrados" | "Más recientes ⌄"
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: Row(
                      children: [
                        Text(
                          '${jobs.length} trabajos encontrados',
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const Spacer(),
                        InkWell(
                          onTap: onSortTap,
                          borderRadius: BorderRadius.circular(8),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 4, vertical: 2),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  currentSort,
                                  style: const TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primary,
                                  ),
                                ),
                                const SizedBox(width: 2),
                                const Icon(
                                  Icons.keyboard_arrow_down_rounded,
                                  size: 18,
                                  color: AppColors.primary,
                                ),
                              ],
                            ),
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
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                ),
              ),

            // ── Sin resultados ─────────────────────────────────
            if (!jobsState.isLoading && jobs.isEmpty)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.only(top: 32),
                  child: Center(
                    child: Text(
                      'No hay trabajos disponibles en esta zona',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 13,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                  ),
                ),
              ),

            // ── Lista de tarjetas de trabajo (Diseño idéntico a la imagen) ──
            if (jobs.isNotEmpty)
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (ctx, i) => _SearchJobTile(
                      job: jobs[i],
                      onTap: () => onJobTap(jobs[i].id),
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

// ─── Tarjeta de trabajo idéntica a la imagen ──────────────────────────────────

class _SearchJobTile extends ConsumerWidget {
  final JobEntity job;
  final VoidCallback onTap;

  const _SearchJobTile({required this.job, required this.onTap});

  Color _categoryColor(String cat) {
    switch (cat.toLowerCase()) {
      case 'plomería':
        return const Color(0xFF0D6EFD);
      case 'electricidad':
        return const Color(0xFFD97706);
      case 'pintura':
        return const Color(0xFF7C3AED);
      case 'carpintería':
        return const Color(0xFF92400E);
      case 'albañilería':
        return const Color(0xFFEA580C);
      case 'limpieza':
        return const Color(0xFF059669);
      case 'cerrajería':
        return const Color(0xFF4B5563);
      case 'mecánica':
        return const Color(0xFF1D4ED8);
      default:
        return AppColors.primary;
    }
  }

  IconData _categoryIcon(String cat) {
    switch (cat.toLowerCase()) {
      case 'plomería':
        return Icons.plumbing_rounded;
      case 'electricidad':
        return Icons.electrical_services_rounded;
      case 'pintura':
        return Icons.format_paint_rounded;
      case 'carpintería':
        return Icons.carpenter_rounded;
      case 'albañilería':
        return Icons.construction_rounded;
      case 'limpieza':
        return Icons.cleaning_services_rounded;
      case 'cerrajería':
        return Icons.lock_rounded;
      case 'mecánica':
        return Icons.build_rounded;
      default:
        return Icons.work_rounded;
    }
  }

  String _formatJobTime(DateTime? dt) {
    if (dt == null) return 'Reciente';
    final now = DateTime.now();
    final difference = now.difference(dt);

    final isToday = dt.year == now.year && dt.month == now.month && dt.day == now.day;
    final yesterday = now.subtract(const Duration(days: 1));
    final isYesterday = dt.year == yesterday.year && dt.month == yesterday.month && dt.day == yesterday.day;

    final hour12 = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final minuteStr = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour < 12 ? 'a. m.' : 'p. m.';
    final timeStr = '$hour12:$minuteStr $period';

    if (isToday) {
      return 'Hoy, $timeStr';
    } else if (isYesterday) {
      return 'Ayer, $timeStr';
    } else if (difference.inDays < 7) {
      const days = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
      final dayName = days[dt.weekday - 1];
      return '$dayName, $timeStr';
    } else {
      return '${dt.day}/${dt.month}/${dt.year}';
    }
  }

  Widget _buildImage(BuildContext context) {
    final catColor = _categoryColor(job.categoryName);
    if (job.images.isNotEmpty) {
      final img = job.images.first;
      if (img.startsWith('http')) {
        return Image.network(
          img,
          width: 96,
          height: 96,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _buildPlaceholder(catColor),
        );
      } else {
        return Image.file(
          File(img),
          width: 96,
          height: 96,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _buildPlaceholder(catColor),
        );
      }
    }
    return _buildPlaceholder(catColor);
  }

  Widget _buildPlaceholder(Color catColor) {
    return Container(
      width: 96,
      height: 96,
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _categoryIcon(job.categoryName),
              color: catColor,
              size: 32,
            ),
            const SizedBox(height: 4),
            Text(
              job.categoryName,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 9.5,
                fontWeight: FontWeight.w600,
                color: catColor,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favorites = ref.watch(favoritesProvider);
    final isFav = favorites.contains(job.id);
    final timeFormatted = _formatJobTime(job.publishedAt ?? job.createdAt);
    final modalityLabel = job.modality == 'FIXED' ? 'Fijo' : 'Estimado';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // ── Foto cuadrada pequeña ──────────────────────────────
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: SizedBox(
                    width: 96,
                    height: 96,
                    child: _buildImage(context),
                  ),
                ),
                const SizedBox(width: 12),

                // ── Contenido derecho ─────────────────────────────────
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Fila 1: Título y Precio
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              job.title,
                              style: const TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF0F172A),
                                height: 1.25,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            job.formattedBudget,
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),

                      // Fila 2: Subtítulo de precio alineado a la derecha
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          modalityLabel,
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 10.5,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF94A3B8),
                          ),
                        ),
                      ),
                      const SizedBox(height: 2),

                      // Fila 3: Ubicación (Pin azul)
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on_outlined,
                            size: 13.5,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              job.address ?? 'Lima',
                              style: const TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 11.5,
                                color: Color(0xFF64748B),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),

                      // Fila 4: Hora (Reloj gris)
                      Row(
                        children: [
                          const Icon(
                            Icons.access_time_rounded,
                            size: 13.5,
                            color: Color(0xFF94A3B8),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              timeFormatted,
                              style: const TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 11.5,
                                color: Color(0xFF64748B),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),

                      // Fila 5: Tag de categoría azul + Bookmark
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 3.5,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEBF3FF),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              job.categoryName,
                              style: const TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              ref.read(favoritesProvider.notifier).toggle(job.id);
                            },
                            behavior: HitTestBehavior.opaque,
                            child: Padding(
                              padding: const EdgeInsets.all(2.0),
                              child: Icon(
                                isFav
                                    ? Icons.bookmark_rounded
                                    : Icons.bookmark_border_rounded,
                                size: 19,
                                color: isFav
                                    ? AppColors.primary
                                    : const Color(0xFF94A3B8),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Modal al presionar sobre un trabajo en el Mapa ───────────────────────────
class _JobMapModalContent extends StatefulWidget {
  final JobEntity job;
  const _JobMapModalContent({required this.job});

  @override
  State<_JobMapModalContent> createState() => _JobMapModalContentState();
}

class _JobMapModalContentState extends State<_JobMapModalContent> {
  bool _showWarningBanner = true;

  @override
  Widget build(BuildContext context) {
    final job = widget.job;
    final isUnverified = !job.isPublisherVerified;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 20,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            // Categoría, Urgente & Badge de Datos Incompletos en la esquina
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEBF3FF),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    job.categoryName,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                if (job.isUrgent) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFECEB),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.bolt, size: 13, color: Color(0xFFE53935)),
                        SizedBox(width: 2),
                        Text(
                          'URGENTE',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFFE53935),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                if (isUnverified) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFFCD34D)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.warning_amber_rounded, size: 13, color: Color(0xFFD97706)),
                        SizedBox(width: 3),
                        Text(
                          'Datos incompletos',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFFB45309),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const Spacer(),
                Text(
                  job.formattedBudget,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Mensaje Flotante de Advertencia (Cerrable con X)
            if (isUnverified && _showWarningBanner) ...[
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFBEB),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFCD34D)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.security_sharp, color: Color(0xFFD97706), size: 20),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '⚠️ Advertencia de Seguridad',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFFB45309),
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'La persona que registró este trabajo no tiene sus datos de verificación completos. Ten cuidado al coordinar o realizar pagos.',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 11,
                              color: Color(0xFFB45309),
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 4),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _showWarningBanner = false;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFDE68A),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.close_rounded, size: 15, color: Color(0xFF92400E)),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Título
            Text(
              job.title,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 8),

            // Ubicación
            Row(
              children: [
                const Icon(Icons.location_on_outlined,
                    size: 15, color: AppColors.primary),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    job.address ?? 'Lima',
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      color: Color(0xFF64748B),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Botón ver detalle
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  context.push('/jobs/${job.id}');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  elevation: 0,
                ),
                child: const Text(
                  'Ver detalle del trabajo',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
