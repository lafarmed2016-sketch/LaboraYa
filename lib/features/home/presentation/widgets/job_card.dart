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
    final formatted = JobEntity.formatUrl(path);
    if (formatted.startsWith('http')) {
      return Image.network(
        formatted,
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
        child: Column(
          children: [
            Row(
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
            const SizedBox(height: 10),
            // Barra de interacciones tipo TikTok / Redes
            _SocialBar(job: job),
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
    final formatted = JobEntity.formatUrl(path);
    if (formatted.startsWith('http')) {
      return Image.network(
        formatted,
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

// ─── Barra de Interacción Social (Reaccionar, Comentar, Compartir, Guardar) ──────

class _SocialBar extends StatefulWidget {
  final JobEntity job;
  const _SocialBar({required this.job});

  @override
  State<_SocialBar> createState() => _SocialBarState();
}

class _SocialBarState extends State<_SocialBar> with SingleTickerProviderStateMixin {
  bool _isLiked = false;
  late int _likeCount;
  late int _commentCount;
  bool _isBookmarked = false;
  late AnimationController _heartAnimCtrl;
  late Animation<double> _heartScale;

  @override
  void initState() {
    super.initState();
    final hash = widget.job.id.hashCode.abs();
    _likeCount = (hash % 38) + 8;
    _commentCount = (hash % 10) + 2;

    _heartAnimCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _heartScale = Tween<double>(begin: 1.0, end: 1.35).animate(
      CurvedAnimation(parent: _heartAnimCtrl, curve: Curves.elasticOut),
    );
  }

  @override
  void dispose() {
    _heartAnimCtrl.dispose();
    super.dispose();
  }

  void _toggleLike() {
    setState(() {
      _isLiked = !_isLiked;
      _likeCount += _isLiked ? 1 : -1;
    });
    _heartAnimCtrl.forward().then((_) => _heartAnimCtrl.reverse());
  }

  void _showCommentsModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _JobCommentsBottomSheet(
        job: widget.job,
        onCommentAdded: () {
          setState(() {
            _commentCount++;
          });
        },
      ),
    );
  }

  void _shareJob(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Text(
              'Compartir este trabajo',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _ShareOptionTile(
                  icon: Icons.chat_rounded,
                  label: 'WhatsApp',
                  color: const Color(0xFF25D366),
                  onTap: () {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Abriendo WhatsApp para compartir...'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                ),
                _ShareOptionTile(
                  icon: Icons.link_rounded,
                  label: 'Copiar Link',
                  color: AppColors.primary,
                  onTap: () {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('¡Enlace de trabajo copiado al portapapeles!'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                ),
                _ShareOptionTile(
                  icon: Icons.send_rounded,
                  label: 'Enviar',
                  color: const Color(0xFF0088CC),
                  onTap: () {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Enviando publicación...'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 10, left: 4, right: 4),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0xFFF1F5F9), width: 1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // ❤️ Reaccionar
          GestureDetector(
            onTap: _toggleLike,
            behavior: HitTestBehavior.opaque,
            child: Row(
              children: [
                ScaleTransition(
                  scale: _heartScale,
                  child: Icon(
                    _isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                    color: _isLiked ? const Color(0xFFEF4444) : const Color(0xFF64748B),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 5),
                Text(
                  '$_likeCount',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _isLiked ? const Color(0xFFEF4444) : const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),

          // 💬 Comentar
          GestureDetector(
            onTap: () => _showCommentsModal(context),
            behavior: HitTestBehavior.opaque,
            child: Row(
              children: [
                const Icon(
                  Icons.chat_bubble_outline_rounded,
                  color: Color(0xFF64748B),
                  size: 19,
                ),
                const SizedBox(width: 5),
                Text(
                  '$_commentCount',
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),

          // 🔗 Compartir
          GestureDetector(
            onTap: () => _shareJob(context),
            behavior: HitTestBehavior.opaque,
            child: const Row(
              children: [
                Icon(
                  Icons.share_outlined,
                  color: Color(0xFF64748B),
                  size: 19,
                ),
                SizedBox(width: 4),
                Text(
                  'Compartir',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),

          // 📌 Guardar
          GestureDetector(
            onTap: () {
              setState(() => _isBookmarked = !_isBookmarked);
            },
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.all(2.0),
              child: Icon(
                _isBookmarked ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                color: _isBookmarked ? AppColors.primary : const Color(0xFF64748B),
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Modal de Comentarios ─────────────────────────────────────────────────────

class _JobCommentsBottomSheet extends StatefulWidget {
  final JobEntity job;
  final VoidCallback onCommentAdded;

  const _JobCommentsBottomSheet({
    required this.job,
    required this.onCommentAdded,
  });

  @override
  State<_JobCommentsBottomSheet> createState() => _JobCommentsBottomSheetState();
}

class _JobCommentsBottomSheetState extends State<_JobCommentsBottomSheet> {
  final TextEditingController _commentCtrl = TextEditingController();
  final List<Map<String, String>> _comments = [
    {
      'user': 'Carlos Mendoza',
      'avatar': 'C',
      'text': '¡Hola! ¿Aún está disponible el trabajo?',
      'time': 'Hace 10 min'
    },
    {
      'user': 'María Elena',
      'avatar': 'M',
      'text': 'Buenas tardes, estoy interesada y cuento con disponibilidad inmediata.',
      'time': 'Hace 25 min'
    },
    {
      'user': 'Jorge Ramírez',
      'avatar': 'J',
      'text': 'Tengo herramientas propias y años de experiencia.',
      'time': 'Hace 1 hora'
    },
  ];

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  void _sendComment() {
    final text = _commentCtrl.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _comments.insert(0, {
        'user': 'Tú',
        'avatar': 'T',
        'text': text,
        'time': 'Ahora mismo',
      });
      _commentCtrl.clear();
    });
    widget.onCommentAdded();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.65,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Handle & Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Column(
              children: [
                Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Comentarios (${_comments.length})',
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 20),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const Divider(height: 1),
              ],
            ),
          ),

          // Lista de Comentarios
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: _comments.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (ctx, i) {
                final c = _comments[i];
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                      child: Text(
                        c['avatar']!,
                        style: const TextStyle(
                          fontFamily: 'Poppins',
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
                          Row(
                            children: [
                              Text(
                                c['user']!,
                                style: const TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                c['time']!,
                                style: const TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 10.5,
                                  color: Color(0xFF94A3B8),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            c['text']!,
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 12,
                              color: Color(0xFF334155),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),

          // Input de Comentario al pie (keyboard responsive)
          Padding(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 8,
              bottom: MediaQuery.of(context).viewInsets.bottom + 12,
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentCtrl,
                    decoration: InputDecoration(
                      hintText: 'Añadir un comentario...',
                      hintStyle: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12.5,
                        color: Color(0xFF94A3B8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      fillColor: const Color(0xFFF8FAFC),
                      filled: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: const BorderSide(color: AppColors.primary),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _sendComment,
                  icon: const Icon(Icons.send_rounded, color: AppColors.primary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Opción de Compartir ──────────────────────────────────────────────────────

class _ShareOptionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ShareOptionTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

