import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:laboraya_app/core/constants/app_colors.dart';
import 'package:laboraya_app/core/services/auth_service.dart';
import 'package:laboraya_app/features/profile/presentation/providers/profile_provider.dart';

// Fondo azul pastel igual al mockup
const _kBgTop    = Color(0xFFE8F0FE);
const _kBgBottom = Color(0xFFF0F4FF);
const _kBlob     = Color(0xFFBDD2FB);
const _kNameColor = Color(0xFF1A237E);
const _kSubColor  = Color(0xFF5C6BC0);

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {

  void _showLogoutDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 36, height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(color: AppColors.border,
                    borderRadius: BorderRadius.circular(2))),
            const Icon(Icons.logout_rounded, size: 40, color: AppColors.error),
            const SizedBox(height: 12),
            const Text('¿Cerrar sesión?', style: TextStyle(
                fontFamily: 'Poppins', fontSize: 18,
                fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            const SizedBox(height: 8),
            const Text('¿Seguro que deseas salir de tu cuenta?',
                textAlign: TextAlign.center,
                style: TextStyle(fontFamily: 'Poppins', fontSize: 14,
                    color: AppColors.textSecondary)),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity, height: 52,
              child: ElevatedButton(
                onPressed: () async {
                  Navigator.pop(ctx);
                  await ref.read(authServiceProvider).logout();
                  if (mounted) context.go('/welcome');
                },
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.error, elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14))),
                child: const Text('Cerrar sesión', style: TextStyle(
                    fontFamily: 'Poppins', fontWeight: FontWeight.w700,
                    fontSize: 15, color: Colors.white)),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity, height: 52,
              child: TextButton(
                onPressed: () => Navigator.pop(ctx),
                style: TextButton.styleFrom(shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: const BorderSide(color: AppColors.border))),
                child: const Text('Cancelar', style: TextStyle(
                    fontFamily: 'Poppins', fontWeight: FontWeight.w600,
                    fontSize: 15, color: AppColors.textSecondary)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(profileProvider);
    return Scaffold(
      backgroundColor: _kBgBottom,
      body: profileAsync.when(
        data: (p) => _buildBody(context, p),
        loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primary)),
        error: (_, __) => _buildBody(context, null),
      ),
    );
  }

  Widget _buildBody(BuildContext context, UserProfile? profile) {
    final name    = profile?.fullName ?? 'Usuario';
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'U';
    final city    = profile?.city ?? '';

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── HEADER — fondo azul pastel con blobs ──────────────
          Stack(
            clipBehavior: Clip.none,
            children: [
              // Fondo degradado
              Container(
                height: 340,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [_kBgTop, _kBgBottom],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
              // Blob decorativo grande (arriba izquierda)
              Positioned(
                top: -40, left: -60,
                child: Container(
                  width: 220, height: 220,
                  decoration: BoxDecoration(
                      color: _kBlob.withValues(alpha: 0.45),
                      shape: BoxShape.circle),
                ),
              ),
              // Blob pequeño (derecha)
              Positioned(
                top: 60, right: -30,
                child: Container(
                  width: 130, height: 130,
                  decoration: BoxDecoration(
                      color: _kBlob.withValues(alpha: 0.30),
                      shape: BoxShape.circle),
                ),
              ),

              // Contenido del header
              SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                  child: Column(
                    children: [
                      // Fila título + settings
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Mi perfil', style: TextStyle(
                              fontFamily: 'Poppins', fontSize: 22,
                              fontWeight: FontWeight.w800, color: _kNameColor)),
                          GestureDetector(
                            onTap: () => context.push('/settings'),
                            child: Container(
                              width: 42, height: 42,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.08),
                                    blurRadius: 8, offset: const Offset(0, 2))],
                              ),
                              child: const Icon(Icons.settings_outlined,
                                  color: _kSubColor, size: 20),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Avatar
                      Container(
                        width: 100, height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.primary,
                          border: Border.all(color: Colors.white, width: 4),
                          boxShadow: [BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.35),
                              blurRadius: 20, offset: const Offset(0, 6))],
                        ),
                        child: ClipOval(
                          child: _buildAvatar(profile, initial),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Nombre
                      Text(name, style: const TextStyle(
                          fontFamily: 'Poppins', fontSize: 22,
                          fontWeight: FontWeight.w800, color: _kNameColor),
                          textAlign: TextAlign.center),
                      const SizedBox(height: 6),

                      // Ciudad
                      if (city.isNotEmpty)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.location_on_rounded,
                                size: 14, color: _kSubColor),
                            const SizedBox(width: 4),
                            Text(city, style: const TextStyle(
                                fontFamily: 'Poppins', fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: _kSubColor)),
                          ],
                        ),
                      const SizedBox(height: 20),

                      // Botón Editar
                      SizedBox(
                        width: double.infinity, height: 52,
                        child: ElevatedButton.icon(
                          onPressed: () => context.push('/edit-profile'),
                          icon: const Icon(Icons.edit_rounded,
                              size: 18, color: Colors.white),
                          label: const Text('Editar mi perfil',
                              style: TextStyle(fontFamily: 'Poppins',
                                  fontSize: 15, fontWeight: FontWeight.w700,
                                  color: Colors.white)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // ── SECCIÓN MIS ACTIVIDADES ──────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _SectionLabel('MIS ACTIVIDADES'),
                const SizedBox(height: 10),
                _ActivityTile(
                  icon: Icons.work_outline_rounded,
                  title: 'Mis trabajos realizados',
                  subtitle: 'Historial de labores completadas',
                  onTap: () => context.push('/my-jobs'),
                ),
                _ActivityTile(
                  icon: Icons.assignment_turned_in_outlined,
                  title: 'Mis postulaciones',
                  subtitle: 'Estado de solicitudes enviadas',
                  onTap: () => context.push('/my-applications'),
                ),
                _ActivityTile(
                  icon: Icons.post_add_rounded,
                  title: 'Mis publicaciones',
                  subtitle: 'Gestionar ofertas de empleo',
                  onTap: () => context.push('/my-jobs'),
                ),
                _ActivityTile(
                  icon: Icons.people_outline_rounded,
                  title: 'Postulaciones recibidas',
                  subtitle: 'Candidatos interesados en tus ofertas',
                  onTap: () => context.push('/received-applications'),
                ),
                _ActivityTile(
                  icon: Icons.bookmark_border_rounded,
                  title: 'Favoritos',
                  subtitle: 'Trabajos guardados',
                  onTap: () => context.push('/favorites'),
                ),

                const SizedBox(height: 24),
                const _SectionLabel('CUENTA'),
                const SizedBox(height: 10),
                _ActivityTile(
                  icon: Icons.notifications_none_rounded,
                  title: 'Notificaciones',
                  subtitle: 'Ajustes de alertas y avisos',
                  onTap: () => context.push('/notifications'),
                ),
                _ActivityTile(
                  icon: Icons.lock_outline_rounded,
                  title: 'Cambiar contraseña',
                  subtitle: 'Actualiza tu contraseña de acceso',
                  onTap: () => context.push('/change-password'),
                ),
                _ActivityTile(
                  icon: Icons.description_outlined,
                  title: 'Términos y condiciones',
                  subtitle: 'Políticas de servicio',
                  onTap: () => context.push('/terms'),
                ),
                _ActivityTile(
                  icon: Icons.shield_outlined,
                  title: 'Política de privacidad',
                  subtitle: 'Protección de datos personales',
                  onTap: () => context.push('/privacy'),
                ),

                const SizedBox(height: 24),

                // Cerrar sesión
                GestureDetector(
                  onTap: _showLogoutDialog,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        vertical: 16, horizontal: 20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 8, offset: const Offset(0, 2))],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40, height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.errorLight,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.logout_rounded,
                              color: AppColors.error, size: 20),
                        ),
                        const SizedBox(width: 14),
                        const Text('Cerrar sesión', style: TextStyle(
                            fontFamily: 'Poppins', fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.error)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(UserProfile? profile, String initial) {
    if (profile?.avatar != null) {
      final av = profile!.avatar!;
      if (av.startsWith('data:image')) {
        return Image.memory(base64Decode(av.split(',').last),
            fit: BoxFit.cover, width: 100, height: 100);
      } else if (av.startsWith('/') || !av.startsWith('http')) {
        return Image.file(File(av),
            fit: BoxFit.cover, width: 100, height: 100);
      } else {
        return Image.network(av,
            fit: BoxFit.cover, width: 100, height: 100);
      }
    }
    return Center(
      child: Text(initial, style: const TextStyle(
          fontFamily: 'Poppins', fontSize: 36,
          fontWeight: FontWeight.w800, color: Colors.white)),
    );
  }
}

// ─── Label de sección ─────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) => Text(text,
      style: const TextStyle(
          fontFamily: 'Poppins', fontSize: 11,
          fontWeight: FontWeight.w700, color: _kSubColor,
          letterSpacing: 1.2));
}

// ─── Fila de actividad ────────────────────────────────────────────────────────

class _ActivityTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ActivityTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
        child: Row(
          children: [
            Container(
              width: 42, height: 42,
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(
                      fontFamily: 'Poppins', fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: const TextStyle(
                      fontFamily: 'Poppins', fontSize: 12,
                      color: AppColors.textSecondary)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                color: AppColors.textHint, size: 20),
          ],
        ),
      ),
    );
  }
}
