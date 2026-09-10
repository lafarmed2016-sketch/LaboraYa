import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:laboraya_app/core/constants/app_colors.dart';
import 'package:laboraya_app/core/storage/secure_storage.dart';
import 'package:laboraya_app/core/widgets/app_empty_state.dart';
import 'package:laboraya_app/features/home/presentation/widgets/job_card.dart';
import 'package:laboraya_app/features/home/presentation/widgets/home_shimmer.dart';
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
  String _selectedModality = 'Por día';
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  final List<String> _modalities = [
    'Por día',
    'Por semana',
    'Por mes',
    'Contrato',
    'Tarea',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<dynamic> _filter(List<dynamic> jobs, String? myId, String? myName) {
    return jobs.where((j) {
      if (j is JobEntity) {
        if (j.isMine(myId: myId, myName: myName)) return false;
        if (_query.trim().isNotEmpty) {
          final q = _query.trim().toLowerCase();
          final matchesTitle = j.title.toLowerCase().contains(q);
          final matchesDesc = j.description.toLowerCase().contains(q);
          final matchesCat = j.categoryName.toLowerCase().contains(q);
          final matchesAddress = (j.address ?? '').toLowerCase().contains(q);
          return matchesTitle || matchesDesc || matchesCat || matchesAddress;
        }
      }
      return true;
    }).toList();
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

    return Scaffold(
      backgroundColor: Colors.white,
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async {
          ref.invalidate(profileProvider);
          ref.invalidate(notificationsProvider);
          await ref.read(jobsProvider.notifier).loadJobs(refresh: true);
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // ── 1. Header: LaboraYa + Ubicación + Notificaciones ─────
            SliverToBoxAdapter(
              child: _HomeHeader(
                onNotifications: () => context.push('/notifications'),
              ),
            ),

            // ── 2. Barra de Búsqueda Interactiva en Inicio ───────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
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
                    children: [
                      const Icon(
                        Icons.search_rounded,
                        color: Color(0xFF94A3B8),
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          onChanged: (val) {
                            setState(() => _query = val);
                          },
                          decoration: const InputDecoration(
                            hintText: 'Buscar trabajo o servicio en inicio...',
                            hintStyle: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 13,
                              color: Color(0xFF94A3B8),
                            ),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 13,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                      ),
                      if (_query.isNotEmpty)
                        GestureDetector(
                          onTap: () {
                            _searchController.clear();
                            setState(() => _query = '');
                          },
                          child: const Icon(
                            Icons.close_rounded,
                            color: Color(0xFF94A3B8),
                            size: 18,
                          ),
                        )
                      else
                        const Icon(
                          Icons.tune_rounded,
                          color: Color(0xFF475569),
                          size: 20,
                        ),
                    ],
                  ),
                ),
              ),
            ),

            // ── 3. Categorías (Iconos circulares limpios) ────────────
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
                        setState(() {
                          _query = 'Plomero';
                          _searchController.text = 'Plomero';
                        });
                      },
                    ),
                    _CategoryCircleItem(
                      title: 'Electricista',
                      icon: Icons.bolt_rounded,
                      color: const Color(0xFFF59E0B),
                      bg: const Color(0xFFFEF3C7),
                      onTap: () {
                        setState(() {
                          _query = 'Electricista';
                          _searchController.text = 'Electricista';
                        });
                      },
                    ),
                    _CategoryCircleItem(
                      title: 'Pintor',
                      icon: Icons.format_paint_rounded,
                      color: const Color(0xFF8B5CF6),
                      bg: const Color(0xFFF5F3FF),
                      onTap: () {
                        setState(() {
                          _query = 'Pintor';
                          _searchController.text = 'Pintor';
                        });
                      },
                    ),
                    _CategoryCircleItem(
                      title: 'Carpintero',
                      icon: Icons.inventory_2_rounded,
                      color: const Color(0xFF92400E),
                      bg: const Color(0xFFFEF2F2),
                      onTap: () {
                        setState(() {
                          _query = 'Carpintero';
                          _searchController.text = 'Carpintero';
                        });
                      },
                    ),
                    _CategoryCircleItem(
                      title: 'Todos',
                      icon: Icons.grid_view_rounded,
                      color: const Color(0xFF64748B),
                      bg: const Color(0xFFF1F5F9),
                      onTap: () {
                        setState(() {
                          _query = '';
                          _searchController.clear();
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 18)),

            // ── 4. Filtro de Modalidades (Píldoras horizontales) ─────
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

            // ── 6. Estados de Carga / Vacío / Lista de Trabajos ──────
            if (state.isLoading && state.jobs.isEmpty)
              const SliverToBoxAdapter(child: HomeShimmer()),
            if (!state.isLoading && state.error != null)
              SliverFillRemaining(
                child: AppErrorState(
                  message: state.error ?? 'Error desconocido',
                  onRetry: () =>
                      ref.read(jobsProvider.notifier).loadJobs(refresh: true),
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

// ─── Componente Encabezado Inicio ────────────────────────────────────────────

class _HomeHeader extends ConsumerWidget {
  final VoidCallback onNotifications;

  const _HomeHeader({required this.onNotifications});

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

          // Campana de notificaciones con badge rojo idéntico
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
                        minWidth: 18,
                        minHeight: 18,
                      ),
                      child: Center(
                        child: Text(
                          '$unreadCount',
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
