import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:laboraya_app/core/constants/app_colors.dart';
import 'package:laboraya_app/core/widgets/app_empty_state.dart';
import 'package:laboraya_app/features/home/presentation/widgets/job_card.dart';
import 'package:laboraya_app/features/home/presentation/widgets/home_shimmer.dart';
import 'package:laboraya_app/features/jobs/presentation/providers/jobs_provider.dart';
import 'package:laboraya_app/features/profile/presentation/providers/profile_provider.dart';
import 'package:laboraya_app/features/notifications/presentation/providers/notifications_provider.dart';

const _kCategories = [
  _Cat('Todos', Icons.grid_view_rounded, Color(0xFF246BCE)),
  _Cat('Plomería', Icons.plumbing_rounded, Color(0xFF0D6EFD)),
  _Cat('Electricidad', Icons.electrical_services_rounded, Color(0xFFD97706)),
  _Cat('Pintura', Icons.format_paint_rounded, Color(0xFF7C3AED)),
  _Cat('Carpintería', Icons.carpenter_rounded, Color(0xFF92400E)),
  _Cat('Limpieza', Icons.cleaning_services_rounded, Color(0xFF059669)),
  _Cat('Albañilería', Icons.construction_rounded, Color(0xFFEA580C)),
  _Cat('Cerrajería', Icons.lock_rounded, Color(0xFF4B5563)),
  _Cat('Mecánica', Icons.build_rounded, Color(0xFF1D4ED8)),
];

class _Cat {
  final String label;
  final IconData icon;
  final Color color;
  const _Cat(this.label, this.icon, this.color);
}

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  String _selectedCategory = 'Todos';

  List<dynamic> _filter(List<dynamic> jobs) {
    if (_selectedCategory == 'Todos') return jobs;
    return jobs
        .where(
          (j) => j.categoryName.toLowerCase().contains(
            _selectedCategory.toLowerCase(),
          ),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(jobsProvider);
    final filtered = _filter(state.jobs);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () =>
            ref.read(jobsProvider.notifier).loadJobs(refresh: true),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: _HomeHeader(
                onNotifications: () => context.push('/notifications'),
                onProfile: () => context.go('/profile'),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                child: _SearchBar(
                  onTap: () => context.go('/search'),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(top: 24, bottom: 24),
                child: _CategoriesRow(
                  selected: _selectedCategory,
                  onSelect: (c) => setState(() => _selectedCategory = c),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: _HomeBanner(onTap: () => context.go('/search')),
              ),
            ),
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
            if (!state.isLoading && state.error == null && state.jobs.isEmpty)
              const SliverFillRemaining(
                child: AppEmptyState(
                  icon: Icons.work_outline_rounded,
                  title: 'No hay trabajos disponibles por ahora.',
                ),
              ),
            if (filtered.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: _SectionHeader(
                  title: 'Nuevos trabajos',
                  count: filtered.length,
                  onSeeAll: () => context.go('/search'),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 90),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (ctx, i) => Padding(
                      padding: const EdgeInsets.only(bottom: 16),
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
          ],
        ),
      ),
    );
  }
}

class _HomeHeader extends ConsumerWidget {
  final VoidCallback onNotifications;
  final VoidCallback onProfile;

  const _HomeHeader({
    required this.onNotifications,
    required this.onProfile,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileProvider);
    final firstName = profileAsync.maybeWhen(
      data: (p) => p?.firstName ?? 'tú',
      orElse: () => 'tú',
    );
    final city = profileAsync.maybeWhen(
      data: (p) => p?.city ?? 'Lima, Perú',
      orElse: () => 'Lima, Perú',
    );
    final avatar = profileAsync.maybeWhen(
      data: (p) => p?.avatar,
      orElse: () => null,
    );
    final initial = firstName.isNotEmpty ? firstName[0].toUpperCase() : 'U';

    final notifications = ref.watch(notificationsProvider);
    final hasUnread = notifications.any((n) => !n.isRead);

    return Container(
      color: Colors.white,
      padding: EdgeInsets.fromLTRB(
        22,
        MediaQuery.of(context).padding.top + 14,
        22,
        16,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hola, $firstName 👋',
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Listo para tu próximo trabajo',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.border),
                  ),
                  child: const Icon(
                    Icons.notifications_none_rounded,
                    color: AppColors.textPrimary,
                    size: 20,
                  ),
                ),
                if (hasUnread)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.redAccent,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
            onPressed: onNotifications,
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onProfile,
            child: CircleAvatar(
              radius: 20,
              backgroundColor: AppColors.primaryLight,
              backgroundImage: avatar != null
                  ? (avatar.startsWith('data:image')
                      ? MemoryImage(base64Decode(avatar.split(',').last)) as ImageProvider
                      : (avatar.startsWith('/') || !avatar.startsWith('http')
                          ? FileImage(File(avatar)) as ImageProvider
                          : NetworkImage(avatar) as ImageProvider))
                  : null,
              child: avatar == null
                  ? Text(
                      initial,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    )
                  : null,
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  final VoidCallback onTap;

  const _SearchBar({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 46,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFF0F0F0)),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.search_rounded,
              color: Color(0xFF9E9E9E),
              size: 20,
            ),
            const SizedBox(width: 12),
          ],
        ),
      ),
    );
  }
}

class _CategoriesRow extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onSelect;

  const _CategoriesRow({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 90,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _kCategories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 16),
        itemBuilder: (ctx, i) {
          final cat = _kCategories[i];
          final isSelected = selected == cat.label;
          return GestureDetector(
            onTap: () => onSelect(cat.label),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFFF3F8FF) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: isSelected ? AppColors.primary : const Color(0xFFF0F0F0)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.02),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Icon(
                      cat.icon,
                      size: 26,
                      color: cat.color,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  cat.label,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 11,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected ? AppColors.primary : const Color(0xFF4B5563),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _HomeBanner extends StatelessWidget {
  final VoidCallback onTap;
  const _HomeBanner({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primaryDark, AppColors.primary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Encuentra trabajo cerca',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Conecta directamente con clientes en tu zona.',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: onTap,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.primaryDark,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'Explorar mapa',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.map_rounded, size: 56, color: Colors.white24),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final int count;
  final VoidCallback onSeeAll;

  const _SectionHeader({
    required this.title,
    required this.count,
    required this.onSeeAll,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
      child: Row(
        children: [
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const Spacer(),
          TextButton(
            onPressed: onSeeAll,
            child: const Text(
              'Ver todos',
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
    );
  }
}
