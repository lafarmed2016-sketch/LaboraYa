import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:laboraya_app/core/constants/app_colors.dart';

class ImagePickerService {
  static final _picker = ImagePicker();

  /// Seleccionar una imagen (cámara o galería)
  static Future<File?> pickSingleImage(BuildContext context) async {
    final source = await _showSourceDialog(context);
    if (source == null) return null;

    final picked = await _picker.pickImage(
      source: source,
      maxWidth: 1200,
      maxHeight: 1200,
      imageQuality: 80,
    );

    if (picked == null) return null;
    return File(picked.path);
  }

  /// Seleccionar múltiples imágenes de la galería
  static Future<List<File>> pickMultipleImages() async {
    final picked = await _picker.pickMultiImage(
      maxWidth: 1200,
      maxHeight: 1200,
      imageQuality: 80,
    );

    return picked.map((xfile) => File(xfile.path)).toList();
  }

  /// Mostrar diálogo para elegir cámara o galería
  static Future<ImageSource?> _showSourceDialog(BuildContext context) async {
    return showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Seleccionar foto',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: AppColors.secondaryLight,
                  child: Icon(Icons.camera_alt, color: AppColors.primary),
                ),
                title: const Text('Cámara'),
                subtitle: const Text('Tomar una foto'),
                onTap: () => Navigator.pop(ctx, ImageSource.camera),
              ),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: AppColors.secondaryLight,
                  child: Icon(Icons.photo_library, color: AppColors.primary),
                ),
                title: const Text('Galería'),
                subtitle: const Text('Elegir de la galería'),
                onTap: () => Navigator.pop(ctx, ImageSource.gallery),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
