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
  final Ref? _ref;
  ChatNotifier(this._apiClient, [this._ref]) : super({});

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
                (m['createdAt'] ?? m['fechaEnvio'] ?? m['fechaCreacion'] ?? '').toString(),
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

  Future<String?> getOrCreateConversation(int otherUserId, {int? jobId}) async {
    try {
      final response = await _apiClient.post(
        ApiConstants.chatCreate,
        data: {
          'OtroUsuarioId': otherUserId,
          'TrabajoId': jobId,
        },
      );
      final data = response.data;
      if (data != null &&
          (data['codigoRespuesta'] == '0' || data['success'] == true)) {
        final d = data['datos'] ?? data['data'] ?? data;
        final convId = (d['conversacionId'] ?? d['id'] ?? '').toString();
        if (convId.isNotEmpty) return convId;
      }
    } catch (_) {}
    return null;
  }

  Future<String?> sendMessage(String conversationId, String text, {String? participantId}) async {
    try {
      String targetConvId = conversationId;
      if (conversationId.startsWith('new_')) {
        final otherId = int.tryParse(participantId ?? conversationId.replaceFirst('new_', ''));
        if (otherId != null) {
          final realId = await getOrCreateConversation(otherId);
          if (realId != null && realId.isNotEmpty) {
            targetConvId = realId;
          }
        }
      }

      final intConvId = int.tryParse(targetConvId) ?? 1;
      await _apiClient.post(
        '${ApiConstants.chats}/Enviar',
        data: {
          'ConversacionId': intConvId,
          'Contenido': text,
          'TipoMensaje': 'TEXTO',
          'conversacionId': targetConvId,
          'content': text,
        },
      );
      await getMessages(targetConvId);
      if (targetConvId != conversationId) {
        state = {...state, conversationId: state[targetConvId] ?? []};
      }
      _ref?.invalidate(conversationsProvider);
      return targetConvId;
    } catch (_) {}
    return null;
  }
}

final chatProvider =
    StateNotifierProvider<ChatNotifier, Map<String, List<ChatMessage>>>((ref) {
      final apiClient = ref.read(apiClientProvider);
      return ChatNotifier(apiClient, ref);
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
        final lastAt = c['lastMessageAt'] ?? c['ultimoMensajeFecha'];
        return ConversationData(
          conversationId: (c['conversationId'] ?? c['id'] ?? '1').toString(),
          participantId: (c['participantId'] ?? c['otroUsuarioId'] ?? '1').toString(),
          participantName: (c['participantName'] ?? c['otroUsuarioNombre'] ?? 'Usuario').toString(),
          participantAvatar: c['participantAvatar'] ?? c['otroUsuarioFoto'],
          lastMessage: (c['lastMessage'] ?? c['ultimoMensaje'])?.toString(),
          lastMessageAt: lastAt != null ? DateTime.tryParse(lastAt.toString()) : null,
          unreadCount: (c['unreadCount'] ?? c['mensajesSinLeer'] ?? 0) as int,
          isOnline: c['isOnline'] == true || c['online'] == true,
        );
      }).toList();
    }
  } catch (_) {}
  return [];
});
