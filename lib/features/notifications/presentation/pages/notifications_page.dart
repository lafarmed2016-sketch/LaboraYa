import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:laboraya_app/core/constants/app_colors.dart';
import 'package:laboraya_app/core/services/mock_data_service.dart';

class NotificationsPage extends ConsumerStatefulWidget {
  const NotificationsPage({super.key});

  @override
  ConsumerState<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends ConsumerState<NotificationsPage> {
  late List<MockNotification> _notifications;

  @override
  void initState() {
    super.initState();
    _notifications = [];
  }

  void _markAllRead() {
    setState(() {
      _notifications = _notifications
          .map(
            (n) => MockNotification(
              id: n.id,
              type: n.type,
              title: n.title,
              body: n.body,
              time: n.time,
              isRead: true,
              relatedId: n.relatedId,
            ),
          )
          .toList();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Todas marcadas como leídas'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  void _onTapNotification(MockNotification notif) {
    // Marcar como leída
    setState(() {
      final index = _notifications.indexWhere((n) => n.id == notif.id);
      if (index >= 0) {
        _notifications[index] = MockNotification(
          id: notif.id,
          type: notif.type,
          title: notif.title,
          body: notif.body,
          time: notif.time,
          isRead: true,
          relatedId: notif.relatedId,
        );
      }
    });

    // Navegar según tipo
    if (notif.relatedId != null) {
      switch (notif.type) {
        case 'application':
        case 'accepted':
        case 'completed':
          context.push('/jobs/${notif.relatedId}');
          break;
        case 'message':
          context.push('/chat/${notif.relatedId}');
          break;
        default:
          break;
      }
    }
  }

  IconData _getIcon(String type) {
    switch (type) {
      case 'application':
        return Icons.person_add;
      case 'accepted':
        return Icons.check_circle;
      case 'message':
        return Icons.chat_bubble;
      case 'review':
        return Icons.star;
      case 'completed':
        return Icons.task_alt;
      default:
        return Icons.notifications;
    }
  }

  Color _getColor(String type) {
    switch (type) {
      case 'application':
        return AppColors.success;
      case 'accepted':
        return AppColors.primary;
      case 'message':
        return AppColors.info;
      case 'review':
        return AppColors.star;
      case 'completed':
        return AppColors.primary;
      default:
        return AppColors.textHint;
    }
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount = _notifications.where((n) => !n.isRead).length;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(
          'Notificaciones${unreadCount > 0 ? ' ($unreadCount)' : ''}',
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          if (unreadCount > 0)
            TextButton(
              onPressed: _markAllRead,
              child: const Text('Marcar todo', style: TextStyle(fontSize: 13)),
            ),
        ],
      ),
      body: _notifications.isEmpty
          ? const Center(
              child: Text(
                'Sin notificaciones',
                style: TextStyle(color: AppColors.textHint),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: _notifications.length,
              separatorBuilder: (_, __) => const Divider(indent: 72, height: 1),
              itemBuilder: (context, index) {
                final notif = _notifications[index];
                final color = _getColor(notif.type);
                return Material(
                  color: notif.isRead
                      ? Colors.white
                      : AppColors.secondaryLight.withValues(alpha: 0.2),
                  child: InkWell(
                    onTap: () => _onTapNotification(notif),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: color.withValues(alpha: 0.1),
                            child: Icon(
                              _getIcon(notif.type),
                              color: color,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  notif.title,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: notif.isRead
                                        ? FontWeight.w500
                                        : FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  notif.body,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: AppColors.textSecondary,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  notif.time,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textHint,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (!notif.isRead)
                            Container(
                              width: 8,
                              height: 8,
                              margin: const EdgeInsets.only(top: 6),
                              decoration: const BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
