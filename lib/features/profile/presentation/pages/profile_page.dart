import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:laboraya_app/core/constants/app_colors.dart';
import 'package:laboraya_app/core/services/auth_service.dart';
import 'package:laboraya_app/core/widgets/app_ui_components.dart';
import 'package:laboraya_app/features/profile/presentation/providers/profile_provider.dart';

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  bool _isWorkerTab = true;

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: Colors.white,
        title: const Text(
          'Cerrar sesión',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        content: const Text(
          '¿Seguro que deseas salir de tu cuenta?',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Cancelar',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(authServiceProvider).logout();
              if (context.mounted) {
                context.go('/welcome');
              }
            },
            child: const Text(
              'Cerrar sesión',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(profileProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: profileAsync.when(
        data: (profile) => _buildBody(context, profile),
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (_, __) => _buildBody(context, null),
      ),
    );
  }

  Widget _buildBody(BuildContext context, UserProfile? profile) {
    final name = profile?.fullName ?? 'Usuario';
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'U';
    final city = profile?.city ?? 'Ubicación no especificada';
    final userType = profile?.userType ?? 'BOTH';
    final isWorker = userType == 'WORKER';
    final isEmployer = userType == 'EMPLOYER';
    final isBoth = userType == 'BOTH';

    return SingleChildScrollView(
      child: Column(
        children: [
          // ── Header Premium ──────────────────────────────────────────
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primaryDark, AppColors.primary],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Mi perfil',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        IconButton(
                          icon: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.settings_outlined,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          onPressed: () => context.push('/settings'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Avatar
                    CircleAvatar(
                      radius: 42,
                      backgroundColor: Colors.white24,
                      backgroundImage: profile?.avatar != null
                          ? (profile!.avatar!.startsWith('data:image')
                              ? MemoryImage(base64Decode(profile!.avatar!.split(',').last)) as ImageProvider
                              : (profile!.avatar!.startsWith('/') || !profile.avatar!.startsWith('http')
                                  ? FileImage(File(profile.avatar!)) as ImageProvider
                                  : NetworkImage(profile.avatar!) as ImageProvider))
                          : null,
                      child: profile?.avatar == null
                          ? Text(
                              initial,
                              style: const TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 32,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      name,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 21,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.location_on_rounded,
                          size: 14,
                          color: Colors.white70,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          city,
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 13,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                    if (profile?.isVerified == true) ...[
                      const SizedBox(height: 8),
                      const VerifiedBadge(),
                    ],
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 46,
                      child: ElevatedButton.icon(
                        onPressed: () => context.push('/edit-profile'),
                        icon: const Icon(
                          Icons.edit_rounded,
                          size: 18,
                          color: AppColors.primaryDark,
                        ),
                        label: const Text(
                          'Editar mi perfil',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryDark,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          elevation: 3,
                          shadowColor: Colors.black.withValues(alpha: 0.2),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const AppSectionHeader(title: 'Mis Actividades'),
                AppListTile(
                  icon: Icons.work_outline_rounded,
                  title: 'Mis trabajos realizados',
                  subtitle: 'Historial de labores completadas',
                  onTap: () => context.push('/my-jobs'),
                ),
                AppListTile(
                  icon: Icons.assignment_turned_in_outlined,
                  title: 'Mis postulaciones',
                  subtitle: 'Estado de solicitudes enviadas',
                  onTap: () => context.push('/my-applications'),
                ),
                AppListTile(
                  icon: Icons.post_add_rounded,
                  title: 'Mis publicaciones',
                  subtitle: 'Gestionar ofertas de empleo',
                  onTap: () => context.push('/my-jobs'),
                ),
                AppListTile(
                  icon: Icons.people_outline_rounded,
                  title: 'Postulaciones recibidas',
                  subtitle: 'Revisar candidatos para mis empleos',
                  onTap: () => context.push('/received-applications'),
                ),
                AppListTile(
                  icon: Icons.bookmark_border_rounded,
                  title: 'Favoritos',
                  subtitle: 'Trabajos guardados',
                  onTap: () => context.push('/favorites'),
                ),

                const AppSectionHeader(title: 'Configuración y Cuenta'),
                AppListTile(
                  icon: Icons.notifications_none_rounded,
                  title: 'Notificaciones',
                  subtitle: 'Ajustes de alertas y avisos',
                  onTap: () => context.push('/notifications'),
                ),
                AppListTile(
                  icon: Icons.description_outlined,
                  title: 'Términos y condiciones',
                  subtitle: 'Políticas de servicio',
                  onTap: () => context.push('/terms'),
                ),
                AppListTile(
                  icon: Icons.shield_outlined,
                  title: 'Política de privacidad',
                  subtitle: 'Protección de datos personales',
                  onTap: () => context.push('/privacy'),
                ),

                const SizedBox(height: 16),

                // ── Botón Cerrar Sesión ─────────────────────────────────
                AppDangerButton(
                  label: 'Cerrar sesión',
                  icon: Icons.logout_rounded,
                  onPressed: () => _showLogoutDialog(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
