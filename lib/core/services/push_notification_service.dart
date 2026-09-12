import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:laboraya_app/core/network/api_client.dart';
import 'package:laboraya_app/features/chat/presentation/providers/chat_provider.dart';
import 'package:laboraya_app/features/notifications/presentation/providers/notifications_provider.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Manejador en segundo plano / app cerrada
}

class PushNotificationService {
  final ApiClient _apiClient;
  final Ref _ref;

  PushNotificationService(this._apiClient, this._ref);

  Future<void> initialize(GoRouter router) async {
    final messaging = FirebaseMessaging.instance;

    // 1. Solicitar permisos (Android 13+ y iOS)
    try {
      final settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional) {
        await messaging.setForegroundNotificationPresentationOptions(
          alert: true,
          badge: true,
          sound: true,
        );

        // 2. Obtener Token y registrar en Backend
        final token = await messaging.getToken();
        if (token != null && token.isNotEmpty) {
          final preview = token.length >= 20
              ? '${token.substring(0, 10)}...${token.substring(token.length - 10)}'
              : token;
          print('TOKEN OBTENIDO: SI');
          print('LONGITUD: ${token.length}');
          print('PREVIEW: $preview');
          await registerToken(token);
        } else {
          print('TOKEN OBTENIDO: NO');
        }

        // Escuchar renovación de Token FCM
        messaging.onTokenRefresh.listen((newToken) {
          if (newToken.isNotEmpty) {
            final preview = newToken.length >= 20
                ? '${newToken.substring(0, 10)}...${newToken.substring(newToken.length - 10)}'
                : newToken;
            print('TOKEN REFRESHED: SI');
            print('LONGITUD: ${newToken.length}');
            print('PREVIEW: $preview');
            registerToken(newToken);
          }
        });
      }
    } catch (_) {}

    // 3. App abierta (Foreground)
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _handleMessage(message, isForeground: true);
    });

    // 4. App en segundo plano (al tocar notificación)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _handleNotificationClick(message, router);
    });

    // 5. App completamente cerrada (al abrir desde notificación)
    try {
      final initialMessage = await messaging.getInitialMessage();
      if (initialMessage != null) {
        _handleNotificationClick(initialMessage, router);
      }
    } catch (_) {}
  }

  Future<void> registerToken(String token) async {
    try {
      await _apiClient.post(
        '/api/v2/UsuariosV2/RegistrarFcmToken',
        data: {
          'token': token,
          'plataforma': 'ANDROID',
        },
      );
    } catch (_) {}
  }

  void _handleMessage(RemoteMessage message, {required bool isForeground}) {
    _ref.invalidate(notificationsProvider);

    final data = message.data;
    final type = (data['type'] ?? '').toString();

    if (type == 'CHAT') {
      _ref.invalidate(conversationsProvider);
      final convId = data['conversationId']?.toString();
      if (convId != null && convId.isNotEmpty) {
        _ref.read(chatProvider.notifier).getMessages(convId);
      }
    }
  }

  void _handleNotificationClick(RemoteMessage message, GoRouter router) {
    _handleMessage(message, isForeground: false);
    final data = message.data;
    final type = (data['type'] ?? '').toString();

    if (type == 'CHAT') {
      final convId = data['conversationId']?.toString();
      if (convId != null && convId.isNotEmpty) {
        router.push('/chat/$convId');
      }
    } else if (type == 'LIKE' || type == 'COMMENT') {
      final jobId = data['jobId']?.toString();
      if (jobId != null && jobId.isNotEmpty) {
        router.push('/job/$jobId');
      }
    }
  }
}

final pushNotificationServiceProvider = Provider<PushNotificationService>((ref) {
  final apiClient = ref.read(apiClientProvider);
  return PushNotificationService(apiClient, ref);
});
