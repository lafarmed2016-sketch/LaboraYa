import 'dart:io';
import 'dart:convert';
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
  List<dynamic> _filter(List<dynamic> jobs, String? myId, String? myName) {
    return jobs.where((j) {
      if (j is JobEntity) {
        return !j.isMine(myId: myId, myName: myName);
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
      backgroundColor: AppColors.background,
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
            SliverToBoxAdapter(
              child: _HomeHeader(
                onNotifications: () => context.push('/notifications'),
                onProfile: () => context.go('/profile'),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
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
            if (!state.isLoading && state.error == null && filtered.isEmpty)
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
