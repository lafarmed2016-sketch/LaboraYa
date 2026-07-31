import 'package:flutter/material.dart';
import 'package:laboraya_app/core/constants/app_colors.dart';

// ─── Enums ──────────────────────────────────────────────────────────────────

enum AppButtonVariant { primary, outline, ghost, danger }

enum AppButtonSize {
  small, // h = 48 (mínimo táctil)
  medium, // h = 52
  large, // h = 56
}

// ─── AppButton (componente base unificado) ──────────────────────────────────

/// Botón reutilizable con soporte para loading, disabled, icono y variantes.
/// Altura mínima táctil: 48 px en todas las variantes.
class AppButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final AppButtonSize size;
  final bool isLoading;
  final IconData? icon;
  final bool iconRight;
  final bool fullWidth;

  const AppButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.size = AppButtonSize.medium,
    this.isLoading = false,
    this.icon,
    this.iconRight = false,
    this.fullWidth = true,
  });

  @override
  Widget build(BuildContext context) {
    final (h, fSize) = switch (size) {
      AppButtonSize.small => (48.0, 13.0),
      AppButtonSize.medium => (52.0, 15.0),
      AppButtonSize.large => (56.0, 16.0),
    };

    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(14),
    );

    final child = _buildChild(fSize);

    Widget btn = switch (variant) {
      AppButtonVariant.primary => ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.45),
          disabledForegroundColor: Colors.white70,
          elevation: 0,
          shadowColor: Colors.transparent,
          minimumSize: Size(0, h),
          shape: shape,
        ),
        child: child,
      ),
      AppButtonVariant.outline => OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          disabledForegroundColor: AppColors.primary.withValues(alpha: 0.4),
          side: BorderSide(
            color: onPressed == null && !isLoading
                ? AppColors.primary.withValues(alpha: 0.35)
                : AppColors.primary,
            width: 1.5,
          ),
          minimumSize: Size(0, h),
          shape: shape,
        ),
        child: child,
      ),
      AppButtonVariant.ghost => TextButton(
        onPressed: isLoading ? null : onPressed,
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          disabledForegroundColor: AppColors.primary.withValues(alpha: 0.4),
          minimumSize: Size(0, h),
          shape: shape,
        ),
        child: child,
      ),
      AppButtonVariant.danger => ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.error,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.error.withValues(alpha: 0.45),
          elevation: 0,
          minimumSize: Size(0, h),
          shape: shape,
        ),
        child: child,
      ),
    };

    return fullWidth ? SizedBox(width: double.infinity, child: btn) : btn;
  }

  Widget _buildChild(double fSize) {
    if (isLoading) {
      return SizedBox(
        width: fSize + 4,
        height: fSize + 4,
        child: CircularProgressIndicator(
          strokeWidth: 2.2,
          color:
              variant == AppButtonVariant.primary ||
                  variant == AppButtonVariant.danger
              ? Colors.white
              : AppColors.primary,
        ),
      );
    }
    if (icon == null) {
      return Text(
        text,
        style: TextStyle(
          fontFamily: 'Poppins',
          fontSize: fSize,
          fontWeight: FontWeight.w600,
        ),
      );
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (!iconRight) ...[
          Icon(icon, size: fSize + 2),
          const SizedBox(width: 8),
        ],
        Text(
          text,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: fSize,
            fontWeight: FontWeight.w600,
          ),
        ),
        if (iconRight) ...[
          const SizedBox(width: 8),
          Icon(icon, size: fSize + 2),
        ],
      ],
    );
  }
}

// ─── Alias semánticos ────────────────────────────────────────────────────────

/// Botón primario — fondo azul LaboraYa, texto blanco.
class AppPrimaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  final AppButtonSize size;

  const AppPrimaryButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
    this.size = AppButtonSize.medium,
  });

  @override
  Widget build(BuildContext context) => AppButton(
    text: text,
    onPressed: onPressed,
    variant: AppButtonVariant.primary,
    size: size,
    isLoading: isLoading,
    icon: icon,
  );
}

/// Botón outlined — borde azul, fondo transparente.
class AppOutlinedButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  final AppButtonSize size;

  const AppOutlinedButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
    this.size = AppButtonSize.medium,
  });

  @override
  Widget build(BuildContext context) => AppButton(
    text: text,
    onPressed: onPressed,
    variant: AppButtonVariant.outline,
    size: size,
    isLoading: isLoading,
    icon: icon,
  );
}

/// Botón que muestra un loader interno mientras [isLoading] es true.
/// Deshabilita automáticamente la interacción durante la carga.
class AppLoadingButton extends StatelessWidget {
  final String text;
  final String? loadingText;
  final VoidCallback? onPressed;
  final bool isLoading;
  final AppButtonVariant variant;
  final AppButtonSize size;

  const AppLoadingButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.loadingText,
    this.isLoading = false,
    this.variant = AppButtonVariant.primary,
    this.size = AppButtonSize.medium,
  });

  @override
  Widget build(BuildContext context) {
    return AppButton(
      text: isLoading && loadingText != null ? loadingText! : text,
      onPressed: isLoading ? null : onPressed,
      variant: variant,
      size: size,
      isLoading: isLoading,
    );
  }
}
