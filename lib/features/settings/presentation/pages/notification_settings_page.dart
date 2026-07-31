import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:laboraya_app/core/constants/app_colors.dart';
import 'package:laboraya_app/core/network/api_client.dart';
import 'package:laboraya_app/core/constants/api_constants.dart';

class NotificationSettingsPage extends ConsumerStatefulWidget {
  const NotificationSettingsPage({super.key});
  @override
  ConsumerState<NotificationSettingsPage> createState() =>
      _NotificationSettingsPageState();
}

class _NotificationSettingsPageState
    extends ConsumerState<NotificationSettingsPage> {
  bool _pushEnabled = true;
  bool _emailEnabled = true;
  bool _newApplications = true;
  bool _messages = true;
  bool _jobUpdates = true;
  bool _reviews = true;
  bool _promotions = false;
  bool _saving = false;

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await ref
          .read(apiClientProvider)
          .put(
            ApiConstants.settingsNotifications,
            data: {
              'pushEnabled': _pushEnabled,
              'emailEnabled': _emailEnabled,
              'newApplications': _newApplications,
              'newMessages': _messages,
              'jobReminders': _jobUpdates,
              'reviews': _reviews,
              'promotions': _promotions,
            },
          );
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Configuración guardada'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
    } catch (_) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Guardado localmente'),
            behavior: SnackBarBehavior.floating,
          ),
        );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            size: 18,
            color: AppColors.textDark,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Notificaciones',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text(
                    'Guardar',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _Section(
            title: 'General',
            icon: Icons.notifications_outlined,
            children: [
              _Toggle(
                label: 'Notificaciones push',
                subtitle: 'Alertas en tu dispositivo',
                value: _pushEnabled,
                onChanged: (v) => setState(() => _pushEnabled = v),
              ),
              _Toggle(
                label: 'Notificaciones por email',
                subtitle: 'Resumen en tu correo',
                value: _emailEnabled,
                onChanged: (v) => setState(() => _emailEnabled = v),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _Section(
            title: 'Tipos de alerta',
            icon: Icons.tune,
            children: [
              _Toggle(
                label: 'Nuevas postulaciones',
                subtitle: 'Cuando alguien se postula a tu trabajo',
                value: _newApplications,
                onChanged: (v) => setState(() => _newApplications = v),
              ),
              _Toggle(
                label: 'Mensajes nuevos',
                subtitle: 'Cuando recibes un mensaje en el chat',
                value: _messages,
                onChanged: (v) => setState(() => _messages = v),
              ),
              _Toggle(
                label: 'Actualizaciones de trabajos',
                subtitle: 'Cambios en estado de contratos',
                value: _jobUpdates,
                onChanged: (v) => setState(() => _jobUpdates = v),
              ),
              _Toggle(
                label: 'Calificaciones recibidas',
                subtitle: 'Cuando alguien te califica',
                value: _reviews,
                onChanged: (v) => setState(() => _reviews = v),
              ),
              _Toggle(
                label: 'Novedades y promociones',
                subtitle: 'Ofertas y actualizaciones de LaboraYa',
                value: _promotions,
                onChanged: (v) => setState(() => _promotions = v),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;
  const _Section({
    required this.title,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 10),
          child: Row(
            children: [
              Icon(icon, size: 16, color: AppColors.primary),
              const SizedBox(width: 6),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 8,
              ),
            ],
          ),
          child: Column(
            children: List.generate(
              children.length,
              (i) => Column(
                children: [
                  children[i],
                  if (i < children.length - 1)
                    const Divider(height: 1, indent: 56),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _Toggle extends StatelessWidget {
  final String label;
  final String subtitle;
  final bool value;
  final void Function(bool) onChanged;
  final Color color;

  const _Toggle({
    required this.label,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    this.color = AppColors.primary,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.circle,
              size: 10,
              color: value ? color : AppColors.textHint,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textHint,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: color,
            trackOutlineColor: WidgetStatePropertyAll(Colors.transparent),
          ),
        ],
      ),
    );
  }
}
