import 'package:flutter/material.dart';

/// Radios de borde LaboraYa (Material Design 3)
class AppRadius {
  // ── Valores ───────────────────────────────────────────────────
  static const double bottomSheet = 28.0; // modales y bottom sheets
  static const double cardLg = 18.0; // tarjetas principales
  static const double cardSm = 14.0; // tarjetas pequeñas
  static const double input = 14.0; // campos de texto
  static const double button = 14.0; // botones
  static const double chip = 20.0; // chips / badges
  static const double dialog = 24.0; // diálogos
  static const double avatar = 100.0; // completamente circular
  static const double sm = 8.0; // uso general pequeño
  static const double md = 12.0; // uso general medio
  static const double full = 100.0;

  // ── BorderRadius listos ───────────────────────────────────────
  static final BorderRadius brBottomSheet = BorderRadius.circular(bottomSheet);
  static final BorderRadius brCardLg = BorderRadius.circular(cardLg);
  static final BorderRadius brCardSm = BorderRadius.circular(cardSm);
  static final BorderRadius brInput = BorderRadius.circular(input);
  static final BorderRadius brButton = BorderRadius.circular(button);
  static final BorderRadius brChip = BorderRadius.circular(chip);
  static final BorderRadius brDialog = BorderRadius.circular(dialog);
  static final BorderRadius brSm = BorderRadius.circular(sm);
  static final BorderRadius brMd = BorderRadius.circular(md);
  static final BorderRadius brFull = BorderRadius.circular(full);

  /// Solo esquinas superiores redondeadas (para bottom sheets)
  static const BorderRadius brTopSheet = BorderRadius.vertical(
    top: Radius.circular(bottomSheet),
  );
}
