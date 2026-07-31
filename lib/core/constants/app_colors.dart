import 'package:flutter/material.dart';

class AppColors {
  // ── Brand / Light Palette ─────────────────────────────────────
  static const Color primary = Color(0xFF246BCE);
  static const Color primaryDark = Color(0xFF1453A6);
  static const Color navy = Color(0xFF0B1F3A);
  static const Color primaryLight = Color(0xFFEBF3FE);
  static const Color accentBlue = Color(0xFF246BCE);

  // Legado — usados en widgets existentes
  static const Color primaryDarkLegacy = Color(0xFF1453A6);
  static const Color secondary = Color(0xFF64B5F6);
  static const Color secondaryLight = Color(0xFFEBF3FE);
  static const Color accent = Color(0xFF246BCE);

  // ── Background / Surface ─────────────────────────────────────
  static const Color background = Color(0xFFF5F7FB);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color inputBg = Color(0xFFF8FAFC);
  static const Color card = Color(0xFFFFFFFF);

  // ── Border ───────────────────────────────────────────────────
  static const Color border = Color(0xFFE6EAF0);
  static const Color divider = Color(0xFFE6EAF0);

  // ── Text ─────────────────────────────────────────────────────
  static const Color textPrimary = Color(0xFF111827);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textHint = Color(0xFF9CA3AF);
  static const Color textOnPrimary = Color(0xFFFFFFFF);
  static const Color textDark = Color(0xFF111827);

  // ── Semantic ─────────────────────────────────────────────────
  static const Color success = Color(0xFF30B878);
  static const Color successLight = Color(0xFFE6F8F0);
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningLight = Color(0xFFFEF3C7);
  static const Color error = Color(0xFFE5484D);
  static const Color danger = Color(0xFFE5484D); // alias de error
  static const Color errorLight = Color(0xFFFDE8E8);
  static const Color info = Color(0xFF246BCE);
  static const Color infoLight = Color(0xFFEBF3FE);
  static const Color urgent = Color(0xFFF58232);
  static const Color urgentLight = Color(0xFFFFF0E6);

  // ── Extras ───────────────────────────────────────────────────
  static const Color star = Color(0xFFF59E0B);
  static const Color online = Color(0xFF30B878);
  static const Color offline = Color(0xFF9CA3AF);
  static const Color disabled = Color(0xFFD1D5DB);
  static const Color shimmerBase = Color(0xFFE5E7EB);
  static const Color shimmerHighlight = Color(0xFFF3F4F6);
  static const Color overlay = Color(0x80000000);

  // ── Chat Dark Forest Green Palette ────────────────────────────
  static const Color chatBg = Color(0xFF071A17);
  static const Color chatBgSecondary = Color(0xFF0B241F);
  static const Color chatSurface = Color(0xFF103129);
  static const Color chatActiveRow = Color(0xFF164438);
  static const Color chatGreenPrimary = Color(0xFF35C98A);
  static const Color chatStatusGreen = Color(0xFF48E0A3);
  static const Color chatTextPrimary = Color(0xFFF5FFF9);
  static const Color chatTextSecondary = Color(0xFF9CB4AC);
  static const Color chatDivider = Color(0xFF193A32);
  static const Color chatBadge = Color(0xFF35C98A);
  static const Color chatAccentSecondary = Color(0xFFC9FF8F);

  // ── Gradients ────────────────────────────────────────────────
  static const LinearGradient splashGradient = LinearGradient(
    colors: [primaryDark, primary],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient profileHeaderGradient = LinearGradient(
    colors: [primaryDark, primary],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient bannerGradient = LinearGradient(
    colors: [primaryDark, primary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
