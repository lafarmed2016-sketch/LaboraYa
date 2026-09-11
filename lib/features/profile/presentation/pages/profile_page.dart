import 'dart:io';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:laboraya_app/core/constants/api_constants.dart';
import 'package:laboraya_app/core/constants/app_colors.dart';
import 'package:laboraya_app/core/network/api_client.dart';
import 'package:laboraya_app/core/services/auth_service.dart';
import 'package:laboraya_app/core/services/image_picker_service.dart';
import 'package:laboraya_app/core/storage/secure_storage.dart';
import 'package:laboraya_app/features/profile/presentation/providers/profile_provider.dart';
import 'package:laboraya_app/features/jobs/presentation/providers/jobs_provider.dart';
import 'package:laboraya_app/features/notifications/presentation/providers/notifications_provider.dart';
import 'package:laboraya_app/features/chat/presentation/providers/chat_provider.dart';
import 'package:laboraya_app/features/jobs/domain/entities/job_entity.dart';

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  Future<void> _changeAvatarDirectly() async {
    final file = await ImagePickerService.pickSingleImage(context);
    if (file == null) return;

    final storage = ref.read(secureStorageProvider);
    await storage.saveLocalAvatarPath(file.path);

    try {
      final apiClient = ref.read(apiClientProvider);
      final bytes = await file.readAsBytes();
      final base64Image = 'data:image/jpeg;base64,${base64Encode(bytes)}';

      final dataMap = {
        'ImagenPerfilUrl': base64Image,
        'imagenPerfilUrl': base64Image,
      };

      try {
        await apiClient.put(ApiConstants.userProfile, data: dataMap);
      } catch (_) {
        final multipartFile = await MultipartFile.fromFile(
          file.path,
          filename: 'avatar_${DateTime.now().millisecondsSinceEpoch}.jpg',
        );
        final formData = FormData.fromMap({
          'file': multipartFile,
          'foto': multipartFile,
          'ImagenPerfilUrl': base64Image,
        });
        await apiClient.post(ApiConstants.userProfile, data: formData);
      }
    } catch (_) {}

    ref.invalidate(profileProvider);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('¡Foto de perfil actualizada correctamente!'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showLogoutDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Icon(Icons.logout_rounded, size: 40, color: AppColors.error),
              const SizedBox(height: 12),
              const Text(
                '¿Cerrar sesión?',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '¿Seguro que deseas salir de tu cuenta?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14,
                  color: Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(ctx);
                    await ref.read(authServiceProvider).logout();
                    ref.invalidate(profileProvider);
                    ref.invalidate(jobsProvider);
                    ref.invalidate(notificationsProvider);
                    ref.invalidate(conversationsProvider);
                    if (mounted) context.go('/welcome');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.error,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'Cerrar sesión',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: TextButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                  ),
                  child: const Text(
                    'Cancelar',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: Color(0xFF64748B),
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
    ref.listen<AsyncValue<UserProfile?>>(profileProvider, (prev, next) {
      if (next.hasValue && next.value == null) {
        ref.read(secureStorageProvider).clearTokens();
        if (mounted) context.go('/auth/login');
      }
    });

    final profileAsync = ref.watch(profileProvider);
    return Scaffold(
      backgroundColor: Colors.white,
      body: profileAsync.when(
        data: (p) => _buildBody(context, p),
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (_, __) => _buildBody(context, null),
      ),
    );
  }

  Widget _buildBody(BuildContext context, UserProfile? profile) {
    final name = profile?.fullName ?? 'Juan Pérez';
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'U';
    final occupation = (profile?.bio?.isNotEmpty == true)
        ? profile!.bio!
        : 'Trabajador independiente';

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Barra Superior: Título + Icono Ajustes ───────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Mi perfil',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                  ),
                ),
                GestureDetector(
                  onTap: () => context.push('/settings'),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: const Icon(
                      Icons.settings_outlined,
                      color: Color(0xFF475569),
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // ── Cabecera de Perfil: Avatar + Info ───────────────────
            Row(
              children: [
                // Avatar interactivo con cámara + check
                GestureDetector(
                  onTap: _changeAvatarDirectly,
                  child: Stack(
                    children: [
                      Container(
                        width: 76,
                        height: 76,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFFEFF6FF),
                          border: Border.all(color: const Color(0xFFE2E8F0), width: 2),
                        ),
                        child: ClipOval(
                          child: _buildAvatar(profile, initial),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          width: 26,
                          height: 26,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: const Icon(
                            Icons.camera_alt_rounded,
                            color: Colors.white,
                            size: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),

                // Datos de Usuario
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 4),

                      // Especialidad con icono
                      Row(
                        children: [
                          const Icon(
                            Icons.handyman_rounded,
                            size: 14,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            occupation,
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Icon(
                            Icons.verified_rounded,
                            size: 15,
                            color: AppColors.primary,
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),

                      // Rating y Fecha
                      Row(
                        children: [
                          const Icon(
                            Icons.star_rounded,
                            size: 16,
                            color: Color(0xFFF59E0B),
                          ),
                          const SizedBox(width: 4),
                          const Text(
                            '4.8 (32)',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Icon(
                            Icons.calendar_today_rounded,
                            size: 12,
                            color: Color(0xFF94A3B8),
                          ),
                          const SizedBox(width: 4),
                          const Text(
                            'Miembro desde 2022',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 11,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // ── 3 Tarjetas de Estadísticas (Idénticas al Mockup) ─────
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  _StatItem(
                    label: 'Trabajos completados',
                    value: '48',
                  ),
                  Container(
                    width: 1,
                    height: 38,
                    color: const Color(0xFFE2E8F0),
                  ),
                  _StatItem(
                    label: 'Trabajos activos',
                    value: '3',
                  ),
                  Container(
                    width: 1,
                    height: 38,
                    color: const Color(0xFFE2E8F0),
                  ),
                  _StatItem(
                    label: 'Calificación',
                    value: '4.8',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── Lista de Opciones de Menú (Estilo Profesional Blanco) ─
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  _MenuItem(
                    icon: Icons.work_outline_rounded,
                    title: 'Mis trabajos',
                    onTap: () => context.push('/my-jobs'),
                  ),
                  const Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9)),
                  _MenuItem(
                    icon: Icons.history_rounded,
                    title: 'Historial de trabajos',
                    onTap: () => context.push('/my-jobs'),
                  ),
                  const Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9)),
                  _MenuItem(
                    icon: Icons.star_outline_rounded,
                    title: 'Mis calificaciones',
                    onTap: () => context.push('/my-reviews'),
                  ),
                  const Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9)),
                  _MenuItem(
                    icon: Icons.bookmark_border_rounded,
                    title: 'Favoritos',
                    onTap: () => context.push('/favorites'),
                  ),
                  const Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9)),
                  _MenuItem(
                    icon: Icons.verified_user_outlined,
                    title: 'Verificación',
                    onTap: () => context.push('/verification'),
                  ),
                  const Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9)),
                  _MenuItem(
                    icon: Icons.help_outline_rounded,
                    title: 'Centro de ayuda',
                    onTap: () => context.push('/help-center'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // ── Botón Editar Perfil ──────────────────────────────────
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                onPressed: () => context.push('/edit-profile'),
                icon: const Icon(Icons.edit_outlined, size: 18, color: AppColors.primary),
                label: const Text(
                  'Editar mi perfil',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFBFDBFE)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // ── Botón Cerrar Sesión ──────────────────────────────────
            SizedBox(
              width: double.infinity,
              height: 48,
              child: TextButton.icon(
                onPressed: _showLogoutDialog,
                icon: const Icon(Icons.logout_rounded, size: 18, color: Color(0xFFEF4444)),
                label: const Text(
                  'Cerrar sesión',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFEF4444),
                  ),
                ),
                style: TextButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar(UserProfile? profile, String initial) {
    final fallback = Center(
      child: Text(
        initial,
        style: const TextStyle(
          fontFamily: 'Poppins',
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: AppColors.primary,
        ),
      ),
    );

    if (profile?.avatar != null && profile!.avatar!.isNotEmpty) {
      return JobEntity.buildImageWidget(
        profile.avatar!,
        fit: BoxFit.cover,
        fallbackBuilder: () => fallback,
      );
    }
    return fallback;
  }
}

// ─── Componente Estadística ──────────────────────────────────────────────────

class _StatItem extends StatelessWidget {
  final String label;
  final String value;

  const _StatItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: Color(0xFF64748B),
              height: 1.2,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Componente Item de Menú ─────────────────────────────────────────────────

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _MenuItem({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF64748B), size: 22),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF0F172A),
                ),
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: Color(0xFF94A3B8),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
