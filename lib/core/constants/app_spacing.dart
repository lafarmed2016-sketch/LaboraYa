import 'package:flutter/material.dart';

/// Escala de espaciado LaboraYa: 4 · 8 · 12 · 16 · 20 · 24 · 32 · 40 · 48
class AppSpacing {
  // ── Escala base ───────────────────────────────────────────────
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0; // añadido
  static const double base = 16.0;
  static const double lg = 20.0; // añadido
  static const double xl = 24.0;
  static const double xl2 = 32.0;
  static const double xl3 = 40.0; // añadido
  static const double xxl = 48.0;

  // Alias de compatibilidad con código existente
  // (app_spacing antiguo usaba md=16, lg=24, xl=32)
  // Se mantienen para no romper referencias previas.
  static const double spacingMd = base;
  static const double spacingLg = xl;
  static const double spacingXl = xl2;

  // ── EdgeInsets rápidos ────────────────────────────────────────
  static const EdgeInsets paddingXs = EdgeInsets.all(xs);
  static const EdgeInsets paddingSm = EdgeInsets.all(sm);
  static const EdgeInsets paddingMd = EdgeInsets.all(base);
  static const EdgeInsets paddingLg = EdgeInsets.all(xl);
  static const EdgeInsets paddingXl = EdgeInsets.all(xl2);

  static const EdgeInsets paddingHorizontalMd = EdgeInsets.symmetric(
    horizontal: base,
  );
  static const EdgeInsets paddingHorizontalLg = EdgeInsets.symmetric(
    horizontal: xl,
  );

  static const EdgeInsets paddingVerticalSm = EdgeInsets.symmetric(
    vertical: sm,
  );
  static const EdgeInsets paddingVerticalMd = EdgeInsets.symmetric(
    vertical: base,
  );

  // ── Tamaños de iconos ─────────────────────────────────────────
  static const double iconSm = 16.0;
  static const double iconMd = 24.0;
  static const double iconLg = 32.0;
  static const double iconXl = 48.0;

  // ── Tamaños de avatar ─────────────────────────────────────────
  static const double avatarSm = 32.0;
  static const double avatarMd = 48.0;
  static const double avatarLg = 64.0;
  static const double avatarXl = 96.0;

  // ── Radios (alias — ver AppRadius para la fuente canónica) ────
  static const double radiusSm = 8.0;
  static const double radiusMd = 12.0;
  static const double radiusLg = 16.0;
  static const double radiusXl = 24.0;
  static const double radiusFull = 100.0;

  static final BorderRadius borderRadiusSm = BorderRadius.circular(radiusSm);
  static final BorderRadius borderRadiusMd = BorderRadius.circular(radiusMd);
  static final BorderRadius borderRadiusLg = BorderRadius.circular(radiusLg);
  static final BorderRadius borderRadiusXl = BorderRadius.circular(radiusXl);
  static final BorderRadius borderRadiusFull = BorderRadius.circular(
    radiusFull,
  );
}
