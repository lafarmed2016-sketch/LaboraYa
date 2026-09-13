import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class AppCachedNetworkImage extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final Widget Function(BuildContext, String)? placeholder;
  final Widget Function(BuildContext, String, dynamic)? errorWidget;
  final Color? fallbackCategoryColor;

  static const String baseUrl = 'https://aplicacioneslafarmed.com:9191';

  const AppCachedNetworkImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.placeholder,
    this.errorWidget,
    this.fallbackCategoryColor,
  });

  static String formatUrl(String rawPath) {
    if (rawPath.isEmpty) return '';
    if (rawPath.startsWith('http://') || rawPath.startsWith('https://')) {
      return rawPath;
    }
    String cleaned = rawPath.startsWith('/') ? rawPath : '/$rawPath';
    return '$baseUrl$cleaned';
  }

  @override
  Widget build(BuildContext context) {
    final formattedUrl = formatUrl(imageUrl);

    Widget imageContent;

    // Si es una ruta local de archivo en el celular (ej. recién tomada con la cámara)
    if (!formattedUrl.startsWith('http')) {
      final file = File(imageUrl);
      if (file.existsSync()) {
        imageContent = Image.file(
          file,
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (_, __, ___) => _buildFallback(),
        );
      } else {
        imageContent = _buildFallback();
      }
    } else {
      // Usar CachedNetworkImage con soporte offline / disco
      imageContent = CachedNetworkImage(
        imageUrl: formattedUrl,
        width: width,
        height: height,
        fit: fit,
        memCacheWidth: width != null && width! > 0 ? (width! * 2).toInt() : null,
        memCacheHeight: height != null && height! > 0 ? (height! * 2).toInt() : null,
        placeholder: (ctx, url) {
          if (placeholder != null) return placeholder!(ctx, url);
          return Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: Container(
              width: width,
              height: height,
              color: Colors.white,
            ),
          );
        },
        errorWidget: (ctx, url, error) {
          if (errorWidget != null) return errorWidget!(ctx, url, error);
          return _buildFallback();
        },
      );
    }

    if (borderRadius != null) {
      return ClipRRect(
        borderRadius: borderRadius!,
        child: imageContent,
      );
    }

    return imageContent;
  }

  Widget _buildFallback() {
    final catColor = fallbackCategoryColor ?? const Color(0xFF3B82F6);
    return Container(
      width: width,
      height: height,
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
          Icons.work_outline_rounded,
          size: (width != null && width! < 100) ? 28 : 42,
          color: catColor,
        ),
      ),
    );
  }
}
