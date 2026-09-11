import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:laboraya_app/core/constants/app_colors.dart';
import 'package:laboraya_app/features/notifications/presentation/providers/notifications_provider.dart';

class NotificationsPage extends ConsumerStatefulWidget {
  const NotificationsPage({super.key});

  @override
  ConsumerState<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends ConsumerState<NotificationsPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(notificationsProvider.notifier).load();
    });
  }

  void _markAllRead() {
    ref.read(notificationsProvider.notifier).markAllRead();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Todas marcadas como leídas'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  void _onTapNotification(NotificationData notif) {
    if (!notif.isRead) {
      ref.read(notificationsProvider.notifier).markRead(notif.id);
    }

    if (notif.data != null && notif.data!.isNotEmpty) {
      final typeUpper = notif.type.toUpperCase();
      if (typeUpper.contains('CHAT') || typeUpper.contains('MESSAGE')) {
        context.push('/chat/${notif.data}');
      } else if (typeUpper.contains('JOB') || typeUpper.contains('APPLICATION')) {
        context.push('/jobs/${notif.data}');
      }
    }
  }

  IconData _getIcon(String type) {
    final t = type.toUpperCase();
    if (t.contains('APPLICATION')) return Icons.person_add;
    if (t.contains('ACCEPTED')) return Icons.check_circle;
    if (t.contains('CHAT') || t.contains('MESSAGE')) return Icons.chat_bubble;
    if (t.contains('REVIEW')) return Icons.star;
    if (t.contains('COMPLETED')) return Icons.task_alt;
    if (t.contains('JOB_SAVED') || t.contains('FAVORITE')) return Icons.bookmark_added;
    return Icons.notifications;
  }

  Color _getColor(String type) {
    final t = type.toUpperCase();
    if (t.contains('APPLICATION')) return AppColors.success;
    if (t.contains('ACCEPTED')) return AppColors.primary;
    if (t.contains('CHAT') || t.contains('MESSAGE')) return AppColors.info;
    if (t.contains('REVIEW')) return AppColors.star;
    if (t.contains('COMPLETED')) return AppColors.primary;
    if (t.contains('JOB_SAVED') || t.contains('FAVORITE')) return const Color(0xFFF59E0B);
    return AppColors.textHint;
  }

  @override
  Widget build(BuildContext context) {
    final notifications = ref.watch(notificationsProvider);
    final unreadCount = ref.watch(notificationsProvider.notifier).unreadCount;

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
      body: notifications.isEmpty
          ? const Center(
              child: Text(
                'Sin notificaciones',
                style: TextStyle(color: AppColors.textHint),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: notifications.length,
              separatorBuilder: (_, __) => const Divider(indent: 72, height: 1),
              itemBuilder: (context, index) {
                final notif = notifications[index];
                final color = _getColor(notif.type);
                final timeStr = timeago.format(notif.createdAt, locale: 'es');

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
                                  timeStr,
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
