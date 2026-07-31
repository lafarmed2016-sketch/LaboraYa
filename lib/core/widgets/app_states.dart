/// Estados visuales reutilizables de LaboraYa.
///
/// Exporta:
///   AppEmptyList       — lista vacía genérica
///   AppNoResults       — sin resultados de búsqueda
///   AppNetworkError    — sin conexión + reintentar
///   AppServerError     — error 5xx del servidor
///   AppNoLocation      — ubicación desactivada
///   AppPermissionDenied— permiso denegado (cámara, ubicación, etc.)
///   AppSessionExpired  — sesión vencida
///   AppRetryButton     — botón reintentar standalone
///   AppPaginationLoader— loader de paginación / carga incremental
library;

import 'package:flutter/material.dart';
import 'package:laboraya_app/core/constants/app_colors.dart';

// ─── Base ────────────────────────────────────────────────────────────────────

class _StateBase extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Widget? extraWidget;

  const _StateBase({
    super.key,
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
    this.extraWidget,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
              child: Icon(icon, size: 32, color: iconColor),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            if (extraWidget != null) ...[
              const SizedBox(height: 12),
              extraWidget!,
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 20),
              SizedBox(
                height: 44,
                child: ElevatedButton(
                  onPressed: onAction,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    actionLabel!,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Widgets públicos ─────────────────────────────────────────────────────────

/// Lista vacía — no hay elementos todavía.
class AppEmptyList extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  const AppEmptyList({
    super.key,
    this.title = 'Aún no hay elementos',
    this.subtitle = 'Cuando tengas actividad, aparecerá aquí.',
    this.icon = Icons.inbox_rounded,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return _StateBase(
      icon: icon,
      iconBg: AppColors.primaryLight,
      iconColor: AppColors.primary,
      title: title,
      subtitle: subtitle,
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }
}

/// Sin resultados de búsqueda.
class AppNoResults extends StatelessWidget {
  final String? query;
  final VoidCallback? onClear;

  const AppNoResults({super.key, this.query, this.onClear});

  @override
  Widget build(BuildContext context) {
    return _StateBase(
      icon: Icons.search_off_rounded,
      iconBg: AppColors.primaryLight,
      iconColor: AppColors.primary,
      title: 'Sin resultados',
      subtitle: query != null && query!.isNotEmpty
          ? 'No encontramos resultados para "$query".\nPrueba con otros términos o ajusta los filtros.'
          : 'Prueba con otros términos o ajusta los filtros.',
      actionLabel: onClear != null ? 'Limpiar búsqueda' : null,
      onAction: onClear,
    );
  }
}

/// Error de red — sin conexión.
class AppNetworkError extends StatelessWidget {
  final VoidCallback? onRetry;

  const AppNetworkError({super.key, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return _StateBase(
      icon: Icons.wifi_off_rounded,
      iconBg: AppColors.error.withValues(alpha: 0.1),
      iconColor: AppColors.error,
      title: 'Sin conexión',
      subtitle: 'Verifica tu conexión a internet e intenta de nuevo.',
      actionLabel: onRetry != null ? 'Reintentar' : null,
      onAction: onRetry,
    );
  }
}

/// Error de servidor (5xx).
class AppServerError extends StatelessWidget {
  final VoidCallback? onRetry;

  const AppServerError({super.key, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return _StateBase(
      icon: Icons.cloud_off_rounded,
      iconBg: AppColors.error.withValues(alpha: 0.1),
      iconColor: AppColors.error,
      title: 'Error del servidor',
      subtitle:
          'Nuestros servidores están teniendo problemas.\nIntenta más tarde.',
      actionLabel: onRetry != null ? 'Reintentar' : null,
      onAction: onRetry,
    );
  }
}

/// Ubicación desactivada.
class AppNoLocation extends StatelessWidget {
  final VoidCallback? onEnable;

  const AppNoLocation({super.key, this.onEnable});

  @override
  Widget build(BuildContext context) {
    return _StateBase(
      icon: Icons.location_off_rounded,
      iconBg: AppColors.warningLight,
      iconColor: AppColors.warning,
      title: 'Ubicación desactivada',
      subtitle:
          'Activa la ubicación para ver trabajos y profesionales cerca de ti.',
      actionLabel: onEnable != null ? 'Activar ubicación' : null,
      onAction: onEnable,
    );
  }
}

/// Permiso denegado.
class AppPermissionDenied extends StatelessWidget {
  final String permissionName;
  final VoidCallback? onSettings;

  const AppPermissionDenied({
    super.key,
    this.permissionName = 'Permiso',
    this.onSettings,
  });

  @override
  Widget build(BuildContext context) {
    return _StateBase(
      icon: Icons.block_rounded,
      iconBg: AppColors.warningLight,
      iconColor: AppColors.warning,
      title: '$permissionName denegado',
      subtitle:
          'Necesitamos acceso para continuar. Ve a Configuración y otorga el permiso.',
      actionLabel: onSettings != null ? 'Ir a configuración' : null,
      onAction: onSettings,
    );
  }
}

/// Sesión vencida.
class AppSessionExpired extends StatelessWidget {
  final VoidCallback? onLogin;

  const AppSessionExpired({super.key, this.onLogin});

  @override
  Widget build(BuildContext context) {
    return _StateBase(
      icon: Icons.lock_clock_rounded,
      iconBg: AppColors.primaryLight,
      iconColor: AppColors.primary,
      title: 'Sesión vencida',
      subtitle:
          'Tu sesión ha expirado. Inicia sesión nuevamente para continuar.',
      actionLabel: onLogin != null ? 'Iniciar sesión' : null,
      onAction: onLogin,
    );
  }
}

// ─── Botón reintentar standalone ─────────────────────────────────────────────

class AppRetryButton extends StatelessWidget {
  final VoidCallback onRetry;
  final String label;

  const AppRetryButton({
    super.key,
    required this.onRetry,
    this.label = 'Reintentar',
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: OutlinedButton.icon(
        onPressed: onRetry,
        icon: const Icon(Icons.refresh_rounded, size: 16),
        label: Text(
          label,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20),
        ),
      ),
    );
  }
}

// ─── Loader de paginación / carga incremental ─────────────────────────────────

class AppPaginationLoader extends StatelessWidget {
  final bool hasMore;
  final bool isLoading;

  const AppPaginationLoader({
    super.key,
    required this.hasMore,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    if (!hasMore && !isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Center(
          child: Text(
            'Has visto todos los resultados',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 12,
              color: AppColors.textHint,
            ),
          ),
        ),
      );
    }
    if (isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: AppColors.primary,
            ),
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }
}
