import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:laboraya_app/core/constants/app_colors.dart';
import 'package:laboraya_app/core/storage/secure_storage.dart';
import 'package:laboraya_app/features/reviews/presentation/providers/reviews_provider.dart';

class MyReviewsPage extends ConsumerWidget {
  const MyReviewsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userIdFuture = ref.watch(secureStorageProvider).getUserId();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        child: FutureBuilder<String?>(
          future: userIdFuture,
          builder: (ctx, snap) {
            final userId = snap.data ?? 'user_demo';
            final reviewsAsync = ref.watch(userReviewsProvider(userId));

            return Column(
              children: [
                // ── Header azul con resumen ──
                Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF0D2137), Color(0xFF1A3A5C)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: const Icon(
                              Icons.arrow_back_ios_new,
                              size: 18,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 14),
                          const Text(
                            'Mis calificaciones',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      reviewsAsync.when(
                        loading: () => const CircularProgressIndicator(
                          color: Colors.white,
                        ),
                        error: (_, __) => const _SummaryContent(avg: 0.0, total: 0),
                        data: (reviews) => reviews.isEmpty
                            ? const _SummaryContent(avg: 0.0, total: 0)
                            : _Summary(reviews: reviews),
                      ),
                    ],
                  ),
                ),
                // ── Lista ──
                Expanded(
                  child: reviewsAsync.when(
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (_, __) => _EmptyState(),
                    data: (reviews) => reviews.isEmpty
                        ? _EmptyState()
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                            itemCount: reviews.length,
                            itemBuilder: (ctx, i) =>
                                _ReviewCard(review: reviews[i]),
                          ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Summary extends StatelessWidget {
  final List reviews;
  const _Summary({required this.reviews});

  @override
  Widget build(BuildContext context) {
    if (reviews.isEmpty) {
      return const _SummaryContent(avg: 0.0, total: 0);
    }
    final avg =
        reviews.fold<double>(0, (s, r) => s + (r.rating as double)) /
        reviews.length;
    return _SummaryContent(avg: avg, total: reviews.length);
  }
}

class _SummaryContent extends StatelessWidget {
  final double avg;
  final int total;
  const _SummaryContent({required this.avg, required this.total});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              avg.toStringAsFixed(1),
              style: const TextStyle(
                fontSize: 52,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                height: 1,
              ),
            ),
            const Text(
              'de 5.0',
              style: TextStyle(fontSize: 13, color: Colors.white60),
            ),
          ],
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RatingBarIndicator(
                rating: avg,
                itemBuilder: (_, __) =>
                    const Icon(Icons.star, color: AppColors.star),
                itemCount: 5,
                itemSize: 22,
              ),
              const SizedBox(height: 6),
              Text(
                '$total reseñas en total',
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
              const SizedBox(height: 6),
              // Barras de distribución
              ...List.generate(5, (i) {
                final star = 5 - i;
                final pct = star == 5
                    ? 0.68
                    : star == 4
                    ? 0.20
                    : star == 3
                    ? 0.08
                    : 0.02;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 3),
                  child: Row(
                    children: [
                      Text(
                        '$star',
                        style: const TextStyle(
                          color: Colors.white60,
                          fontSize: 10,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.star, size: 10, color: AppColors.star),
                      const SizedBox(width: 6),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: pct,
                            minHeight: 5,
                            backgroundColor: Colors.white12,
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              AppColors.star,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final dynamic review;
  const _ReviewCard({required this.review});

  @override
  Widget build(BuildContext context) {
    return Container(
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
              CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                child: Text(
                  (review.reviewerFirstName?.isNotEmpty == true)
                      ? review.reviewerFirstName[0]
                      : '?',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${review.reviewerFirstName ?? ''} ${review.reviewerLastName ?? ''}'
                          .trim(),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (review.jobTitle != null)
                      Text(
                        review.jobTitle!,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textHint,
                        ),
                      ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  RatingBarIndicator(
                    rating: (review.rating as double),
                    itemBuilder: (_, __) =>
                        const Icon(Icons.star, color: AppColors.star),
                    itemCount: 5,
                    itemSize: 14,
                  ),
                  Text(
                    review.createdAt != null
                        ? _timeAgo(review.createdAt as DateTime)
                        : '',
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.textHint,
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (review.comment != null && review.comment!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F9FB),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                review.comment!,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inDays > 30)
      return 'Hace ${(diff.inDays / 30).floor()} mes${diff.inDays > 60 ? 'es' : ''}';
    if (diff.inDays > 0)
      return 'Hace ${diff.inDays} día${diff.inDays > 1 ? 's' : ''}';
    }
    if (diff.inHours > 0) {
      return 'Hace ${diff.inHours} hora${diff.inHours > 1 ? 's' : ''}';
    }
    return 'Hace un momento';
  }
}

class _StaticReviews extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: const [
        _StaticCard(
          name: 'María García',
          job: 'Reparación de fuga',
          rating: 5.0,
          comment:
              'Excelente trabajo, muy profesional y puntual. Lo recomiendo.',
          time: 'Hace 3 días',
        ),
        _StaticCard(
          name: 'Carlos López',
          job: 'Instalación de grifería',
          rating: 4.5,
          comment: 'Buen trabajo, cumplió con lo acordado.',
          time: 'Hace 1 semana',
        ),
        _StaticCard(
          name: 'Ana Torres',
          job: 'Pintura de sala',
          rating: 5.0,
          comment: 'Recomendado! Muy limpio y ordenado al trabajar.',
          time: 'Hace 2 semanas',
        ),
      ],
    );
  }
}

class _StaticCard extends StatelessWidget {
  final String name, job, comment, time;
  final double rating;
  const _StaticCard({
    required this.name,
    required this.job,
    required this.rating,
    required this.comment,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
              CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                child: Text(
                  name[0],
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      job,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textHint,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  RatingBarIndicator(
                    rating: rating,
                    itemBuilder: (_, __) =>
                        const Icon(Icons.star, color: AppColors.star),
                    itemCount: 5,
                    itemSize: 14,
                  ),
                  Text(
                    time,
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.textHint,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FB),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              comment,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: AppColors.star.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.star_border, size: 40, color: AppColors.star),
        ),
        const SizedBox(height: 16),
        const Text(
          'Sin calificaciones aún',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 6),
        const Text(
          'Completa trabajos para recibir reseñas',
          style: TextStyle(fontSize: 13, color: AppColors.textHint),
        ),
      ],
    ),
  );
}
