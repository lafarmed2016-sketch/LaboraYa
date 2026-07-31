import 'package:flutter/material.dart';
import 'package:laboraya_app/core/constants/app_colors.dart';
import 'package:laboraya_app/core/constants/app_spacing.dart';

class VerificationPage extends StatefulWidget {
  const VerificationPage({super.key});

  @override
  State<VerificationPage> createState() => _VerificationPageState();
}

class _VerificationPageState extends State<VerificationPage> {
  final Map<String, String> _verifications = {
    'email': 'verified',
    'phone': 'verified',
    'identity': 'pending',
    'selfie': 'none',
    'address': 'none',
  };

  int get _completedCount =>
      _verifications.values.where((v) => v == 'verified').length;

  void _simulateVerification(String key) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Verificar'),
        content: Text('¿Deseas enviar la verificación de ${_getLabel(key)}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() => _verifications[key] = 'pending');
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Verificación enviada. Se revisará en 24-48h'),
                  backgroundColor: AppColors.success,
                ),
              );
              // Simular aprobación después de 2 segundos
              Future.delayed(const Duration(seconds: 2), () {
                if (mounted) setState(() => _verifications[key] = 'verified');
              });
            },
            child: const Text('Enviar'),
          ),
        ],
      ),
    );
  }

  String _getLabel(String key) {
    switch (key) {
      case 'email':
        return 'Correo electrónico';
      case 'phone':
        return 'Número de teléfono';
      case 'identity':
        return 'Documento de identidad';
      case 'selfie':
        return 'Selfie de verificación';
      case 'address':
        return 'Dirección';
      default:
        return key;
    }
  }

  IconData _getIcon(String key) {
    switch (key) {
      case 'email':
        return Icons.email_outlined;
      case 'phone':
        return Icons.phone_outlined;
      case 'identity':
        return Icons.badge_outlined;
      case 'selfie':
        return Icons.camera_alt_outlined;
      case 'address':
        return Icons.location_on_outlined;
      default:
        return Icons.check_circle_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text('Verificación'),
      ),
      body: SingleChildScrollView(
        padding: AppSpacing.paddingLg,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Progress
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: AppSpacing.borderRadiusMd,
              ),
              child: Column(
                children: [
                  Text(
                    '$_completedCount de 5',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'verificaciones completadas',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: _completedCount / 5,
                      backgroundColor: AppColors.divider,
                      color: AppColors.primary,
                      minHeight: 6,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Verificaciones',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            ..._verifications.entries.map(
              (e) => _VerificationTile(
                icon: _getIcon(e.key),
                title: _getLabel(e.key),
                status: e.value,
                onVerify: e.value == 'none'
                    ? () => _simulateVerification(e.key)
                    : null,
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.infoLight,
                borderRadius: AppSpacing.borderRadiusMd,
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: AppColors.info, size: 18),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Los usuarios verificados reciben más postulaciones y generan mayor confianza.',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VerificationTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String status;
  final VoidCallback? onVerify;

  const _VerificationTile({
    required this.icon,
    required this.title,
    required this.status,
    this.onVerify,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(
          icon,
          color: status == 'verified' ? AppColors.success : AppColors.textHint,
        ),
        title: Text(
          title,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        trailing: _buildTrailing(),
        onTap: onVerify,
      ),
    );
  }

  Widget _buildTrailing() {
    switch (status) {
      case 'verified':
        return const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle, color: AppColors.success, size: 18),
            SizedBox(width: 4),
            Text(
              'Verificado',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.success,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        );
      case 'pending':
        return const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.warning,
              ),
            ),
            SizedBox(width: 6),
            Text(
              'Pendiente',
              style: TextStyle(fontSize: 12, color: AppColors.warning),
            ),
          ],
        );
      default:
        return const Text(
          'Verificar →',
          style: TextStyle(
            fontSize: 12,
            color: AppColors.primary,
            fontWeight: FontWeight.w500,
          ),
        );
    }
  }
}
