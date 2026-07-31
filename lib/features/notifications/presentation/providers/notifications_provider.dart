import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:laboraya_app/core/constants/api_constants.dart';
import 'package:laboraya_app/core/network/api_client.dart';

class NotificationData {
  final String id;
  final String type;
  final String title;
  final String body;
  final String? data;
  final bool isRead;
  final DateTime createdAt;

  NotificationData({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    this.data,
    this.isRead = false,
    required this.createdAt,
  });
}

class NotificationsNotifier extends StateNotifier<List<NotificationData>> {
  final ApiClient _apiClient;
  NotificationsNotifier(this._apiClient) : super([]);

  Future<void> load({int page = 1}) async {
    try {
      final response = await _apiClient.get(
        ApiConstants.notifications,
        queryParameters: {'page': page},
      );
      final data = response.data;
      if (data == null) return;

      final isSuccess =
          data['codigoRespuesta'] == '0' || data['success'] == true;
      if (isSuccess) {
        final list = (data['datos'] ?? data['data'] ?? []) as List;
        state = list
            .map(
              (n) => NotificationData(
                id: (n['id'] ?? n['notificacionId'] ?? '1').toString(),
                type: (n['type'] ?? n['tipo'] ?? 'GENERAL').toString(),
                title: (n['title'] ?? n['titulo'] ?? 'Notificación').toString(),
                body: (n['body'] ?? n['cuerpo'] ?? '').toString(),
                data: n['data']?.toString(),
                isRead: n['esLeido'] == true || n['isRead'] == true,
                createdAt:
                    DateTime.tryParse(
                      (n['createdAt'] ?? n['fechaCreacion'] ?? '').toString(),
                    ) ??
                    DateTime.now(),
              ),
            )
            .toList();
      }
    } catch (_) {}
  }

  Future<void> markRead(String id) async {
    try {
      await _apiClient.put('${ApiConstants.notifications}/$id/read');
      state = state
          .map(
            (n) => n.id == id
                ? NotificationData(
                    id: n.id,
                    type: n.type,
                    title: n.title,
                    body: n.body,
                    data: n.data,
                    isRead: true,
                    createdAt: n.createdAt,
                  )
                : n,
          )
          .toList();
    } catch (_) {}
  }

  Future<void> markAllRead() async {
    try {
      await _apiClient.put(ApiConstants.notificationsReadAll);
      state = state
          .map(
            (n) => NotificationData(
              id: n.id,
              type: n.type,
              title: n.title,
              body: n.body,
              data: n.data,
              isRead: true,
              createdAt: n.createdAt,
            ),
          )
          .toList();
    } catch (_) {}
  }

  int get unreadCount => state.where((n) => !n.isRead).length;
}

final notificationsProvider =
    StateNotifierProvider<NotificationsNotifier, List<NotificationData>>((ref) {
      final apiClient = ref.read(apiClientProvider);
      final notifier = NotificationsNotifier(apiClient);
      notifier.load();
      return notifier;
    });
