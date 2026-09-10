import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:laboraya_app/core/constants/api_constants.dart';
import 'package:laboraya_app/core/constants/app_colors.dart';
import 'package:laboraya_app/core/constants/app_spacing.dart';
import 'package:laboraya_app/core/network/api_client.dart';
import 'package:laboraya_app/core/services/image_picker_service.dart';
import 'package:laboraya_app/core/services/location_service.dart';
import 'package:laboraya_app/core/storage/secure_storage.dart';
import 'package:laboraya_app/features/profile/presentation/providers/profile_provider.dart';

class VerificationPage extends ConsumerStatefulWidget {
  const VerificationPage({super.key});

  @override
  ConsumerState<VerificationPage> createState() => _VerificationPageState();
}

class _VerificationPageState extends ConsumerState<VerificationPage> {
  bool _isUploading = false;

  Future<void> _updateField(String fieldName, String value) async {
    setState(() => _isUploading = true);
    try {
      final apiClient = ref.read(apiClientProvider);
      final res = await apiClient.put(
        ApiConstants.userProfile,
        data: {fieldName: value},
      );

      if (!mounted) return;
      if (res.data != null &&
          (res.data['codigoRespuesta'] == '0' || res.data['success'] == true)) {
        ref.invalidate(profileProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('¡Datos de verificación actualizados correctamente!'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res.data?['mensaje'] ?? 'Error al actualizar datos'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al conectar con el servidor: $e'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Future<void> _promptDniDialog(String? currentDni) async {
    final ctrl = TextEditingController(text: currentDni ?? '');
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Verificar Documento de Identidad'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ingresa tu DNI o Documento de Identidad (mínimo 8 dígitos):',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl,
              keyboardType: TextInputType.number,
              maxLength: 12,
              decoration: const InputDecoration(
                labelText: 'Número de DNI',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.badge_outlined),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              final val = ctrl.text.trim();
              if (val.length < 8) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('El DNI debe contener al menos 8 dígitos.'),
                    backgroundColor: AppColors.error,
                  ),
                );
                return;
              }
              Navigator.pop(ctx);
              _updateField('documentoIdentidad', val);
            },
            child: const Text('Guardar y Verificar'),
          ),
        ],
      ),
    );
  }

  Future<void> _promptPhoneDialog(String? currentPhone) async {
    final ctrl = TextEditingController(text: currentPhone ?? '');
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Verificar Número de Teléfono'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ingresa tu número de teléfono de contacto:',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl,
              keyboardType: TextInputType.phone,
              maxLength: 15,
              decoration: const InputDecoration(
                labelText: 'Teléfono',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.phone_outlined),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              final val = ctrl.text.trim();
              if (val.length < 6) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Ingresa un número de teléfono válido.'),
                    backgroundColor: AppColors.error,
                  ),
                );
                return;
              }
              Navigator.pop(ctx);
              _updateField('telefono', val);
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  Future<void> _uploadSelfiePhoto() async {
    final file = await ImagePickerService.pickSingleImage(context);
    if (file == null) return;

    setState(() => _isUploading = true);
    try {
      final bytes = await file.readAsBytes();
      final base64Image = base64Encode(bytes);
      final payloadUrl = 'data:image/jpeg;base64,$base64Image';

      final storage = ref.read(secureStorageProvider);
      await storage.saveLocalAvatarPath(file.path);

      await _updateField('ImagenPerfilUrl', payloadUrl);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al procesar la imagen: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Future<void> _promptAddressDialog(String? currentCity) async {
    final ctrl = TextEditingController(text: currentCity ?? '');
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Verificar Dirección / Distrito'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ingresa tu distrito o presiona GPS para detectarlo automáticamente:',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl,
              decoration: InputDecoration(
                labelText: 'Distrito / Ciudad',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.location_on_outlined),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.my_location_rounded, color: AppColors.primary),
                  onPressed: () async {
                    final result = await LocationService.getCurrentLocation();
                    if (result != null) {
                      ctrl.text = result.district;
                    }
                  },
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              final val = ctrl.text.trim();
              if (val.isEmpty) return;
              Navigator.pop(ctx);
              _updateField('distrito', val);
            },
            child: const Text('Guardar'),
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
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text('Verificación de Identidad'),
      ),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Text('Error al cargar perfil: $err'),
        ),
        data: (profile) {
          final isEmailVerified = profile?.email != null && profile!.email.isNotEmpty;
          final isPhoneVerified = profile?.phone != null && profile!.phone!.trim().length >= 6;
          final isDniVerified = profile?.dni != null && profile!.dni!.trim().length >= 8;
          final isSelfieVerified = profile?.avatar != null && profile!.avatar!.trim().isNotEmpty;
          final isAddressVerified = profile?.city != null && profile!.city!.trim().isNotEmpty;

          int completedCount = 0;
          if (isEmailVerified) completedCount++;
          if (isPhoneVerified) completedCount++;
          if (isDniVerified) completedCount++;
          if (isSelfieVerified) completedCount++;
          if (isAddressVerified) completedCount++;

          final isFullyVerified = profile?.isVerified == true || completedCount == 5;

          return Stack(
            children: [
              SingleChildScrollView(
                padding: AppSpacing.paddingLg,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Card Estado General
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: AppSpacing.borderRadiusMd,
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x0A000000),
                            blurRadius: 10,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                isFullyVerified
                                    ? Icons.verified_user_rounded
                                    : Icons.shield_outlined,
                                color: isFullyVerified
                                    ? AppColors.success
                                    : AppColors.primary,
                                size: 32,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                isFullyVerified
                                    ? 'Perfil 100% Verificado'
                                    : '$completedCount de 5 Verificaciones',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            isFullyVerified
                                ? 'Tu cuenta cuenta con insignia azul de confianza para contratar y trabajar.'
                                : 'Completar tus verificaciones aumenta tus postulaciones y la confianza de los clientes.',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 14),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: completedCount / 5,
                              backgroundColor: AppColors.divider,
                              color: isFullyVerified ? AppColors.success : AppColors.primary,
                              minHeight: 8,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Requisitos de Verificación',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 12),

                    // 1. Correo Electrónico
                    _VerificationTile(
                      icon: Icons.email_outlined,
                      title: 'Correo electrónico',
                      subtitle: profile?.email ?? 'No registrado',
                      isVerified: isEmailVerified,
                      onVerify: null,
                    ),

                    // 2. Teléfono
                    _VerificationTile(
                      icon: Icons.phone_outlined,
                      title: 'Número de teléfono',
                      subtitle: profile?.phone ?? 'Sin registrar',
                      isVerified: isPhoneVerified,
                      onVerify: () => _promptPhoneDialog(profile?.phone),
                    ),

                    // 3. Documento de Identidad (DNI)
                    _VerificationTile(
                      icon: Icons.badge_outlined,
                      title: 'Documento de Identidad (DNI)',
                      subtitle: profile?.dni != null && profile!.dni!.isNotEmpty
                          ? 'DNI: ${profile.dni}'
                          : 'Requerido para verificación',
                      isVerified: isDniVerified,
                      onVerify: () => _promptDniDialog(profile?.dni),
                    ),

                    // 4. Selfie / Foto de Verificación
                    _VerificationTile(
                      icon: Icons.camera_alt_outlined,
                      title: 'Foto / Selfie de perfil',
                      subtitle: isSelfieVerified
                          ? 'Foto cargada correctamente'
                          : 'Sube tu foto de perfil visible',
                      isVerified: isSelfieVerified,
                      onVerify: () => _uploadSelfiePhoto(),
                    ),

                    // 5. Dirección / Distrito
                    _VerificationTile(
                      icon: Icons.location_on_outlined,
                      title: 'Distrito / Ubicación',
                      subtitle: profile?.city ?? 'Sin definir',
                      isVerified: isAddressVerified,
                      onVerify: () => _promptAddressDialog(profile?.city),
                    ),

                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.infoLight,
                        borderRadius: AppSpacing.borderRadiusMd,
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.info_outline, color: AppColors.info, size: 18),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Tus documentos e información personal están protegidos y solo se utilizan para verificar tu identidad.',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (_isUploading)
                Container(
                  color: Colors.black26,
                  child: const Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _VerificationTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isVerified;
  final VoidCallback? onVerify;

  const _VerificationTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isVerified,
    this.onVerify,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isVerified ? const Color(0xFFDCFCE7) : const Color(0xFFE2E8F0),
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: isVerified ? const Color(0xFFF0FDF4) : const Color(0xFFF1F5F9),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: isVerified ? AppColors.success : AppColors.textHint,
            size: 20,
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 12,
            color: isVerified ? AppColors.success : AppColors.textSecondary,
          ),
        ),
        trailing: isVerified
            ? const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle_rounded, color: AppColors.success, size: 20),
                  SizedBox(width: 4),
                  Text(
                    'Verificado',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.success,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              )
            : TextButton(
                onPressed: onVerify,
                child: const Text(
                  'Completar',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
      ),
    );
  }
}
