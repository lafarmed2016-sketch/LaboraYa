import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:laboraya_app/core/constants/app_colors.dart';
import 'package:laboraya_app/core/widgets/app_states.dart';
import 'package:laboraya_app/features/home/presentation/widgets/job_card.dart';
import 'package:laboraya_app/features/home/presentation/widgets/home_shimmer.dart';
import 'package:laboraya_app/features/jobs/presentation/providers/jobs_provider.dart';
import 'package:laboraya_app/features/map/presentation/widgets/osm_map_widget.dart';

class SearchJobsPage extends ConsumerStatefulWidget {
  const SearchJobsPage({super.key});

  @override
  ConsumerState<SearchJobsPage> createState() => _SearchJobsPageState();
}

class _SearchJobsPageState extends ConsumerState<SearchJobsPage> {
  bool _showMap = false;
  String? _selectedJobId;
  final _searchCtrl = TextEditingController();
  Timer? _debounce; // previene solicitudes duplicadas al escribir

  // Filtros locales (se envían al backend al aplicar)
  double _radiusKm = 10;
  String? _filterCategory;
  double? _budgetMin;
  double? _budgetMax;
  String? _filterModality;
  bool _onlyUrgent = false;
  bool _onlyVerified = false;

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onSearch(String q) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 450), () {
      ref.read(jobsProvider.notifier).setSearchQuery(q.trim());
    });
  }

  void _applyFilters() {
    final notifier = ref.read(jobsProvider.notifier);
    if (_filterCategory != null) {
      notifier.setCategoryFilter(_filterCategory);
    }
    if (_filterModality != null) {
      notifier.setModalityFilter(_filterModality);
    }
    notifier.loadJobs(refresh: true);
  }

  void _clearFilters() {
    setState(() {
      _radiusKm = 10;
      _filterCategory = null;
      _budgetMin = null;
      _budgetMax = null;
      _filterModality = null;
      _onlyUrgent = false;
      _onlyVerified = false;
    });
    ref.read(jobsProvider.notifier).clearFilters();
  }

  @override
  Widget build(BuildContext context) {
    final jobsState = ref.watch(jobsProvider);
    final top = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // ── Contenido principal ──────────────────────────────
          if (_showMap)
            _MapView(
              jobs: jobsState.jobs,
              selectedJobId: _selectedJobId,
              onMarkerTap: (id) => setState(() => _selectedJobId = id),
              headerHeight: top + 116,
            )
          else
            _ListView(
              jobsState: jobsState,
              headerHeight: top + 116,
              onRetry: () =>
                  ref.read(jobsProvider.notifier).loadJobs(refresh: true),
              onRefresh: () =>
                  ref.read(jobsProvider.notifier).loadJobs(refresh: true),
            ),

          // ── Header flotante ──────────────────────────────────
          Positioned(
            top: top + 10,
            left: 16,
            right: 16,
            child: _SearchHeader(
              ctrl: _searchCtrl,
              showMap: _showMap,
              onToggle: (v) => setState(() => _showMap = v),
              onSearch: _onSearch,
              onFilter: () => _showFiltersSheet(context),
            ),
          ),

          // ── Tarjeta inferior (mapa) ──────────────────────────
          if (_showMap && _selectedJobId != null)
            Positioned(
              bottom: 20,
              left: 16,
              right: 16,
              child: _MapJobCard(
                job: jobsState.jobs
                    .where((j) => j.id == _selectedJobId)
                    .firstOrNull,
                onTap: () => context.push('/jobs/$_selectedJobId'),
                onClose: () => setState(() => _selectedJobId = null),
              ),
            ),
        ],
      ),
    );
  }

  void _showFiltersSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _FiltersSheet(
        radiusKm: _radiusKm,
        category: _filterCategory,
        budgetMin: _budgetMin,
        budgetMax: _budgetMax,
        modality: _filterModality,
        onlyUrgent: _onlyUrgent,
        onlyVerified: _onlyVerified,
        onChanged:
            ({
              required double radius,
              required String? category,
              required double? budgetMin,
              required double? budgetMax,
              required String? modality,
              required bool onlyUrgent,
              required bool onlyVerified,
            }) {
              setState(() {
                _radiusKm = radius;
                _filterCategory = category;
                _budgetMin = budgetMin;
                _budgetMax = budgetMax;
                _filterModality = modality;
                _onlyUrgent = onlyUrgent;
                _onlyVerified = onlyVerified;
              });
            },
        onApply: () {
          Navigator.pop(context);
          _applyFilters();
        },
        onClear: () {
          Navigator.pop(context);
          _clearFilters();
        },
      ),
    );
  }
}

// ─── Header con buscador + toggle ────────────────────────────────────────────

class _SearchHeader extends StatelessWidget {
  final TextEditingController ctrl;
  final bool showMap;
  final ValueChanged<bool> onToggle;
  final ValueChanged<String> onSearch;
  final VoidCallback onFilter;

  const _SearchHeader({
    required this.ctrl,
    required this.showMap,
    required this.onToggle,
    required this.onSearch,
    required this.onFilter,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Buscador
        Container(
          height: 54,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border, width: 0.8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 12,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              const SizedBox(width: 14),
              const Icon(
                Icons.search_rounded,
                color: AppColors.primary,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: ctrl,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 14,
                    color: AppColors.textPrimary,
                  ),
                  decoration: const InputDecoration(
                    hintText: '¿Qué trabajo estás buscando?',
                    hintStyle: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 13,
                      color: AppColors.textHint,
                    ),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                    isDense: true,
                  ),
                  onSubmitted: onSearch,
                  onChanged: onSearch,
                  textInputAction: TextInputAction.search,
                ),
              ),
              GestureDetector(
                onTap: onFilter,
                child: Container(
                  width: 38,
                  height: 38,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.tune_rounded,
                    color: AppColors.primary,
                    size: 18,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        // Selector Segmentado Lista / Mapa
        Center(
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: AppColors.border, width: 0.8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _ToggleBtn(
                  label: 'Lista',
                  icon: Icons.list_rounded,
                  isSelected: !showMap,
                  onTap: () => onToggle(false),
                ),
                _ToggleBtn(
                  label: 'Mapa',
                  icon: Icons.map_rounded,
                  isSelected: showMap,
                  onTap: () => onToggle(true),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ToggleBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _ToggleBtn({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(26),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 15,
              color: isSelected ? Colors.white : AppColors.textSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? Colors.white : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Vista lista ──────────────────────────────────────────────────────────────

class _ListView extends StatelessWidget {
  final JobsState jobsState;
  final double headerHeight;
  final VoidCallback onRetry;
  final Future<void> Function() onRefresh;

  const _ListView({
    required this.jobsState,
    required this.headerHeight,
    required this.onRetry,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: onRefresh,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: EdgeInsets.only(top: headerHeight + 12),
            sliver: const SliverToBoxAdapter(child: SizedBox.shrink()),
          ),
          if (jobsState.isLoading && jobsState.jobs.isEmpty)
            const SliverToBoxAdapter(child: HomeShimmer()),
          if (!jobsState.isLoading && jobsState.error != null)
            SliverFillRemaining(child: AppNetworkError(onRetry: onRetry)),
          if (!jobsState.isLoading &&
              jobsState.error == null &&
              jobsState.jobs.isEmpty)
            const SliverFillRemaining(child: AppNoResults()),
          if (jobsState.jobs.isNotEmpty)
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (ctx, i) => Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: JobCard(
                      job: jobsState.jobs[i],
                      onTap: () => ctx.push('/jobs/${jobsState.jobs[i].id}'),
                    ),
                  ),
                  childCount: jobsState.jobs.length,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Vista mapa ───────────────────────────────────────────────────────────────

class _MapView extends StatelessWidget {
  final List<dynamic> jobs;
  final String? selectedJobId;
  final ValueChanged<String> onMarkerTap;
  final double headerHeight;

  const _MapView({
    required this.jobs,
    required this.selectedJobId,
    required this.onMarkerTap,
    required this.headerHeight,
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: OsmMapWidget(
        latitude: -12.1186,
        longitude: -77.0318,
        zoom: 13,
        height: MediaQuery.of(context).size.height,
        markers: jobs
            .where((j) => j.latitude != null && j.longitude != null)
            .map(
              (j) => MapJobMarker(
                id: j.id,
                latitude: j.latitude!,
                longitude: j.longitude!,
                title: j.title,
                price: j.formattedBudget,
                isUrgent: j.isUrgent,
                onTap: () => onMarkerTap(j.id),
              ),
            )
            .toList(),
      ),
    );
  }
}

// ─── Tarjeta inferior (mapa) ──────────────────────────────────────────────────

class _MapJobCard extends StatelessWidget {
  final dynamic job;
  final VoidCallback onTap;
  final VoidCallback onClose;

  const _MapJobCard({
    required this.job,
    required this.onTap,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    if (job == null) return const SizedBox.shrink();
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.work_rounded,
                color: AppColors.primary,
                size: 26,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    job.title,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_rounded,
                        size: 12,
                        color: AppColors.textHint,
                      ),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          job.address ?? '',
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        job.formattedBudget,
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const Spacer(),
                      if (job.isUrgent)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.urgent.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'Urgente',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: AppColors.urgent,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: onClose,
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: AppColors.background,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close_rounded,
                  color: AppColors.textHint,
                  size: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Bottom sheet de filtros ──────────────────────────────────────────────────

class _FiltersSheet extends StatefulWidget {
  final double radiusKm;
  final String? category;
  final double? budgetMin;
  final double? budgetMax;
  final String? modality;
  final bool onlyUrgent;
  final bool onlyVerified;
  final void Function({
    required double radius,
    required String? category,
    required double? budgetMin,
    required double? budgetMax,
    required String? modality,
    required bool onlyUrgent,
    required bool onlyVerified,
  })
  onChanged;
  final VoidCallback onApply;
  final VoidCallback onClear;

  const _FiltersSheet({
    required this.radiusKm,
    required this.category,
    required this.budgetMin,
    required this.budgetMax,
    required this.modality,
    required this.onlyUrgent,
    required this.onlyVerified,
    required this.onChanged,
    required this.onApply,
    required this.onClear,
  });

  @override
  State<_FiltersSheet> createState() => _FiltersSheetState();
}

class _FiltersSheetState extends State<_FiltersSheet> {
  late double _radius;
  String? _category;
  late final TextEditingController _minCtrl;
  late final TextEditingController _maxCtrl;
  String? _modality;
  late bool _onlyUrgent;
  late bool _onlyVerified;

  static const _categories = [
    'Electricidad',
    'Plomería',
    'Pintura',
    'Carpintería',
    'Albañilería',
    'Limpieza',
    'Cerrajería',
    'Mecánica',
    'Jardinería',
    'Mudanzas',
  ];

  static const _modalities = [
    ('Por tarea', 'PER_TASK'),
    ('Por día', 'PER_DAY'),
    ('Por semana', 'PER_WEEK'),
    ('Por contrato', 'PER_CONTRACT'),
    ('Tiempo completo', 'FULL_TIME'),
  ];

  @override
  void initState() {
    super.initState();
    _radius = widget.radiusKm;
    _category = widget.category;
    _minCtrl = TextEditingController(
      text: widget.budgetMin?.toStringAsFixed(0) ?? '',
    );
    _maxCtrl = TextEditingController(
      text: widget.budgetMax?.toStringAsFixed(0) ?? '',
    );
    _modality = widget.modality;
    _onlyUrgent = widget.onlyUrgent;
    _onlyVerified = widget.onlyVerified;
  }

  @override
  void dispose() {
    _minCtrl.dispose();
    _maxCtrl.dispose();
    super.dispose();
  }

  void _emit() {
    widget.onChanged(
      radius: _radius,
      category: _category,
      budgetMin: double.tryParse(_minCtrl.text),
      budgetMax: double.tryParse(_maxCtrl.text),
      modality: _modality,
      onlyUrgent: _onlyUrgent,
      onlyVerified: _onlyVerified,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            // Título
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Row(
                children: [
                  const Text(
                    'Filtros',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: widget.onClear,
                    child: const Text(
                      'Limpiar',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Radio
                    _FilterLabel('Radio de búsqueda: ${_radius.toInt()} km'),
                    Slider(
                      value: _radius,
                      min: 1,
                      max: 50,
                      divisions: 49,
                      activeColor: AppColors.primary,
                      inactiveColor: AppColors.border,
                      label: '${_radius.toInt()} km',
                      onChanged: (v) => setState(() {
                        _radius = v;
                        _emit();
                      }),
                    ),
                    const SizedBox(height: 16),
                    // Categoría
                    const _FilterLabel('Categoría'),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _categories.map((cat) {
                        final sel = _category == cat;
                        return GestureDetector(
                          onTap: () => setState(() {
                            _category = sel ? null : cat;
                            _emit();
                          }),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 160),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: sel
                                  ? AppColors.primary
                                  : AppColors.background,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: sel
                                    ? AppColors.primary
                                    : AppColors.border,
                              ),
                            ),
                            child: Text(
                              cat,
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: sel
                                    ? Colors.white
                                    : AppColors.textSecondary,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),
                    // Presupuesto
                    const _FilterLabel('Presupuesto (S/)'),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _minCtrl,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 14,
                            ),
                            decoration: const InputDecoration(
                              hintText: 'Mínimo',
                              prefixText: 'S/ ',
                            ),
                            onChanged: (_) => _emit(),
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 10),
                          child: Text(
                            '—',
                            style: TextStyle(color: AppColors.textHint),
                          ),
                        ),
                        Expanded(
                          child: TextField(
                            controller: _maxCtrl,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 14,
                            ),
                            decoration: const InputDecoration(
                              hintText: 'Máximo',
                              prefixText: 'S/ ',
                            ),
                            onChanged: (_) => _emit(),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // Modalidad
                    const _FilterLabel('Modalidad'),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _modalities.map((m) {
                        final sel = _modality == m.$2;
                        return GestureDetector(
                          onTap: () => setState(() {
                            _modality = sel ? null : m.$2;
                            _emit();
                          }),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 160),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: sel
                                  ? AppColors.primary
                                  : AppColors.background,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: sel
                                    ? AppColors.primary
                                    : AppColors.border,
                              ),
                            ),
                            child: Text(
                              m.$1,
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: sel
                                    ? Colors.white
                                    : AppColors.textSecondary,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),
                    // Switches
                    _FilterSwitch(
                      label: 'Solo empleadores verificados',
                      value: _onlyVerified,
                      onChanged: (v) => setState(() {
                        _onlyVerified = v;
                        _emit();
                      }),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
            // Footer
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: widget.onApply,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'Aplicar filtros',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
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

class _FilterLabel extends StatelessWidget {
  final String text;
  const _FilterLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontFamily: 'Poppins',
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
    );
  }
}

class _FilterSwitch extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _FilterSwitch({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 14,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: AppColors.primary,
        ),
      ],
    );
  }
}
