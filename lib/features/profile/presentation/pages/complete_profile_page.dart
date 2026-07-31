import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:laboraya_app/core/constants/api_constants.dart';
import 'package:laboraya_app/core/constants/app_colors.dart';
import 'package:laboraya_app/core/network/api_client.dart';
import 'package:laboraya_app/core/services/image_picker_service.dart';
import 'package:laboraya_app/core/services/location_service.dart';
import 'package:laboraya_app/features/profile/presentation/providers/profile_provider.dart';

// ─── CompleteProfilePage ──────────────────────────────────────────────────────
// Pantalla post-registro para completar datos de confianza:
// teléfono, DNI, foto de perfil, distrito.
// El usuario puede omitirlo y hacerlo después desde su perfil.

class CompleteProfilePage extends ConsumerStatefulWidget {
  const CompleteProfilePage({super.key});

  @override
  ConsumerState<CompleteProfilePage> createState() =>
      _CompleteProfilePageState();
}

class _CompleteProfilePageState extends ConsumerState<CompleteProfilePage> {
  final _formKey    = GlobalKey<FormState>();
  final _phoneCtrl  = TextEditingController();
  final _dniCtrl    = TextEditingController();
  final _districtCtrl = TextEditingController();
  File? _photo;
  bool _isSaving = false;
  bool _gpsLoading = false;

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _dniCtrl.dispose();
    _districtCtrl.dispose();
    super.dispose();
  }

  // Porcentaje de completitud visual
  int get _progress {
    int filled = 0;
    if (_phoneCtrl.text.trim().isNotEmpty) filled++;
    if (_dniCtrl.text.trim().isNotEmpty) filled++;
    if (_districtCtrl.text.trim().isNotEmpty) filled++;
    if (_photo != null) filled++;
    return ((filled / 4) * 100).round();
  }

  Future<void> _pickPhoto() async {
    final file = await ImagePickerService.pickSingleImage(context);
    if (file != null) setState(() => _photo = file);
  }

  Future<void> _getGpsDistrict() async {
    if (_gpsLoading) return;
    setState(() => _gpsLoading = true);
    try {
      final result = await LocationService.getCurrentLocation();
      if (!mounted) return;
      if (result != null) {
        _districtCtrl.text = result.district;
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ubicación detectada: ${result.district}'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _gpsLoading = false);
    }
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    try {
      final apiClient = ref.read(apiClientProvider);
      final payload = {
        'documentoIdentidad': _dniCtrl.text,
        'telefono': _phoneCtrl.text,
        'distrito': _districtCtrl.text,
      };
      
      final res = await apiClient.put(ApiConstants.userProfile, data: payload);
      
      if (!mounted) return;
      setState(() => _isSaving = false);

      if (res.data != null && (res.data['codigoRespuesta'] == '0' || res.data['success'] == true)) {
        ref.invalidate(profileProvider);
        context.go('/');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res.data?['mensaje'] ?? 'Error al guardar el perfil'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error de conexión. Inténtalo de nuevo.'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _skip() => context.go('/');

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _skip();
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Column(
            children: [
              // ── Barra superior ────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Completa tu perfil',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Los perfiles completos generan más confianza',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: _skip,
                      child: const Text(
                        'Omitir',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ── Barra de progreso ─────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Perfil completado al $_progress%',
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        Text(
                          '$_progress%',
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: _progress / 100,
                        backgroundColor: AppColors.border,
                        color: _progress == 100
                            ? AppColors.success
                            : AppColors.primary,
                        minHeight: 6,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 4),

              // ── Contenido scrollable ──────────────────────────────
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [

                        // ── Banner de confianza ───────────────────────
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xFF1453A6),
                                Color(0xFF246BCE),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Row(
                            children: [
                              Icon(
                                Icons.verified_user_rounded,
                                color: Colors.white,
                                size: 28,
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '¿Por qué completar tu perfil?',
                                      style: TextStyle(
                                        fontFamily: 'Poppins',
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                                    SizedBox(height: 3),
                                    Text(
                                      'Los empleadores contratan con más confianza a perfiles verificados con foto y DNI.',
                                      style: TextStyle(
                                        fontFamily: 'Poppins',
                                        fontSize: 11.5,
                                        color: Colors.white70,
                                        height: 1.4,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // ── Foto de perfil ────────────────────────────
                        const _SectionTitle(
                          icon: Icons.camera_alt_outlined,
                          title: 'Foto de perfil',
                          badge: 'Recomendado',
                          badgeColor: AppColors.primary,
                        ),
                        const SizedBox(height: 12),
                        Center(
                          child: GestureDetector(
                            onTap: _pickPhoto,
                            child: Stack(
                              children: [
                                CircleAvatar(
                                  radius: 52,
                                  backgroundColor: AppColors.background,
                                  backgroundImage: _photo != null
                                      ? FileImage(_photo!)
                                      : null,
                                  child: _photo == null
                                      ? const Icon(
                                          Icons.person_outline_rounded,
                                          size: 40,
                                          color: AppColors.textHint,
                                        )
                                      : null,
                                ),
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: Container(
                                    width: 32,
                                    height: 32,
                                    decoration: const BoxDecoration(
                                      color: AppColors.primary,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.add_a_photo_outlined,
                                      size: 16,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // ── Teléfono ──────────────────────────────────
                        const _SectionTitle(
                          icon: Icons.phone_outlined,
                          title: 'Número de teléfono',
                          badge: 'Para contacto',
                          badgeColor: AppColors.success,
                        ),
                        const SizedBox(height: 10),
                        _ProfileField(
                          controller: _phoneCtrl,
                          hint: 'Ej: 987 654 321',
                          keyboardType: TextInputType.phone,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(9),
                          ],
                          textInputAction: TextInputAction.next,
                          onChanged: (_) => setState(() {}),
                          prefixIcon: Icons.phone_outlined,
                        ),
                        const SizedBox(height: 20),

                        // ── DNI ───────────────────────────────────────
                        const _SectionTitle(
                          icon: Icons.badge_outlined,
                          title: 'DNI / Documento de identidad',
                          badge: 'Genera confianza',
                          badgeColor: AppColors.warning,
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.all(10),
                          margin: const EdgeInsets.only(bottom: 10),
                          decoration: BoxDecoration(
                            color: AppColors.warningLight,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Row(
                            children: [
                              Icon(
                                Icons.lock_outline_rounded,
                                size: 14,
                                color: AppColors.warning,
                              ),
                              SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'Tu DNI solo se usa para verificar tu identidad. No se muestra públicamente.',
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 11,
                                    color: AppColors.warning,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        _ProfileField(
                          controller: _dniCtrl,
                          hint: 'Ej: 12345678',
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(8),
                          ],
                          textInputAction: TextInputAction.next,
                          onChanged: (_) => setState(() {}),
                          prefixIcon: Icons.badge_outlined,
                          validator: (v) {
                            if (v != null &&
                                v.isNotEmpty &&
                                v.length != 8) {
                              return 'El DNI debe tener 8 dígitos';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),

                        // ── Distrito ──────────────────────────────────
                        const _SectionTitle(
                          icon: Icons.location_on_outlined,
                          title: 'Distrito / Zona',
                          badge: 'Para trabajos cercanos',
                          badgeColor: AppColors.info,
                        ),
                        const SizedBox(height: 10),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: _ProfileField(
                                controller: _districtCtrl,
                                hint: 'Ej: Miraflores, San Isidro...',
                                keyboardType: TextInputType.text,
                                textInputAction: TextInputAction.done,
                                onChanged: (_) => setState(() {}),
                                prefixIcon: Icons.location_on_outlined,
                              ),
                            ),
                            const SizedBox(width: 10),
                            // ── Botón GPS ──────────────────────────────
                            Tooltip(
                              message: 'Usar mi ubicación GPS',
                              child: InkWell(
                                onTap: _getGpsDistrict,
                                borderRadius: BorderRadius.circular(14),
                                child: Container(
                                  width: 56,
                                  height: 56,
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryLight,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: AppColors.primary
                                          .withValues(alpha: 0.3),
                                    ),
                                  ),
                                  child: _gpsLoading
                                      ? const Padding(
                                          padding: EdgeInsets.all(16),
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: AppColors.primary,
                                          ),
                                        )
                                      : const Icon(
                                          Icons.my_location_rounded,
                                          color: AppColors.primary,
                                          size: 22,
                                        ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),

                        // ── Botón guardar ─────────────────────────────
                        _SaveButton(isSaving: _isSaving, onTap: _save),
                        const SizedBox(height: 12),

                        // ── Omitir ────────────────────────────────────
                        Center(
                          child: TextButton(
                            onPressed: _skip,
                            child: const Text(
                              'Completar después',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 13.5,
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
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
}

// ─── Título de sección con badge ──────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final IconData icon;
  final String title;
  final String badge;
  final Color badgeColor;

  const _SectionTitle({
    required this.icon,
    required this.title,
    required this.badge,
    required this.badgeColor,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 8,
      runSpacing: 4,
      children: [
        Icon(icon, size: 18, color: AppColors.textSecondary),
        Text(
          title,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: badgeColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            badge,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: badgeColor,
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Campo de texto del perfil ────────────────────────────────────────────────

class _ProfileField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final TextInputAction? textInputAction;
  final void Function(String)? onChanged;
  final IconData prefixIcon;
  final String? Function(String?)? validator;

  const _ProfileField({
    required this.controller,
    required this.hint,
    this.keyboardType,
    this.inputFormatters,
    this.textInputAction,
    this.onChanged,
    required this.prefixIcon,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    const border = OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(14)),
      borderSide: BorderSide(color: Color(0xFFDDE1E7), width: 1.2),
    );
    const focusBorder = OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(14)),
      borderSide: BorderSide(color: AppColors.primary, width: 1.8),
    );
    const errorBorder = OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(14)),
      borderSide: BorderSide(color: AppColors.error, width: 1.2),
    );

    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      textInputAction: textInputAction,
      onChanged: onChanged,
      validator: validator,
      style: const TextStyle(
        fontFamily: 'Poppins',
        fontSize: 14,
        color: AppColors.textPrimary,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(
          fontFamily: 'Poppins',
          fontSize: 14,
          color: Color(0xFFB0B5C8),
        ),
        prefixIcon: Icon(prefixIcon, size: 18, color: const Color(0xFFB0B5C8)),
        filled: true,
        fillColor: AppColors.inputBg,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 18,
        ),
        border: border,
        enabledBorder: border,
        focusedBorder: focusBorder,
        errorBorder: errorBorder,
        focusedErrorBorder: errorBorder,
        errorStyle: const TextStyle(
          fontFamily: 'Poppins',
          fontSize: 11,
          color: AppColors.error,
        ),
      ),
    );
  }
}

// ─── Botón Guardar ────────────────────────────────────────────────────────────

class _SaveButton extends StatefulWidget {
  final bool isSaving;
  final VoidCallback onTap;
  const _SaveButton({required this.isSaving, required this.onTap});

  @override
  State<_SaveButton> createState() => _SaveButtonState();
}

class _SaveButtonState extends State<_SaveButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _press;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _press = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 90),
      lowerBound: 0,
      upperBound: 1,
    );
    _scale = Tween<double>(begin: 1.0, end: 0.97).animate(_press);
  }

  @override
  void dispose() {
    _press.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _press.forward(),
      onTapUp: (_) {
        _press.reverse();
        if (!widget.isSaving) widget.onTap();
      },
      onTapCancel: () => _press.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          width: double.infinity,
          height: 56,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(14),
            boxShadow: widget.isSaving
                ? []
                : [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.30),
                      blurRadius: 14,
                      offset: const Offset(0, 5),
                    ),
                  ],
          ),
          child: Center(
            child: widget.isSaving
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  )
                : const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.check_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Guardar y entrar',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
