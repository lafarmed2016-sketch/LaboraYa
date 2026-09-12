import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:laboraya_app/core/constants/app_colors.dart';
import 'package:laboraya_app/core/storage/secure_storage.dart';
import 'package:laboraya_app/core/widgets/app_empty_state.dart';
import 'package:laboraya_app/features/home/presentation/widgets/tiktok_job_feed.dart';
import 'package:laboraya_app/features/jobs/domain/entities/job_entity.dart';
import 'package:laboraya_app/features/jobs/presentation/providers/jobs_provider.dart';
import 'package:laboraya_app/features/profile/presentation/providers/profile_provider.dart';
import 'package:laboraya_app/features/notifications/presentation/providers/notifications_provider.dart';

class HomePage extends ConsumerStatefulWidget {
  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  bool _isSearchExpanded = false;
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(jobsProvider.notifier).loadJobs(refresh: true);
    });
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
    final showSearch = _isSearchExpanded || _query.isNotEmpty;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // ── 1. TikTok Feed Vertical Inmersivo ───────────────────────
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
            ),

          // ── 2. Top Header Flotante Transparente (TikTok) ────────────
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

                      // Botones superiores: Búsqueda y Notificaciones (Sin menú hamburguesa)
                      Row(
                        children: [
                          // Botón Ícono de Búsqueda (Al costado de Notificaciones)
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _isSearchExpanded = !_isSearchExpanded;
                              });
                            },
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: showSearch
                                    ? AppColors.primary.withValues(alpha: 0.8)
                                    : Colors.black.withValues(alpha: 0.35),
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
                        ],
                      ),
                    ],
                  ),

                  // Barra de búsqueda desplegable oscura translúcida
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
                              const Icon(
                                Icons.search_rounded,
                                color: Colors.white70,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextField(
                                  controller: _searchController,
                                  autofocus: true,
                                  onChanged: (val) {
                                    setState(() => _query = val);
                                  },
                                  decoration: const InputDecoration(
                                    hintText: 'Buscar trabajo o servicio en inicio...',
                                    hintStyle: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 12,
                                      color: Colors.white54,
                                    ),
                                    border: InputBorder.none,
                                    isDense: true,
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                  style: const TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 12,
                                    color: Colors.white,
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
                                    color: Colors.white70,
                                    size: 16,
                                  ),
                                ),
                            ],
                          )
                        : const SizedBox.shrink(),
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
