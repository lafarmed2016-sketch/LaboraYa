import 'dart:io';
import 'package:flutter/material.dart';
import 'package:laboraya_app/core/constants/app_colors.dart';
import 'package:laboraya_app/features/jobs/domain/entities/job_entity.dart';

// ─── JobCard ──────────────────────────────────────────────────────────────────

class JobCard extends StatelessWidget {
  final JobEntity job;
  final VoidCallback? onTap;
  final bool compact;

  const JobCard({
    super.key,
    required this.job,
    this.onTap,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return compact
        ? _UrgentCard(job: job, onTap: onTap)
        : _MainCard(job: job, onTap: onTap);
  }
}

// ─── Main card ────────────────────────────────────────────────────────────────

class _MainCard extends StatelessWidget {
  final JobEntity job;
  final VoidCallback? onTap;
  const _MainCard({required this.job, this.onTap});

  Widget _buildImageWidget(String path, Color catColor) {
    if (path.startsWith('http')) {
      return Image.network(
        path,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _buildCategoryBanner(catColor),
      );
    } else {
      return Image.file(
        File(path),
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _buildCategoryBanner(catColor),
      );
    }
  }

  Widget _buildCategoryBanner(Color catColor) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            catColor.withValues(alpha: 0.18),
            catColor.withValues(alpha: 0.08),
          ],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _categoryIcon(job.categoryName),
              color: catColor,
              size: 42,
            ),
            const SizedBox(height: 6),
            Text(
              job.categoryName,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: catColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final catColor = _categoryColor(job.categoryName);
    final hasRealImage = job.images.isNotEmpty;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
          boxShadow: const [
            BoxShadow(
              color: Color(0x08000000),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Thumbnail imagen cuadrada 76x76
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width: 76,
                height: 76,
                child: hasRealImage
                    ? _buildImageWidget(job.images.first, catColor)
                    : _buildCategoryBanner(catColor),
              ),
            ),
            const SizedBox(width: 12),

            // Info del trabajo
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    job.title,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_rounded,
                        size: 13,
                        color: Color(0xFF94A3B8),
                      ),
                      const SizedBox(width: 2),
                      Expanded(
                        child: Text(
                          '${job.address ?? "Miraflores, Lima"} • 0.5 km',
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 11,
                            color: Color(0xFF64748B),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      job.modalityLabel,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),

            // Precio destacado en azul / etiqueta Urgente
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (job.isUrgent)
                  Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFECEB),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'URGENTE',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFFEF4444),
                      ),
                    ),
                  ),
                Text(
                  job.formattedBudget,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 16,
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

// ─── Urgent card (Horizontal List) ──────────────────────────────────────────

class _UrgentCard extends StatelessWidget {
  final JobEntity job;
  final VoidCallback? onTap;
  const _UrgentCard({required this.job, this.onTap});

  Widget _buildImageWidget(String path, Color catColor) {
    if (path.startsWith('http')) {
      return Image.network(
        path,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _buildCategoryBanner(catColor),
      );
    } else {
      return Image.file(
        File(path),
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _buildCategoryBanner(catColor),
      );
    }
  }

  Widget _buildCategoryBanner(Color catColor) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            catColor.withValues(alpha: 0.18),
            catColor.withValues(alpha: 0.08),
          ],
        ),
      ),
      child: Center(
        child: Icon(
          _categoryIcon(job.categoryName),
          color: catColor,
          size: 36,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final catColor = _categoryColor(job.categoryName);
    final hasRealImage = job.images.isNotEmpty;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 230,
        margin: const EdgeInsets.only(right: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border, width: 0.8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(18),
              ),
              child: SizedBox(
                height: 120,
                width: double.infinity,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    hasRealImage
                        ? _buildImageWidget(job.images.first, catColor)
                        : _buildCategoryBanner(catColor),
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      height: 60,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [
                              Colors.black.withValues(alpha: 0.65),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.urgent,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.flash_on_rounded,
                              size: 10,
                              color: Colors.white,
                            ),
                            SizedBox(width: 2),
                            Text(
                              'Urgente',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 8,
                      left: 10,
                      child: Text(
                        job.formattedBudget,
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          shadows: [
                            Shadow(color: Color(0x99000000), blurRadius: 6),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    job.title,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      height: 1.25,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_rounded,
                        size: 12,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          job.address ?? 'Lima, Perú',
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 11,
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
      ),
    );
  }
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

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

// ─── Favorite button ──────────────────────────────────────────────────────────

class _FavoriteButton extends StatefulWidget {
  final String jobId;
  const _FavoriteButton({required this.jobId});

  @override
  State<_FavoriteButton> createState() => _FavoriteButtonState();
}

class _FavoriteButtonState extends State<_FavoriteButton>
    with SingleTickerProviderStateMixin {
  bool _saved = false;
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
      lowerBound: 0,
      upperBound: 1,
    );
    _scale = Tween<double>(
      begin: 1.0,
      end: 1.3,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() => _saved = !_saved);
    _ctrl.forward().then((_) => _ctrl.reverse());
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _toggle,
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.92),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 8,
              ),
            ],
          ),
          child: Icon(
            _saved ? Icons.favorite_rounded : Icons.favorite_border_rounded,
            size: 17,
            color: _saved ? AppColors.error : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
