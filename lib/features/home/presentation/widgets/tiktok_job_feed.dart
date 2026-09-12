import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:laboraya_app/core/constants/app_colors.dart';
import 'package:laboraya_app/features/jobs/domain/entities/job_entity.dart';
import 'package:laboraya_app/features/favorites/presentation/providers/favorites_provider.dart';
import 'package:laboraya_app/features/home/presentation/widgets/job_card.dart';

class TikTokJobFeed extends StatefulWidget {
  final List<dynamic> jobs;
  final Future<void> Function() onRefresh;
  final VoidCallback? onToggleViewMode;

  const TikTokJobFeed({
    super.key,
    required this.jobs,
    required this.onRefresh,
    this.onToggleViewMode,
  });

  @override
  State<TikTokJobFeed> createState() => _TikTokJobFeedState();
}

class _TikTokJobFeedState extends State<TikTokJobFeed> {
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.jobs.isEmpty) {
      return const Center(
        child: Text(
          'No hay empleos disponibles.',
          style: TextStyle(
            fontFamily: 'Poppins',
            color: Color(0xFF64748B),
          ),
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: widget.onRefresh,
      child: PageView.builder(
        controller: _pageController,
        scrollDirection: Axis.vertical,
        itemCount: widget.jobs.length,
        itemBuilder: (context, index) {
          final item = widget.jobs[index];
          if (item is JobEntity) {
            return TikTokJobCard(
              job: item,
              itemIndex: index,
              totalItems: widget.jobs.length,
              onToggleViewMode: widget.onToggleViewMode,
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}

class TikTokJobCard extends ConsumerStatefulWidget {
  final JobEntity job;
  final int itemIndex;
  final int totalItems;
  final VoidCallback? onToggleViewMode;

  const TikTokJobCard({
    super.key,
    required this.job,
    required this.itemIndex,
    required this.totalItems,
    this.onToggleViewMode,
  });

  @override
  ConsumerState<TikTokJobCard> createState() => _TikTokJobCardState();
}

class _TikTokJobCardState extends ConsumerState<TikTokJobCard> {
  final PageController _imagePageController = PageController();
  int _currentImageIndex = 0;

  @override
  void dispose() {
    _imagePageController.dispose();
    super.dispose();
  }

  Widget _buildImageWidget(String path, Color catColor) {
    return JobEntity.buildImageWidget(
      path,
      fit: BoxFit.cover,
      fallbackBuilder: () => _buildCategoryBanner(catColor),
    );
  }

  Widget _buildCategoryBanner(Color catColor) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            catColor.withValues(alpha: 0.9),
            const Color(0xFF0F172A),
          ],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _categoryIcon(widget.job.categoryName),
              color: Colors.white.withValues(alpha: 0.9),
              size: 84,
            ),
            const SizedBox(height: 12),
            Text(
              widget.job.categoryName.toUpperCase(),
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: 2.0,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDescriptionBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                widget.job.title,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _categoryColor(widget.job.categoryName).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      widget.job.categoryName,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: _categoryColor(widget.job.categoryName),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    widget.job.formattedBudget,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'Descripción del trabajo:',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF334155),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                widget.job.description,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  color: Color(0xFF475569),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: () {
                    Navigator.pop(ctx);
                    context.push('/jobs/${widget.job.id}');
                  },
                  child: const Text(
                    'Ver Detalles Completos',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final favorites = ref.watch(favoritesProvider);
    final isFavorite = favorites.contains(widget.job.id);
    final catColor = _categoryColor(widget.job.categoryName);
    final hasImages = widget.job.images.isNotEmpty;

    return Container(
      color: Colors.black,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // ── 1. Fondo de Imagen / Carrusel / Gradiente ───────────────
          if (hasImages)
            PageView.builder(
              controller: _imagePageController,
              scrollDirection: Axis.horizontal,
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              itemCount: widget.job.images.length,
              onPageChanged: (idx) {
                setState(() => _currentImageIndex = idx);
              },
              itemBuilder: (ctx, imgIdx) {
                return _buildImageWidget(widget.job.images[imgIdx], catColor);
              },
            )
          else
            _buildCategoryBanner(catColor),

          // ── 2. Sombra Gradiente para Legibilidad ─────────────────────
          const IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black54,
                    Colors.transparent,
                    Colors.black38,
                    Colors.black87,
                  ],
                  stops: [0.0, 0.25, 0.65, 1.0],
                ),
              ),
            ),
          ),

          // ── 2b. Botones de Navegación Lateral (Flechas Izquierda / Derecha) ──
          if (hasImages && widget.job.images.length > 1) ...[
            if (_currentImageIndex > 0)
              Positioned(
                left: 12,
                top: MediaQuery.of(context).size.height * 0.38,
                child: GestureDetector(
                  onTap: () {
                    _imagePageController.previousPage(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeInOut,
                    );
                  },
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.55),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white38, width: 1.2),
                      boxShadow: const [
                        BoxShadow(color: Colors.black38, blurRadius: 4),
                      ],
                    ),
                    child: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
              ),
            if (_currentImageIndex < widget.job.images.length - 1)
              Positioned(
                right: 70,
                top: MediaQuery.of(context).size.height * 0.38,
                child: GestureDetector(
                  onTap: () {
                    _imagePageController.nextPage(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeInOut,
                    );
                  },
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.55),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white38, width: 1.2),
                      boxShadow: const [
                        BoxShadow(color: Colors.black38, blurRadius: 4),
                      ],
                    ),
                    child: const Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
              ),
          ],

          // ── 3. Indicador de imágenes y Contador ─────────────────────
          if (hasImages && widget.job.images.length > 1)
            Positioned(
              top: MediaQuery.of(context).padding.top + 64,
              left: 0,
              right: 0,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: Text(
                      '📷 ${_currentImageIndex + 1} / ${widget.job.images.length}',
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Center(
                    child: AnimatedSmoothIndicator(
                      activeIndex: _currentImageIndex,
                      count: widget.job.images.length,
                      effect: const ExpandingDotsEffect(
                        dotWidth: 7,
                        dotHeight: 7,
                        activeDotColor: Colors.white,
                        dotColor: Colors.white38,
                        expansionFactor: 3,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // ── 4. Columna de Acciones Flotantes (Derecha - TikTok) ──────
          Positioned(
            right: 14,
            bottom: 100,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Avatar del Empleador
                GestureDetector(
                  onTap: () => context.push('/jobs/${widget.job.id}'),
                  child: Stack(
                    alignment: Alignment.bottomCenter,
                    children: [
                      Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 6,
                            ),
                          ],
                        ),
                        child: () {
                          final avatarProvider = JobEntity.getAvatarImageProvider(widget.job.publisherAvatar);
                          return CircleAvatar(
                            radius: 24,
                            backgroundColor: AppColors.primary,
                            backgroundImage: avatarProvider,
                            child: avatarProvider == null
                                ? Text(
                                    widget.job.publisherName.isNotEmpty
                                        ? widget.job.publisherName[0].toUpperCase()
                                        : 'U',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                  )
                                : null,
                          );
                        }(),
                      ),
                      if (widget.job.isPublisherVerified)
                        Positioned(
                          bottom: 4,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 10,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // Me Gusta / Favorito (Heart)
                _TikTokActionButton(
                  icon: isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                  iconColor: isFavorite ? const Color(0xFFEF4444) : Colors.white,
                  label: isFavorite ? 'Guardado' : 'Guardar',
                  onTap: () {
                    ref.read(favoritesProvider.notifier).toggle(widget.job.id);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          !isFavorite
                              ? '📌 Guardado en tus favoritos. ¡Le avisamos al empleador!'
                              : 'Eliminado de tus favoritos',
                          style: const TextStyle(fontFamily: 'Poppins'),
                        ),
                        duration: const Duration(seconds: 2),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 18),

                // Comentarios Públicos
                _TikTokActionButton(
                  icon: Icons.chat_bubble_rounded,
                  iconColor: Colors.white,
                  label: 'Comentar',
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (ctx) => JobCommentsBottomSheet(
                        job: widget.job,
                        onCommentAdded: () {},
                      ),
                    );
                  },
                ),
                const SizedBox(height: 18),

                // Compartir
                _TikTokActionButton(
                  icon: Icons.share_rounded,
                  iconColor: Colors.white,
                  label: 'Compartir',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Compartiendo "${widget.job.title}"'),
                        behavior: SnackBarBehavior.floating,
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 18),

                // Ver Detalles
                _TikTokActionButton(
                  icon: Icons.info_outline_rounded,
                  iconColor: Colors.white,
                  label: 'Info',
                  onTap: () => context.push('/jobs/${widget.job.id}'),
                ),
              ],
            ),
          ),

          // ── 5. Panel de Información Inferior (Izquierda - TikTok) ────
          Positioned(
            left: 16,
            right: 80,
            bottom: 24,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Nombre del empleador
                Row(
                  children: [
                    Text(
                      '@${widget.job.publisherName}',
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        shadows: [
                          Shadow(color: Colors.black54, blurRadius: 4),
                        ],
                      ),
                    ),
                    if (widget.job.isPublisherVerified) ...[
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.verified_rounded,
                        color: AppColors.primary,
                        size: 15,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 6),

                // Título del empleo
                Text(
                  widget.job.title,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    height: 1.25,
                    shadows: [
                      Shadow(color: Colors.black87, blurRadius: 6),
                    ],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),

                // Etiquetas (Categoría, Modalidad, Urgente)
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: catColor.withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        widget.job.categoryName,
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.white38),
                      ),
                      child: Text(
                        widget.job.modalityLabel,
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    if (widget.job.isUrgent)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF4444),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.flash_on_rounded, size: 12, color: Colors.white),
                            SizedBox(width: 2),
                            Text(
                              'URGENTE',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),

                // Precio / Presupuesto destacado
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: Text(
                    widget.job.formattedBudget,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // Ubicación
                Row(
                  children: [
                    const Icon(
                      Icons.location_on_rounded,
                      size: 14,
                      color: Colors.white70,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        '${widget.job.address ?? "Miraflores, Lima"} • 0.5 km',
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 12,
                          color: Colors.white70,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),

                // Snippet de descripción
                GestureDetector(
                  onTap: _showDescriptionBottomSheet,
                  child: Text(
                    widget.job.description,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      color: Colors.white70,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 12),

                // Botón Principal de Postulación
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () => context.push('/jobs/${widget.job.id}'),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'POSTULARME AHORA',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                        SizedBox(width: 8),
                        Icon(
                          Icons.arrow_forward_rounded,
                          size: 16,
                          color: Colors.white,
                        ),
                      ],
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

// ─── Botón de Acción Estilo TikTok ──────────────────────────────────────────

class _TikTokActionButton extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final VoidCallback onTap;

  const _TikTokActionButton({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.45),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white24, width: 1),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.white,
              shadows: [
                Shadow(color: Colors.black87, blurRadius: 4),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

Color _categoryColor(String cat) {
  switch (cat.toLowerCase()) {
    case 'plomería':
    case 'plomero':
      return const Color(0xFF0D6EFD);
    case 'electricidad':
    case 'electricista':
      return const Color(0xFFD97706);
    case 'pintura':
    case 'pintor':
      return const Color(0xFF7C3AED);
    case 'carpintería':
    case 'carpintero':
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
    case 'plomero':
      return Icons.plumbing_rounded;
    case 'electricidad':
    case 'electricista':
      return Icons.electrical_services_rounded;
    case 'pintura':
    case 'pintor':
      return Icons.format_paint_rounded;
    case 'carpintería':
    case 'carpintero':
      return Icons.carpenter_rounded;
    case 'albañilería':
      return Icons.construction_rounded;
    case 'limpieza':
      return Icons.cleaning_services_rounded;
    case 'cerrajería':
      return Icons.lock_rounded;
    default:
      return Icons.work_rounded;
  }
}
