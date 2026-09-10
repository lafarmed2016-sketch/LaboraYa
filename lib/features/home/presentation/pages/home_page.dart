import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:laboraya_app/core/constants/app_colors.dart';
import 'package:laboraya_app/core/storage/secure_storage.dart';
import 'package:laboraya_app/core/widgets/app_empty_state.dart';
import 'package:laboraya_app/features/home/presentation/widgets/job_card.dart';
import 'package:laboraya_app/features/home/presentation/widgets/home_shimmer.dart';
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
  bool _isTikTokFeedMode = true;
  String _selectedModality = 'Por día';

  final List<String> _modalities = [
    'Por día',
    'Por semana',
    'Por mes',
    'Contrato',
    'Tarea',
  ];

  List<dynamic> _filter(List<dynamic> jobs, String? myId, String? myName) {
    return jobs.where((j) {
      if (j is JobEntity) {
        return !j.isMine(myId: myId, myName: myName);
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

    final state = ref.watch(jobsProvider);
    final profile = ref.watch(profileProvider).value;
    final filtered = _filter(state.jobs, profile?.id, profile?.fullName);
    final notifications = ref.watch(notificationsProvider);
    final unreadCount = notifications.where((n) => !n.isRead).length;

    return Scaffold(
      backgroundColor: _isTikTokFeedMode ? Colors.black : Colors.white,
      body: _isTikTokFeedMode
          ? Stack(
              children: [
                // ── 1. TikTok Feed Vertical ───────────────────────────
                if (state.isLoading && state.jobs.isEmpty)
                  const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  )
                else if (!state.isLoading && state.error != null)
                  Center(
                    child: AppErrorState(
                      message: state.error ?? 'Error al cargar trabajos',
                      onRetry: _handleRefresh,
                    ),
                  )
                else if (filtered.isEmpty)
                  const Center(
                    child: AppEmptyState(
                      icon: Icons.work_outline_rounded,
                      title: 'No hay trabajos disponibles por ahora.',
                    ),
                  )
                else
                  TikTokJobFeed(
                    jobs: filtered,
                    onRefresh: _handleRefresh,
                    onToggleViewMode: () {
                      setState(() => _isTikTokFeedMode = false);
                    },
                  ),

                // ── 2. Top Header Flotante Transparente (TikTok) ─────
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: EdgeInsets.fromLTRB(
                      16,
                      MediaQuery.of(context).padding.top + 8,
                      16,
                      12,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.75),
                          Colors.transparent,
                        ],
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Logo + Ubicación
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
                                    shadows: [
                                      Shadow(color: Colors.black54, blurRadius: 4),
                                    ],
                                  ),
                                ),
                                Row(
                                  children: const [
                                    Icon(
                                      Icons.location_on_rounded,
                                      size: 13,
                                      color: Colors.white70,
                                    ),
                                    SizedBox(width: 3),
                                    Text(
                                      'Miraflores, Lima',
                                      style: TextStyle(
                                        fontFamily: 'Poppins',
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.white70,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),

                            // Botones superiores: Notificaciones, Búsqueda, Cambiar Vista
                            Row(
                              children: [
                                // Búsqueda rápida
                                GestureDetector(
                                  onTap: () => context.go('/search'),
                                  child: Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: Colors.black.withValues(alpha: 0.35),
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.white24),
                                    ),
                                    child: const Icon(
                                      Icons.search_rounded,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),

                                // Notificaciones
                                GestureDetector(
                                  onTap: () => context.push('/notifications'),
                                  child: Stack(
                                    clipBehavior: Clip.none,
                                    children: [
                                      Container(
                                        width: 40,
                                        height: 40,
                                        decoration: BoxDecoration(
                                          color: Colors.black.withValues(alpha: 0.35),
                                          shape: BoxShape.circle,
                                          border: Border.all(color: Colors.white24),
                                        ),
                                        child: const Icon(
                                          Icons.notifications_none_rounded,
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                      ),
                                      if (unreadCount > 0)
                                        Positioned(
                                          top: -2,
                                          right: -2,
                                          child: Container(
                                            padding: const EdgeInsets.all(4),
                                            decoration: const BoxDecoration(
                                              color: Color(0xFFEF4444),
                                              shape: BoxShape.circle,
                                            ),
                                            constraints: const BoxConstraints(
                                              minWidth: 16,
                                              minHeight: 16,
                                            ),
                                            child: Center(
                                              child: Text(
                                                '$unreadCount',
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 9,
                                                  fontWeight: FontWeight.w800,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),

                                // Alternar a vista lista
                                GestureDetector(
                                  onTap: () {
                                    setState(() => _isTikTokFeedMode = false);
                                  },
                                  child: Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.25),
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.white38),
                                    ),
                                    child: const Icon(
                                      Icons.view_list_rounded,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            )
          : RefreshIndicator(
              color: AppColors.primary,
              onRefresh: _handleRefresh,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  // ── 1. Header tradicional + Botón Volver a TikTok Feed ─────
                  SliverToBoxAdapter(
                    child: _HomeHeader(
                      onNotifications: () => context.push('/notifications'),
                      isTikTokMode: false,
                      onToggleView: () {
                        setState(() => _isTikTokFeedMode = true);
                      },
                    ),
                  ),

                  // ── 2. Barra de Búsqueda ─────────────────────────────────
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
                      child: GestureDetector(
                        onTap: () => context.go('/search'),
                        child: Container(
                          height: 48,
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x06000000),
                                blurRadius: 8,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            children: const [
                              Icon(
                                Icons.search_rounded,
                                color: Color(0xFF94A3B8),
                                size: 20,
                              ),
                              SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Buscar trabajo o servicio...',
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 13,
                                    color: Color(0xFF94A3B8),
                                  ),
                                ),
                              ),
                              Icon(
                                Icons.tune_rounded,
                                color: Color(0xFF475569),
                                size: 20,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  // ── 3. Categorías ─────────────────────────────────────────
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _CategoryCircleItem(
                            title: 'Plomero',
                            icon: Icons.water_drop_rounded,
                            color: const Color(0xFF2563EB),
                            bg: const Color(0xFFEFF6FF),
                            onTap: () {
                              ref.read(jobsProvider.notifier).setCategoryFilter('1');
                              context.go('/search');
                            },
                          ),
                          _CategoryCircleItem(
                            title: 'Electricista',
                            icon: Icons.bolt_rounded,
                            color: const Color(0xFFF59E0B),
                            bg: const Color(0xFFFEF3C7),
                            onTap: () {
                              ref.read(jobsProvider.notifier).setCategoryFilter('2');
                              context.go('/search');
                            },
                          ),
                          _CategoryCircleItem(
                            title: 'Pintor',
                            icon: Icons.format_paint_rounded,
                            color: const Color(0xFF8B5CF6),
                            bg: const Color(0xFFF5F3FF),
                            onTap: () {
                              ref.read(jobsProvider.notifier).setCategoryFilter('3');
                              context.go('/search');
                            },
                          ),
                          _CategoryCircleItem(
                            title: 'Carpintero',
                            icon: Icons.inventory_2_rounded,
                            color: const Color(0xFF92400E),
                            bg: const Color(0xFFFEF2F2),
                            onTap: () {
                              ref.read(jobsProvider.notifier).setCategoryFilter('5');
                              context.go('/search');
                            },
                          ),
                          _CategoryCircleItem(
                            title: 'Más',
                            icon: Icons.grid_view_rounded,
                            color: const Color(0xFF64748B),
                            bg: const Color(0xFFF1F5F9),
                            onTap: () => context.go('/search'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 18)),

                  // ── 4. Filtro de Modalidades ──────────────────────────────
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: 38,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: _modalities.length,
                        itemBuilder: (ctx, i) {
                          final item = _modalities[i];
                          final isSelected = item == _selectedModality;
                          return GestureDetector(
                            onTap: () {
                              setState(() => _selectedModality = item);
                              String? modFilter;
                              switch (item) {
                                case 'Por día':
                                  modFilter = 'PER_DAY';
                                  break;
                                case 'Por semana':
                                  modFilter = 'PER_WEEK';
                                  break;
                                case 'Por mes':
                                  modFilter = 'PER_MONTH';
                                  break;
                                case 'Contrato':
                                  modFilter = 'PER_CONTRACT';
                                  break;
                                case 'Tarea':
                                  modFilter = 'PER_TASK';
                                  break;
                              }
                              ref.read(jobsProvider.notifier).setModalityFilter(modFilter);
                            },
                            child: Container(
                              margin: const EdgeInsets.only(right: 8),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected ? AppColors.primary : Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isSelected
                                      ? AppColors.primary
                                      : const Color(0xFFE2E8F0),
                                ),
                              ),
                              child: Text(
                                item,
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 12,
                                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                  color: isSelected ? Colors.white : const Color(0xFF64748B),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 12)),

                  // ── 5. Encabezado "Trabajos cerca de ti" ──────────────────
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Trabajos cerca de ti',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          GestureDetector(
                            onTap: () => context.go('/search'),
                            child: Row(
                              children: const [
                                Icon(
                                  Icons.map_outlined,
                                  size: 16,
                                  color: AppColors.primary,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'Ver mapa',
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ── 6. Lista de Trabajos Tradicional ──────────────────────
                  if (state.isLoading && state.jobs.isEmpty)
                    const SliverToBoxAdapter(child: HomeShimmer()),
                  if (!state.isLoading && state.error != null)
                    SliverFillRemaining(
                      child: AppErrorState(
                        message: state.error ?? 'Error desconocido',
                        onRetry: _handleRefresh,
                      ),
                    ),
                  if (!state.isLoading && state.error == null && filtered.isEmpty)
                    const SliverFillRemaining(
                      child: AppEmptyState(
                        icon: Icons.work_outline_rounded,
                        title: 'No hay trabajos disponibles por ahora.',
                      ),
                    ),
                  if (filtered.isNotEmpty)
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 90),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (ctx, i) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: JobCard(
                              job: filtered[i],
                              onTap: () => ctx.push('/jobs/${filtered[i].id}'),
                            ),
                          ),
                          childCount: filtered.length,
                        ),
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}

// ─── Componente Encabezado Inicio Tradicional ────────────────────────────────

class _HomeHeader extends ConsumerWidget {
  final VoidCallback onNotifications;
  final bool isTikTokMode;
  final VoidCallback onToggleView;

  const _HomeHeader({
    required this.onNotifications,
    required this.isTikTokMode,
    required this.onToggleView,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifications = ref.watch(notificationsProvider);
    final unreadCount = notifications.where((n) => !n.isRead).length;

    return Container(
      color: Colors.white,
      padding: EdgeInsets.fromLTRB(
        20,
        MediaQuery.of(context).padding.top + 10,
        20,
        6,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Logo LaboraYa + Ubicación
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'LaboraYa',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 2),
              Row(
                children: const [
                  Icon(
                    Icons.location_on_rounded,
                    size: 14,
                    color: Color(0xFF64748B),
                  ),
                  SizedBox(width: 3),
                  Text(
                    'Miraflores, Lima',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 16,
                    color: Color(0xFF64748B),
                  ),
                ],
              ),
            ],
          ),

          Row(
            children: [
              // Botón para volver a Modo TikTok Feed
              GestureDetector(
                onTap: onToggleView,
                child: Container(
                  width: 42,
                  height: 42,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                  ),
                  child: const Icon(
                    Icons.view_carousel_rounded,
                    color: AppColors.primary,
                    size: 22,
                  ),
                ),
              ),

              // Campana de notificaciones
              GestureDetector(
                onTap: onNotifications,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: const Icon(
                        Icons.notifications_none_rounded,
                        color: Color(0xFF0F172A),
                        size: 20,
                      ),
                    ),
                    Positioned(
                      top: -2,
                      right: -2,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Color(0xFFEF4444),
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 18,
                          minHeight: 18,
                        ),
                        child: Center(
                          child: Text(
                            unreadCount > 0 ? '$unreadCount' : '3',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
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
    );
  }
}

// ─── Componente Ícono de Categoría ───────────────────────────────────────────

class _CategoryCircleItem extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final Color bg;
  final VoidCallback onTap;

  const _CategoryCircleItem({
    required this.title,
    required this.icon,
    required this.color,
    required this.bg,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 6),
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Color(0xFF475569),
            ),
          ),
        ],
      ),
    );
  }
}
