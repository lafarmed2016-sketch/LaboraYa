import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:laboraya_app/core/constants/app_colors.dart';
import 'package:laboraya_app/features/jobs/domain/entities/job_entity.dart';
import 'package:laboraya_app/features/jobs/presentation/providers/jobs_provider.dart';
import 'package:laboraya_app/features/profile/presentation/providers/profile_provider.dart';

class MyJobsPage extends ConsumerStatefulWidget {
  const MyJobsPage({super.key});

  @override
  ConsumerState<MyJobsPage> createState() => _MyJobsPageState();
}

class _MyJobsPageState extends ConsumerState<MyJobsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
    _tab.addListener(() => setState(() {}));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(jobsProvider.notifier).loadJobs(refresh: true);
    });
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final myJobsAsync = ref.watch(myJobsProvider);
    final globalJobs = ref.watch(jobsProvider).jobs;
    final profile = ref.watch(profileProvider).value;
    final myId = profile?.id;

    final List<JobEntity> apiMyJobs = myJobsAsync.value ?? [];
    final List<JobEntity> localMyJobs = globalJobs
        .where((j) => j.isMine(myId: myId, myName: profile?.fullName))
        .toList();

    // Combinar sin duplicados
    final Map<String, JobEntity> combinedMap = {};
    for (final j in apiMyJobs) {
      combinedMap[j.id] = j;
    }
    for (final j in localMyJobs) {
      combinedMap[j.id] = j;
    }
    final myJobs = combinedMap.values.toList();

    final active = myJobs
        .where(
          (j) => [
            'OPEN',
            'PUBLISHED',
            'RECEIVING_APPLICATIONS',
            'ASSIGNED',
            'IN_PROGRESS',
          ].contains(j.status.toUpperCase()),
        )
        .toList();
    final completed = myJobs.where((j) => j.status.toUpperCase() == 'COMPLETED').toList();
    final cancelled = myJobs
        .where((j) => ['CANCELLED', 'EXPIRED'].contains(j.status.toUpperCase()))
        .toList();

    final counts = [active.length, completed.length, cancelled.length];
    final tabs = ['Activos', 'Completados', 'Cancelados'];
    final colors = [
      AppColors.primary,
      AppColors.success,
      const Color(0xFF78909C),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ──
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          if (context.canPop()) {
                            context.pop();
                          } else {
                            context.go('/');
                          }
                        },
                        child: const Icon(
                          Icons.arrow_back_ios_new,
                          size: 18,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Mis trabajos',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textDark,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Tab bar custom
                  Row(
                    children: List.generate(3, (i) {
                      final isSelected = _tab.index == i;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => _tab.animateTo(i),
                          child: Column(
                            children: [
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? colors[i].withValues(alpha: 0.08)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Column(
                                  children: [
                                    Text(
                                      '${counts[i]}',
                                      style: TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.w800,
                                        color: isSelected
                                            ? colors[i]
                                            : AppColors.textHint,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      tabs[i],
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: isSelected
                                            ? FontWeight.w700
                                            : FontWeight.w500,
                                        color: isSelected
                                            ? colors[i]
                                            : AppColors.textHint,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                height: 3,
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? colors[i]
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),

            // ── Contenido ──
            Expanded(
              child: TabBarView(
                controller: _tab,
                children: [
                  _JobList(
                    jobs: active,
                    status: 'active',
                    color: AppColors.primary,
                  ),
                  _JobList(
                    jobs: completed,
                    status: 'completed',
                    color: AppColors.success,
                  ),
                  _JobList(
                    jobs: cancelled,
                    status: 'cancelled',
                    color: const Color(0xFF78909C),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _JobList extends StatelessWidget {
  final List<JobEntity> jobs;
  final String status;
  final Color color;

  const _JobList({
    required this.jobs,
    required this.status,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    if (jobs.isEmpty) return _Empty(status: status, color: color);

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      itemCount: jobs.length,
      itemBuilder: (context, i) => _JobTile(job: jobs[i], statusColor: color),
    );
  }
}

class _JobTile extends StatelessWidget {
  final JobEntity job;
  final Color statusColor;

  const _JobTile({required this.job, required this.statusColor});

  String get _statusLabel {
    switch (job.status) {
      case 'PUBLISHED':
        return 'Publicado';
      case 'RECEIVING_APPLICATIONS':
        return 'Recibiendo';
      case 'IN_SELECTION':
        return 'En selección';
      case 'ASSIGNED':
        return 'Asignado';
      case 'IN_PROGRESS':
        return 'En progreso';
      case 'COMPLETED':
        return 'Completado';
      case 'CANCELLED':
        return 'Cancelado';
      case 'EXPIRED':
        return 'Expirado';
      default:
        return job.status;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/jobs/${job.id}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        margin: const EdgeInsets.only(right: 5),
                        decoration: BoxDecoration(
                          color: statusColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      Text(
                        _statusLabel,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: statusColor,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (job.images.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: SizedBox(
                        width: 60,
                        height: 60,
                        child: JobEntity.buildImageWidget(
                          job.images.first,
                          fit: BoxFit.cover,
                          fallbackBuilder: () => Container(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            child: const Icon(Icons.work_rounded, color: AppColors.primary),
                          ),
                        ),
                      ),
                    ),
                  ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        job.title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textDark,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on_outlined,
                            size: 13,
                            color: AppColors.textHint,
                          ),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text(
                              job.address ?? 'Sin dirección',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 10),
            // Footer: postulantes, modalidad y precio — sin overflow
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Flexible(
                        child: _Chip(
                          icon: Icons.people_outline,
                          label: '${job.applicantsCount} postulantes',
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: _Chip(
                          icon: Icons.work_outline,
                          label: job.modalityLabel,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  job.formattedBudget,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _Chip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: AppColors.textHint),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            label,
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _Empty extends StatelessWidget {
  final String status;
  final Color color;
  const _Empty({required this.status, required this.color});

  @override
  Widget build(BuildContext context) {
    final (icon, title, sub) = switch (status) {
      'active' => (
        Icons.work_outline,
        'Sin trabajos activos',
        'Publica tu primer trabajo',
      ),
      'completed' => (
        Icons.task_alt,
        'Sin trabajos completados',
        'Aquí aparecerán tus trabajos terminados',
      ),
      _ => (Icons.cancel_outlined, 'Sin trabajos cancelados', 'Todo va bien'),
    };
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 40, color: color),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            sub,
            style: const TextStyle(fontSize: 13, color: AppColors.textHint),
          ),
        ],
      ),
    );
  }
}
