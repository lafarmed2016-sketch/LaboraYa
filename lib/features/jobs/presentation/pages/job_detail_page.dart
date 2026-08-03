import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:laboraya_app/core/constants/app_colors.dart';
import 'package:laboraya_app/features/favorites/presentation/providers/favorites_provider.dart';
import 'package:laboraya_app/features/applications/presentation/providers/applications_provider.dart';
import 'package:laboraya_app/features/jobs/presentation/providers/jobs_provider.dart';
import 'package:laboraya_app/features/profile/presentation/providers/profile_provider.dart';
import 'package:timeago/timeago.dart' as timeago;

// ─── JobDetailPage ────────────────────────────────────────────────────────────

class JobDetailPage extends ConsumerWidget {
  final String jobId;
  const JobDetailPage({super.key, required this.jobId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final jobAsync = ref.watch(jobDetailProvider(jobId));

    return jobAsync.when(
      loading: () => const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          leading: _BackButton(onBack: () => context.pop()),
        ),
        body: Center(
          child: Text(
            'Error al cargar el trabajo.',
            style: const TextStyle(fontFamily: 'Poppins'),
          ),
        ),
      ),
      data: (job) {
        if (job == null) {
          return Scaffold(
            appBar: AppBar(
              backgroundColor: Colors.white,
              leading: _BackButton(onBack: () => context.pop()),
            ),
            body: const Center(
              child: Text(
                'Trabajo no encontrado.',
                style: TextStyle(fontFamily: 'Poppins'),
              ),
            ),
          );
        }

        final profile = ref.watch(profileProvider).value;
        final isFav = ref.watch(favoritesProvider).contains(job.id);
        final hasApplied = ref
            .watch(applicationsProvider)
            .any((a) => a.jobId == job.id);

        return Scaffold(
          backgroundColor: AppColors.background,
          body: CustomScrollView(
            slivers: [
              // ── Galería ──────────────────────────────────────────
              SliverToBoxAdapter(
                child: _JobGallery(
                  images: job.images,
                  category: job.categoryName,
                  title: job.title,
                  isFav: isFav,
                  onBack: () => context.pop(),
                  onFav: () =>
                      ref.read(favoritesProvider.notifier).toggle(job.id),
                  onShare: () => _share(context, job.title),
                ),
              ),

              // ── Contenido ─────────────────────────────────────────
              SliverToBoxAdapter(
                child: Container(
                  color: Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Chips: categoría + urgente
                        Wrap(
                          spacing: 8,
                          children: [
                            _Chip(
                              label: job.categoryName,
                              color: AppColors.primary,
                            ),
                            _Chip(
                              label: job.modalityLabel,
                              color: AppColors.primaryDark,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // Título
                        Text(
                          job.title,
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 10),
                        // Precio
                        Text(
                          job.formattedBudget,
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          job.modalityLabel,
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 12,
                            color: AppColors.textHint,
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Meta row
                        Wrap(
                          spacing: 16,
                          runSpacing: 8,
                          children: [
                            _MetaItem(
                              icon: Icons.location_on_rounded,
                              text: job.address ?? 'Sin dirección',
                            ),
                            _MetaItem(
                              icon: Icons.schedule_rounded,
                              text: timeago.format(
                                job.publishedAt ?? job.createdAt,
                                locale: 'es',
                              ),
                            ),
                            _MetaItem(
                              icon: Icons.people_alt_rounded,
                              text:
                                  '${job.applicantsCount} postulante${job.applicantsCount == 1 ? '' : 's'}',
                            ),
                            if (job.workersNeeded > 1)
                              _MetaItem(
                                icon: Icons.engineering_rounded,
                                text: '${job.workersNeeded} personas',
                              ),
                          ],
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),

              // ── Secciones de detalle ──────────────────────────────
              SliverList(
                delegate: SliverChildListDelegate([
                  _Section(
                    title: 'Descripción',
                    child: Text(
                      job.description,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 14,
                        color: AppColors.textSecondary,
                        height: 1.6,
                      ),
                    ),
                  ),
                  _Section(
                    title: 'Detalles del trabajo',
                    child: Column(
                      children: [
                        if (job.duration != null)
                          _DetailRow(
                            icon: Icons.timer_outlined,
                            label: 'Duración',
                            value: job.duration!,
                          ),
                        _DetailRow(
                          icon: Icons.build_outlined,
                          label: 'Materiales',
                          value: job.materialsLabel,
                        ),
                        if (job.experienceReq != null)
                          _DetailRow(
                            icon: Icons.school_outlined,
                            label: 'Experiencia',
                            value: job.experienceReq!,
                          ),
                        _DetailRow(
                          icon: Icons.people_outline,
                          label: 'Trabajadores',
                          value: '${job.workersNeeded} persona(s)',
                        ),
                        if (job.requiredDate != null)
                          _DetailRow(
                            icon: Icons.calendar_today_outlined,
                            label: 'Fecha requerida',
                            value: job.requiredDate!,
                          ),
                      ],
                    ),
                  ),
                  _Section(
                    title: 'Ubicación aproximada',
                    child: Container(
                      height: 80,
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.map_outlined,
                            color: AppColors.primary,
                            size: 28,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            job.address ?? 'Ubicación no especificada',
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 13,
                              color: AppColors.primary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  _Section(
                    title: 'Publicado por',
                    child: _PublisherCard(job: job),
                  ),
                  _Section(
                    title: 'Recomendaciones de seguridad',
                    child: const _SecurityTips(),
                  ),
                  const SizedBox(height: 100),
                ]),
              ),
            ],
          ),
          // ── Footer ────────────────────────────────────────────────
          bottomNavigationBar: _JobFooter(
            job: job,
            hasApplied: hasApplied,
            isMyJob: job.isMine(myId: profile?.id, myName: profile?.fullName),
            onApply: () => _showApplySheet(context, ref, job),
            onChat: () => context.push(
              '/chat/new_${job.publisherId}',
              extra: {
                'name': job.publisherName,
                'avatar': job.publisherAvatar,
                'participantId': job.publisherId,
              },
            ),
          ),
        );
      },
    );
  }

  void _share(BuildContext context, String title) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const Text(
              'Compartir empleo',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 20),
            ListTile(
              onTap: () {
                Clipboard.setData(
                  ClipboardData(text: 'https://laboraya.com/jobs/$jobId'),
                );
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('✅ Enlace copiado al portapapeles'),
                    backgroundColor: AppColors.success,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFEBF3FC),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.link_rounded,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              title: const Text(
                'Copiar enlace de esta publicación',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              trailing: const Icon(
                Icons.copy_rounded,
                size: 18,
                color: AppColors.textHint,
              ),
            ),
            const SizedBox(height: 8),
            ListTile(
              onTap: () {
                Clipboard.setData(
                  ClipboardData(
                    text: 'LaboraYa: $title - https://laboraya.com/jobs/$jobId',
                  ),
                );
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      '✅ Información del trabajo lista para compartir',
                    ),
                    backgroundColor: AppColors.success,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.send_rounded,
                  color: AppColors.success,
                  size: 20,
                ),
              ),
              title: const Text(
                'Compartir con mis contactos',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              trailing: const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: AppColors.textHint,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showApplySheet(BuildContext context, WidgetRef ref, dynamic job) {
    final msgCtrl = TextEditingController();
    final budgetCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 20,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const Text(
              'Enviar postulación',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: msgCtrl,
              maxLines: 3,
              style: const TextStyle(fontFamily: 'Poppins', fontSize: 14),
              decoration: const InputDecoration(
                hintText: 'Mensaje de presentación...',
                hintStyle: TextStyle(fontFamily: 'Poppins'),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: budgetCtrl,
              keyboardType: TextInputType.number,
              style: const TextStyle(fontFamily: 'Poppins', fontSize: 14),
              decoration: const InputDecoration(
                hintText: 'Tu propuesta económica',
                prefixText: 'S/ ',
                hintStyle: TextStyle(fontFamily: 'Poppins'),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () async {
                  final budget = double.tryParse(budgetCtrl.text) ?? 0;
                  await ref
                      .read(applicationsProvider.notifier)
                      .apply(
                        jobId: job.id,
                        jobTitle: job.title,
                        employerName: job.publisherName,
                        budget: budget,
                        message: msgCtrl.text,
                      );
                  if (ctx.mounted) Navigator.pop(ctx);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          '¡Postulación enviada!',
                          style: TextStyle(fontFamily: 'Poppins'),
                        ),
                        backgroundColor: AppColors.success,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'Enviar postulación',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Galería ──────────────────────────────────────────────────────────────────

class _JobGallery extends StatefulWidget {
  final List<String> images;
  final String category;
  final String title;
  final bool isFav;
  final VoidCallback onBack;
  final VoidCallback onFav;
  final VoidCallback onShare;

  const _JobGallery({
    required this.images,
    required this.category,
    required this.title,
    required this.isFav,
    required this.onBack,
    required this.onFav,
    required this.onShare,
  });

  @override
  State<_JobGallery> createState() => _JobGalleryState();
}

class _JobGalleryState extends State<_JobGallery> {
  int _current = 0;

  @override
  Widget build(BuildContext context) {
    final hasImages = widget.images.isNotEmpty;

    return SizedBox(
      height: 260,
      child: Stack(
        children: [
          // Imagen
          if (hasImages)
            PageView.builder(
              itemCount: widget.images.length,
              onPageChanged: (i) => setState(() => _current = i),
              itemBuilder: (_, i) {
                final imgPath = widget.images[i];
                if (imgPath.startsWith('/') || !imgPath.startsWith('http')) {
                  return Image.file(
                    File(imgPath),
                    fit: BoxFit.cover,
                    width: double.infinity,
                    errorBuilder: (_, __, ___) => _CategoryBannerPlaceholder(category: widget.category),
                  );
                }
                return Image.network(
                  imgPath,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  errorBuilder: (_, __, ___) => _CategoryBannerPlaceholder(category: widget.category),
                );
              },
            )
          else
            _CategoryBannerPlaceholder(category: widget.category),

          // Degradado superior
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 100,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.5),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // Botones top
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 12,
            right: 12,
            child: Row(
              children: [
                _BackButton(onBack: widget.onBack),
                const Spacer(),
                _IconCircle(
                  icon: widget.isFav
                      ? Icons.bookmark_rounded
                      : Icons.bookmark_outline_rounded,
                  color: widget.isFav ? AppColors.primary : Colors.white,
                  onTap: widget.onFav,
                ),
                const SizedBox(width: 8),
                _IconCircle(
                  icon: Icons.share_rounded,
                  color: Colors.white,
                  onTap: widget.onShare,
                ),
              ],
            ),
          ),

          // Contador de imágenes
          if (widget.images.length > 1)
            Positioned(
              bottom: 14,
              right: 14,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_current + 1} / ${widget.images.length}',
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _CategoryBannerPlaceholder extends StatelessWidget {
  final String category;
  const _CategoryBannerPlaceholder({required this.category});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 260,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1E3A8A),
            Color(0xFF3B82F6),
          ],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.work_outline_rounded,
              color: Colors.white70,
              size: 54,
            ),
            const SizedBox(height: 10),
            Text(
              category,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Publicación sin imágenes adjuntas',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12,
                color: Colors.white60,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Footer del detalle ───────────────────────────────────────────────────────

class _JobFooter extends StatelessWidget {
  final dynamic job;
  final bool hasApplied;
  final bool isMyJob;
  final VoidCallback onApply;
  final VoidCallback onChat;

  const _JobFooter({
    required this.job,
    required this.hasApplied,
    this.isMyJob = false,
    required this.onApply,
    required this.onChat,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.border, width: 0.8)),
      ),
      child: Row(
        children: [
          // Precio
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Presupuesto',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 11,
                  color: AppColors.textHint,
                ),
              ),
              Text(
                job.formattedBudget,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          if (isMyJob)
            Expanded(
              child: Container(
                height: 50,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                ),
                alignment: Alignment.center,
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.person_pin_rounded, color: AppColors.primary, size: 18),
                    SizedBox(width: 8),
                    Text(
                      'Tu publicación',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else ...[
            // Botón chat
            SizedBox(
              height: 50,
              child: OutlinedButton.icon(
                onPressed: onChat,
                icon: const Icon(Icons.chat_bubble_outline_rounded, size: 16),
                label: const Text(
                  'Chat',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary, width: 1.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            // Botón postular
            Expanded(
              child: SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: hasApplied ? null : onApply,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: hasApplied
                        ? AppColors.success
                        : AppColors.primary,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: AppColors.success,
                    disabledForegroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    hasApplied ? '✓ Postulado' : 'Postularme',
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Sección reutilizable ─────────────────────────────────────────────────────

class _Section extends StatelessWidget {
  final String title;
  final Widget child;
  const _Section({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

// ─── Tarjeta del empleador ────────────────────────────────────────────────────

class _PublisherCard extends StatelessWidget {
  final dynamic job;
  const _PublisherCard({required this.job});

  @override
  Widget build(BuildContext context) {
    final initial = job.publisherName.isNotEmpty
        ? job.publisherName[0].toUpperCase()
        : 'U';
    return Row(
      children: [
        CircleAvatar(
          radius: 26,
          backgroundColor: AppColors.primaryLight,
          child: Text(
            initial,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    job.publisherName,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(
                    Icons.verified_rounded,
                    color: AppColors.primary,
                    size: 16,
                  ),
                ],
              ),
              const SizedBox(height: 3),
              if (job.publisherReviews != null && job.publisherReviews! > 0)
                Row(
                  children: [
                    const Icon(
                      Icons.star_rounded,
                      size: 14,
                      color: AppColors.star,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      '${(job.publisherRating ?? 5.0).toStringAsFixed(1)} · ${job.publisherReviews} reseñas',
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                )
              else
                const Text(
                  'Publicador nuevo · Sin reseñas aún',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 11.5,
                    color: AppColors.textHint,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Recomendaciones de seguridad ─────────────────────────────────────────────

class _SecurityTips extends StatelessWidget {
  const _SecurityTips();

  static const _tips = [
    'Coordina en persona en un lugar público la primera vez.',
    'No realices pagos por adelantado fuera de la plataforma.',
    'Solicita que el trabajador tenga identificación.',
    'Usa el chat de LaboraYa para todas las comunicaciones.',
    'Deja una reseña después de completar el trabajo.',
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: _tips.map((tip) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: AppColors.successLight,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: AppColors.success,
                  size: 13,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  tip,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

// ─── Widgets auxiliares ───────────────────────────────────────────────────────

class _Chip extends StatelessWidget {
  final String label;
  final Color color;
  const _Chip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

class _MetaItem extends StatelessWidget {
  final IconData icon;
  final String text;
  const _MetaItem({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppColors.textHint),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.textHint),
          const SizedBox(width: 10),
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.end,
          ),
        ],
      ),
    );
  }
}

class _BackButton extends StatelessWidget {
  final VoidCallback onBack;
  const _BackButton({required this.onBack});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onBack,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.4),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.arrow_back_rounded,
          color: Colors.white,
          size: 18,
        ),
      ),
    );
  }
}

class _IconCircle extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _IconCircle({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.4),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color, size: 18),
      ),
    );
  }
}
