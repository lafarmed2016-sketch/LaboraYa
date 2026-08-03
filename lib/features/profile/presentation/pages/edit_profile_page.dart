import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:laboraya_app/core/constants/api_constants.dart';
import 'package:laboraya_app/core/constants/app_colors.dart';
import 'package:laboraya_app/core/network/api_client.dart';
import 'package:laboraya_app/core/services/image_picker_service.dart';
import 'package:laboraya_app/core/storage/secure_storage.dart';
import 'package:laboraya_app/core/widgets/app_ui_components.dart';
import 'package:laboraya_app/features/profile/presentation/providers/profile_provider.dart';

class EditProfilePage extends ConsumerStatefulWidget {
  const EditProfilePage({super.key});

  @override
  ConsumerState<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends ConsumerState<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _lastNameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _cityController;
  late final TextEditingController _descriptionController;

  bool _initialized = false;
  File? _avatarFile;
  bool _isLoading = false;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _lastNameController = TextEditingController();
    _phoneController = TextEditingController();
    _cityController = TextEditingController();
    _descriptionController = TextEditingController();

    _nameController.addListener(_markChanged);
    _lastNameController.addListener(_markChanged);
    _phoneController.addListener(_markChanged);
    _cityController.addListener(_markChanged);
    _descriptionController.addListener(_markChanged);
  }

  // Pre-llena los campos la primera vez que llegan los datos del perfil
  // sin disparar _hasChanges
  void _initFields(UserProfile profile) {
    if (_initialized) return;
    _initialized = true;

    // Remover listeners temporalmente para no marcar como modificado
    _nameController.removeListener(_markChanged);
    _lastNameController.removeListener(_markChanged);
    _phoneController.removeListener(_markChanged);
    _cityController.removeListener(_markChanged);
    _descriptionController.removeListener(_markChanged);

    _nameController.text        = profile.firstName;
    _lastNameController.text    = profile.lastName;
    _phoneController.text       = profile.phone ?? '';
    _cityController.text        = profile.city ?? '';
    _descriptionController.text = profile.bio ?? '';

    // Volver a agregar listeners después de pre-llenar
    _nameController.addListener(_markChanged);
    _lastNameController.addListener(_markChanged);
    _phoneController.addListener(_markChanged);
    _cityController.addListener(_markChanged);
    _descriptionController.addListener(_markChanged);
  }

  void _markChanged() {
    if (!_hasChanges) setState(() => _hasChanges = true);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _cityController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _changeAvatar() async {
    final file = await ImagePickerService.pickSingleImage(context);
    if (file != null) {
      setState(() {
        _avatarFile = file;
        _hasChanges = true;
      });
    }
  }

  Future<bool> _onWillPop() async {
    if (!_hasChanges) return true;

    final result = await showModalBottomSheet<bool>(
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
            // Handle
            Container(
              width: 36, height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Icon(
              Icons.edit_off_rounded,
              size: 40,
              color: AppColors.textHint,
            ),
            const SizedBox(height: 12),
            const Text(
              '¿Descartar cambios?',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Tienes cambios sin guardar en tu perfil.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx, false),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Seguir editando',
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
              height: 52,
              child: TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: TextButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: const BorderSide(color: AppColors.border),
                  ),
                ),
                child: const Text(
                  'Descartar cambios',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );

    return result ?? false;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final api = ref.read(apiClientProvider);
      final storage = ref.read(secureStorageProvider);

      final dataMap = {
        'Nombres': _nameController.text.trim(),
        'Apellidos': _lastNameController.text.trim(),
        'Telefono': _phoneController.text.trim(),
        'Distrito': _cityController.text.trim(),
        'Descripcion': _descriptionController.text.trim(),
        'PrecioHora': 0,
        'firstName': _nameController.text.trim(),
        'lastName': _lastNameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'city': _cityController.text.trim(),
        'bio': _descriptionController.text.trim(),
      };

      if (_avatarFile != null) {
        await storage.saveLocalAvatarPath(_avatarFile!.path);
        try {
          final bytes = await _avatarFile!.readAsBytes();
          final base64Image = base64Encode(bytes);
          dataMap['ImagenPerfilUrl'] = 'data:image/jpeg;base64,$base64Image';
        } catch (e) {
          debugPrint('Error encoding avatar to base64: $e');
        }
      }

      await api.put(ApiConstants.userProfile, data: dataMap);

      ref.invalidate(profileProvider);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Perfil actualizado correctamente'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
      context.pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al actualizar perfil: ${e.toString()}'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(profileProvider);
    final profile = profileAsync.value;

    // Pre-llenar campos cuando los datos llegan del servidor
    if (profile != null) _initFields(profile);
    return PopScope(
      canPop: !_hasChanges,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final shouldPop = await _onWillPop();
        if (shouldPop && context.mounted) {
          context.pop();
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border),
              ),
              child: const Icon(
                Icons.arrow_back_rounded,
                color: AppColors.textPrimary,
                size: 18,
              ),
            ),
            onPressed: () async {
              if (await _onWillPop()) {
                if (context.mounted) context.pop();
              }
            },
          ),
          title: const Text(
            'Editar Perfil',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar Picker
                Center(
                  child: GestureDetector(
                    onTap: _changeAvatar,
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 46,
                          backgroundColor: AppColors.primaryLight,
                          backgroundImage: _avatarFile != null
                              ? FileImage(_avatarFile!)
                              : (profile?.avatar != null && profile!.avatar.isNotEmpty
                                  ? (profile.avatar.startsWith('/') || !profile.avatar.startsWith('http')
                                      ? FileImage(File(profile.avatar)) as ImageProvider
                                      : NetworkImage(profile.avatar) as ImageProvider)
                                  : null),
                          child: _avatarFile == null && profile?.avatar == null
                              ? const Icon(
                                  Icons.person_rounded,
                                  size: 46,
                                  color: AppColors.primary,
                                )
                              : null,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.camera_alt_rounded,
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

                AppCard(
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _nameController,
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 14,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Nombres',
                          prefixIcon: Icon(
                            Icons.person_outline_rounded,
                            color: AppColors.primary,
                          ),
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) => v == null || v.trim().isEmpty
                            ? 'Ingresa tus nombres'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _lastNameController,
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 14,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Apellidos',
                          prefixIcon: Icon(
                            Icons.person_outline_rounded,
                            color: AppColors.primary,
                          ),
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) => v == null || v.trim().isEmpty
                            ? 'Ingresa tus apellidos'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 14,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Teléfono',
                          prefixIcon: Icon(
                            Icons.phone_outlined,
                            color: AppColors.primary,
                          ),
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _cityController,
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 14,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Ubicación / Ciudad',
                          prefixIcon: Icon(
                            Icons.location_city_rounded,
                            color: AppColors.primary,
                          ),
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _descriptionController,
                        maxLines: 3,
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 14,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Biografía / Descripción profesional',
                          alignLabelWithHint: true,
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                AppPrimaryButton(
                  label: 'Guardar cambios',
                  isLoading: _isLoading,
                  onPressed: _save,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
