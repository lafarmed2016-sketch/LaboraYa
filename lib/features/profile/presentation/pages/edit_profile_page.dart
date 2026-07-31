import 'dart:io';
import 'package:dio/dio.dart';
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
  void _initFields(UserProfile profile) {
    if (_initialized) return;
    _initialized = true;
    _nameController.text        = profile.firstName;
    _lastNameController.text    = profile.lastName;
    _phoneController.text       = profile.phone ?? '';
    _cityController.text        = profile.city ?? '';
    _descriptionController.text = profile.bio ?? '';
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

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white,
        title: const Text(
          '¿Descartar cambios?',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        content: const Text(
          'Tienes modificaciones sin guardar en tu perfil.',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'Seguir editando',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
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
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Descartar',
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
        'Ciudad': _cityController.text.trim(),
        'Descripcion': _descriptionController.text.trim(),
        'PrecioHora': 0,
        'firstName': _nameController.text.trim(),
        'lastName': _lastNameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'city': _cityController.text.trim(),
        'bio': _descriptionController.text.trim(),
      };

      bool savedWithMultipart = false;
      if (_avatarFile != null) {
        await storage.saveLocalAvatarPath(_avatarFile!.path);
        try {
          final formData = FormData.fromMap({
            ...dataMap,
            'foto': await MultipartFile.fromFile(_avatarFile!.path, filename: 'avatar.jpg'),
            'avatar': await MultipartFile.fromFile(_avatarFile!.path, filename: 'avatar.jpg'),
            'file': await MultipartFile.fromFile(_avatarFile!.path, filename: 'avatar.jpg'),
          });
          await api.put(ApiConstants.userProfile, data: formData);
          savedWithMultipart = true;
        } catch (e) {
          debugPrint('Error uploading avatar via multipart, fallback/retry...: $e');
        }
      }

      if (!savedWithMultipart) {
        await api.put(ApiConstants.userProfile, data: dataMap);
      }

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
                context.pop();
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
                              : (profile?.avatar != null
                                  ? (profile!.avatar!.startsWith('/') || !profile!.avatar!.startsWith('http')
                                      ? FileImage(File(profile!.avatar!)) as ImageProvider
                                      : NetworkImage(profile!.avatar!) as ImageProvider)
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
