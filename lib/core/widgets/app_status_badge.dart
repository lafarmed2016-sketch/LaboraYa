import 'package:flutter/material.dart';
import 'package:laboraya_app/core/constants/app_colors.dart';

enum BadgeType { success, warning, error, info, urgent, neutral, primary }

class AppStatusBadge extends StatelessWidget {
  final String label;
  final BadgeType type;
  final IconData? icon;
  final bool compact;

  const AppStatusBadge({
    super.key,
    required this.label,
    this.type = BadgeType.neutral,
    this.icon,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (type) {
      BadgeType.success => (AppColors.successLight, AppColors.success),
      BadgeType.warning => (AppColors.warningLight, AppColors.warning),
      BadgeType.error => (AppColors.errorLight, AppColors.error),
      BadgeType.info => (AppColors.infoLight, AppColors.info),
      BadgeType.urgent => (AppColors.urgentLight, AppColors.urgent),
      BadgeType.primary => (AppColors.primaryLight, AppColors.primary),
      BadgeType.neutral => (const Color(0xFFF1F5F9), AppColors.textSecondary),
    };

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 3 : 4,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 11, color: fg),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: compact ? 10 : 11,
              fontWeight: FontWeight.w600,
              color: fg,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

/// Converts ApplicationStatus string to badge
class AppApplicationBadge extends StatelessWidget {
  final String status;
  const AppApplicationBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, type) = switch (status) {
      'SENT' => ('Enviada', BadgeType.info),
      'VIEWED' => ('Vista', BadgeType.primary),
      'PRESELECTED' => ('Preseleccionada', BadgeType.warning),
      'ACCEPTED' => ('Aceptada', BadgeType.success),
      'REJECTED' => ('Rechazada', BadgeType.error),
      'WITHDRAWN' => ('Retirada', BadgeType.neutral),
      'CANCELLED' => ('Cancelada', BadgeType.neutral),
      _ => (status, BadgeType.neutral),
    };
    return AppStatusBadge(label: label, type: type);
  }
}

/// Converts ContractStatus string to badge
class AppContractBadge extends StatelessWidget {
  final String status;
  const AppContractBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, type) = switch (status) {
      'PENDING' => ('Pendiente', BadgeType.warning),
      'ACCEPTED' => ('Aceptado', BadgeType.primary),
      'CONFIRMED' => ('Confirmado', BadgeType.info),
      'IN_PROGRESS' => ('En progreso', BadgeType.primary),
      'PENDING_CONFIRMATION' => ('Por confirmar', BadgeType.warning),
      'COMPLETED' => ('Completado', BadgeType.success),
      'CANCELLED' => ('Cancelado', BadgeType.neutral),
      'IN_DISPUTE' => ('En disputa', BadgeType.error),
      _ => (status, BadgeType.neutral),
    };
    return AppStatusBadge(label: label, type: type);
  }
}
