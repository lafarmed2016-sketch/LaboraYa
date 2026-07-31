import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:laboraya_app/core/constants/api_constants.dart';
import 'package:laboraya_app/core/network/api_client.dart';

class ChatMessage {
  final String id;
  final String text;
  final bool isMe;
  final String time;
  final String senderId;
  final String status;

  ChatMessage({
    required this.id,
    required this.text,
    required this.isMe,
    required this.time,
    this.senderId = '',
    this.status = 'ENVIADO',
  });
}

class ConversationData {
  final String conversationId;
  final String participantId;
  final String participantName;
  final String? participantAvatar;
  final String? lastMessage;
  final DateTime? lastMessageAt;
  final int unreadCount;
  final bool isOnline;

  ConversationData({
    required this.conversationId,
    required this.participantId,
    required this.participantName,
    this.participantAvatar,
    this.lastMessage,
    this.lastMessageAt,
    this.unreadCount = 0,
    this.isOnline = false,
  });
}

class ChatNotifier extends StateNotifier<Map<String, List<ChatMessage>>> {
  final ApiClient _apiClient;
  ChatNotifier(this._apiClient) : super({});

  Future<List<ChatMessage>> getMessages(
    String conversationId, {
    int page = 1,
  }) async {
    try {
      final response = await _apiClient.get(
        '${ApiConstants.chats}/$conversationId/Mensajes',
        queryParameters: {'page': page},
      );
      final data = response.data;
      if (data == null) return [];

      final isSuccess =
          data['codigoRespuesta'] == '0' || data['success'] == true;
      if (isSuccess) {
        final list = (data['datos'] ?? data['data'] ?? []) as List;
        final messages = list.map((m) {
          final createdAt =
              DateTime.tryParse(
                (m['createdAt'] ?? m['fechaEnvio'] ?? '').toString(),
              ) ??
              DateTime.now();
          final timeStr =
              '${createdAt.hour.toString().padLeft(2, '0')}:${createdAt.minute.toString().padLeft(2, '0')}';
          return ChatMessage(
            id: (m['id'] ?? m['mensajeId'] ?? '1').toString(),
            text: (m['content'] ?? m['contenido'] ?? '').toString(),
            isMe: m['isMe'] == true || m['esMio'] == true,
            time: timeStr,
            senderId: (m['senderId'] ?? m['remitenteId'] ?? '').toString(),
            status: (m['status'] ?? m['estado'] ?? 'ENVIADO').toString(),
          );
        }).toList();

        state = {...state, conversationId: messages};
        return messages;
      }
    } catch (_) {}
    return state[conversationId] ?? [];
  }

  Future<void> sendMessage(String conversationId, String text) async {
    try {
      final intConvId = int.tryParse(conversationId) ?? 1;
      await _apiClient.post(
        '${ApiConstants.chats}/Enviar',
        data: {
          'ConversacionId': intConvId,
          'Contenido': text,
          'TipoMensaje': 'TEXTO',
          'conversacionId': conversationId,
          'content': text,
        },
      );
      await getMessages(conversationId);
    } catch (_) {}
  }
}

final chatProvider =
    StateNotifierProvider<ChatNotifier, Map<String, List<ChatMessage>>>((ref) {
      final apiClient = ref.read(apiClientProvider);
      return ChatNotifier(apiClient);
    });

final conversationsProvider = FutureProvider<List<ConversationData>>((
  ref,
) async {
  try {
    final apiClient = ref.read(apiClientProvider);
    final response = await apiClient.get(
      '${ApiConstants.chats}/Conversaciones',
    );
    final data = response.data;
    if (data == null) return [];

    final isSuccess = data['codigoRespuesta'] == '0' || data['success'] == true;
    if (isSuccess) {
      final list = (data['datos'] ?? data['data'] ?? []) as List;
      return list.map((c) {
        final lastAt = c['lastMessageAt'] ?? c['fechaUltimoMensaje'];
        return ConversationData(
          conversationId: (c['conversationId'] ?? c['conversacionId'] ?? '1')
              .toString(),
          participantId: (c['participantId'] ?? c['usuarioContactoId'] ?? '1')
              .toString(),
          participantName:
              (c['participantName'] ?? c['nombreContacto'] ?? 'Usuario')
                  .toString(),
          participantAvatar: c['participantAvatar'] ?? c['avatarContacto'],
          lastMessage: (c['lastMessage'] ?? c['ultimoMensaje'])?.toString(),
          lastMessageAt: lastAt != null
              ? DateTime.tryParse(lastAt.toString())
              : null,
          unreadCount: (c['unreadCount'] ?? c['cantidadNoLeida'] ?? 0) as int,
          isOnline: c['isOnline'] == true || c['online'] == true,
        );
      }).toList();
    }
  } catch (_) {}
  return [];
});
