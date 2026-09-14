import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:laboraya_app/core/constants/app_colors.dart';
import 'package:laboraya_app/core/services/jobs_cache_service.dart';
import 'package:laboraya_app/core/storage/secure_storage.dart';
import 'package:laboraya_app/core/widgets/app_empty_state.dart';
import 'package:laboraya_app/features/home/presentation/widgets/tiktok_job_feed.dart';
import 'package:laboraya_app/features/jobs/domain/entities/job_entity.dart';
import 'package:laboraya_app/features/jobs/presentation/providers/jobs_provider.dart';
import 'package:laboraya_app/features/profile/presentation/providers/profile_provider.dart';
import 'package:laboraya_app/features/notifications/presentation/providers/notifications_provider.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  bool _isSearchExpanded = false;
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  String? _selectedCategory; // null = "Para ti" (todos)
  String _userLocation = 'Lima, Peru';

  // Chips de categoria estilo TikTok
  static const _categoryChips = [
    (label: 'Para ti',      icon: Icons.auto_awesome_rounded,      filter: null          ),
    (label: 'Urgente',      icon: Icons.flash_on_rounded,           filter: 'URGENT'      ),
    (label: 'Gasfiteria',   icon: Icons.water_drop_rounded,         filter: 'Gasfiteria'  ),
    (label: 'Electricidad', icon: Icons.electrical_services_rounded, filter: 'Electricidad'),
    (label: 'Pintura',      icon: Icons.format_paint_rounded,       filter: 'Pintura'     ),
    (label: 'Carpinteria',  icon: Icons.table_restaurant_rounded,   filter: 'Carpinteria' ),
    (label: 'Albanileria',  icon: Icons.handyman_rounded,           filter: 'Albanileria' ),
    (label: 'Limpieza',     icon: Icons.cleaning_services_rounded,  filter: 'Limpieza'    ),
    (label: 'Mudanzas',     icon: Icons.local_shipping_rounded,     filter: 'Mudanzas'    ),
    (label: 'Mecanica',     icon: Icons.directions_car_rounded,     filter: 'Mecanica'    ),
    (label: 'Sistemas',     icon: Icons.computer_rounded,           filter: 'Sistemas y PC'),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(jobsProvider.notifier).loadJobs(refresh: true);
      _loadUserLocation();
    });
  }

  Future<void> _loadUserLocation() async {
    final cached = await JobsCacheService.getUserLocation();
    if (cached != null && cached.isNotEmpty && mounted) {
      setState(() => _userLocation = cached);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<dynamic> _filter(List<dynamic> jobs, String? myId, String? myName) {
    return jobs.where((j) {
      if (j is JobEntity) {
        if (j.isMine(myId: myId, myName: myName)) return false;
        // Filtro por chip de categoria
        if (_selectedCategory != null) {
          if (_selectedCategory == 'URGENT') {
            if (!j.isUrgent) return false;
          } else {
            final catLow = j.categoryName.toLowerCase();
            final filterLow = _selectedCategory!.toLowerCase();
            if (!catLow.contains(filterLow) && !filterLow.contains(catLow)) return false;
          }
        }
        // Filtro por busqueda de texto
        if (_query.trim().isNotEmpty) {
          final q = _query.trim().toLowerCase();
          final matchesTitle   = j.title.toLowerCase().contains(q);
          final matchesDesc    = j.description.toLowerCase().contains(q);
          final matchesCat     = j.categoryName.toLowerCase().contains(q);
          final matchesAddress = (j.address ?? '').toLowerCase().contains(q);
          return matchesTitle || matchesDesc || matchesCat || matchesAddress;
        }
      }
      return true;
    }).toList();
  }

  Future<void> _handleRefresh() async {
    ref.invalidate(profileProvider);
    ref.invalidate(notificationsProvider);
    await ref.read(jobsProvider.notifier).loadJobs(refresh: true);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<UserProfile?>>(profileProvider, (prev, next) {
      if (next.hasValue && next.value == null) {
        ref.read(secureStorageProvider).clearTokens();
        if (mounted) context.go('/auth/login');
      }
    });

    final state        = ref.watch(jobsProvider);
    final profile      = ref.watch(profileProvider).value;
    final filtered     = _filter(state.jobs, profile?.id, profile?.fullName);
    final notifications = ref.watch(notificationsProvider);
    final unreadCount  = notifications.where((n) => !n.isRead).length;
    final showSearch   = _isSearchExpanded || _query.isNotEmpty;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // ── 1. TikTok Feed Vertical ─────────────────────────────────
          if (state.isLoading && state.jobs.isEmpty)
            const Center(child: CircularProgressIndicator(color: AppColors.primary))
          else if (!state.isLoading && !state.isRefreshingInBackground && state.error != null)
            Center(
              child: AppErrorState(
                message: state.error ?? 'Error al cargar trabajos',
                onRetry: _handleRefresh,
              ),
            )
          else if (filtered.isEmpty && !state.isLoading && !state.isRefreshingInBackground)
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const AppEmptyState(
                    icon: Icons.work_outline_rounded,
                    title: 'No hay trabajos en esta categoria.',
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () => setState(() => _selectedCategory = null),
                    child: const Text(
                      'Ver todos los trabajos',
                      style: TextStyle(color: Colors.white70, fontFamily: 'Poppins'),
                    ),
                  ),
                ],
              ),
            )
          else
            TikTokJobFeed(jobs: filtered, onRefresh: _handleRefresh),

          // ── 2. Header Flotante (TikTok) ─────────────────────────────
          Positioned(
            top: 0, left: 0, right: 0,
            child: Container(
              padding: EdgeInsets.fromLTRB(
                16, MediaQuery.of(context).padding.top + 8, 16, 12,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.80),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Fila superior: Logo + Botones ─────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Logo + Ubicacion
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'LaboraYa',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: -0.5,
                              shadows: [Shadow(color: Colors.black54, blurRadius: 4)],
                            ),
                          ),
                          Row(
                            children: [
                              const Icon(Icons.location_on_rounded, size: 13, color: Colors.white70),
                              const SizedBox(width: 3),
                              Text(
                                _userLocation,
                                style: const TextStyle(
                                  fontFamily: 'Poppins', fontSize: 12,
                                  fontWeight: FontWeight.w500, color: Colors.white70,
                                ),
                              ),
                              // Spinner de refresco en background
                              if (state.isRefreshingInBackground) ...[
                                const SizedBox(width: 6),
                                const SizedBox(
                                  width: 8, height: 8,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 1.5, color: Colors.white38,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),

                      // Busqueda + Notificaciones
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () => setState(() => _isSearchExpanded = !_isSearchExpanded),
                            child: Container(
                              width: 40, height: 40,
                              decoration: BoxDecoration(
                                color: showSearch
                                    ? AppColors.primary.withValues(alpha: 0.8)
                                    : Colors.black.withValues(alpha: 0.35),
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white24),
                              ),
                              child: const Icon(Icons.search_rounded, color: Colors.white, size: 20),
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () => context.push('/notifications'),
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                Container(
                                  width: 40, height: 40,
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.35),
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white24),
                                  ),
                                  child: const Icon(
                                    Icons.notifications_none_rounded,
                                    color: Colors.white, size: 20,
                                  ),
                                ),
                                if (unreadCount > 0)
                                  Positioned(
                                    top: -2, right: -2,
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: const BoxDecoration(
                                        color: Color(0xFFEF4444), shape: BoxShape.circle,
                                      ),
                                      constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                                      child: Center(
                                        child: Text(
                                          '$unreadCount',
                                          style: const TextStyle(
                                            color: Colors.white, fontSize: 9, fontWeight: FontWeight.w800,
                                          ),
                                        ),
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

                  // ── Barra de busqueda desplegable ──────────────────
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeInOut,
                    height: showSearch ? 42 : 0,
                    margin: EdgeInsets.only(top: showSearch ? 10 : 0),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.65),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: showSearch
                        ? Row(
                            children: [
                              const Icon(Icons.search_rounded, color: Colors.white70, size: 18),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextField(
                                  controller: _searchController,
                                  autofocus: true,
                                  onChanged: (val) => setState(() => _query = val),
                                  decoration: const InputDecoration(
                                    hintText: 'Buscar trabajo o servicio...',
                                    hintStyle: TextStyle(
                                      fontFamily: 'Poppins', fontSize: 12, color: Colors.white54,
                                    ),
                                    border: InputBorder.none,
                                    isDense: true,
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                  style: const TextStyle(
                                    fontFamily: 'Poppins', fontSize: 12, color: Colors.white,
                                  ),
                                ),
                              ),
                              if (_query.isNotEmpty)
                                GestureDetector(
                                  onTap: () {
                                    _searchController.clear();
                                    setState(() => _query = '');
                                  },
                                  child: const Icon(Icons.close_rounded, color: Colors.white70, size: 16),
                                ),
                            ],
                          )
                        : const SizedBox.shrink(),
                  ),

                  // ── Chips de Categoria estilo TikTok ───────────────
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 34,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: EdgeInsets.zero,
                      itemCount: _categoryChips.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (ctx, i) {
                        final chip = _categoryChips[i];
                        final isSelected = _selectedCategory == chip.filter;
                        return GestureDetector(
                          onTap: () => setState(() => _selectedCategory = chip.filter),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            curve: Curves.easeOut,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.primary
                                  : Colors.black.withValues(alpha: 0.55),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isSelected ? AppColors.primary : Colors.white30,
                                width: isSelected ? 0 : 0.8,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  chip.icon,
                                  size: 13,
                                  color: isSelected ? Colors.white : Colors.white70,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  chip.label,
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 12,
                                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                    color: isSelected ? Colors.white : Colors.white70,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  // ── Banner offline / datos del cache ───────────────
                  if (state.isFromCache && !state.isRefreshingInBackground)
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.orange.withValues(alpha: 0.4)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.wifi_off_rounded, size: 13, color: Colors.orange),
                          SizedBox(width: 6),
                          Text(
                            'Mostrando datos recientes',
                            style: TextStyle(
                              fontFamily: 'Poppins', fontSize: 11,
                              color: Colors.orange, fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
