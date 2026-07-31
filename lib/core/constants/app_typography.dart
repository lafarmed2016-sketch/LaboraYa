import 'package:flutter/material.dart';
import 'package:laboraya_app/core/constants/app_colors.dart';

/// Tipografía global de LaboraYa
/// Fuente: Poppins — Regular 400 · Medium 500 · SemiBold 600 · Bold 700
class AppTypography {
  static const String _font = 'Poppins';

  // ── Escala de tamaños ─────────────────────────────────────────
  // Display   32  Bold 700
  // Título    26  Bold 700
  // Pantalla  22  SemiBold 600
  // Card      16  SemiBold 600
  // Body      14  Regular 400
  // Caption   12  Regular 400
  // Badge     11  SemiBold 600

  static const TextStyle display = TextStyle(
    fontFamily: _font,
    fontSize: 32,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    letterSpacing: -0.5,
    height: 1.15,
  );

  static const TextStyle titleLg = TextStyle(
    fontFamily: _font,
    fontSize: 26,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    letterSpacing: -0.3,
    height: 1.2,
  );

  static const TextStyle titleMd = TextStyle(
    fontFamily: _font,
    fontSize: 22,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.25,
  );

  static const TextStyle titleSm = TextStyle(
    fontFamily: _font,
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.3,
  );

  static const TextStyle cardTitle = TextStyle(
    fontFamily: _font,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.3,
  );

  static const TextStyle bodyLg = TextStyle(
    fontFamily: _font,
    fontSize: 15,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
    height: 1.5,
  );

  static const TextStyle body = TextStyle(
    fontFamily: _font,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    height: 1.5,
  );

  static const TextStyle bodyMd = TextStyle(
    fontFamily: _font,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
    height: 1.5,
  );

  static const TextStyle bodySm = TextStyle(
    fontFamily: _font,
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    height: 1.5,
  );

  static const TextStyle caption = TextStyle(
    fontFamily: _font,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    height: 1.4,
  );

  static const TextStyle captionMd = TextStyle(
    fontFamily: _font,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
    height: 1.4,
  );

  static const TextStyle badge = TextStyle(
    fontFamily: _font,
    fontSize: 11,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.2,
    height: 1.3,
  );

  static const TextStyle tiny = TextStyle(
    fontFamily: _font,
    fontSize: 10,
    fontWeight: FontWeight.w500,
    color: AppColors.textHint,
    height: 1.3,
  );

  // ── Variantes sobre blanco (para fondos oscuros) ──────────────
  static const TextStyle displayOnDark = TextStyle(
    fontFamily: _font,
    fontSize: 32,
    fontWeight: FontWeight.w700,
    color: Colors.white,
    letterSpacing: -0.5,
    height: 1.15,
  );

  static const TextStyle titleLgOnDark = TextStyle(
    fontFamily: _font,
    fontSize: 26,
    fontWeight: FontWeight.w700,
    color: Colors.white,
    letterSpacing: -0.3,
    height: 1.2,
  );

  static const TextStyle bodyOnDark = TextStyle(
    fontFamily: _font,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: Colors.white70,
    height: 1.5,
  );

  // ── TextTheme para MaterialApp ────────────────────────────────
  static const TextTheme textTheme = TextTheme(
    displayLarge: display,
    displayMedium: titleLg,
    displaySmall: titleMd,
    headlineLarge: titleMd,
    headlineMedium: titleSm,
    headlineSmall: cardTitle,
    titleLarge: titleSm,
    titleMedium: bodyMd,
    titleSmall: bodySm,
    bodyLarge: bodyLg,
    bodyMedium: body,
    bodySmall: caption,
    labelLarge: bodyMd,
    labelMedium: captionMd,
    labelSmall: badge,
  );
}
