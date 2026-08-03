import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:laboraya_app/core/constants/app_colors.dart';
import 'package:laboraya_app/features/chat/presentation/providers/chat_provider.dart';

class ChatPage extends ConsumerStatefulWidget {
  final String conversationId;
  final String? participantName;
  final String? participantAvatar;
  final String? participantId;

  const ChatPage({
    super.key,
    required this.conversationId,
    this.participantName,
    this.participantAvatar,
    this.participantId,
  });

  @override
  ConsumerState<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends ConsumerState<ChatPage> {
  final _msgCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _msgCtrl.addListener(
      () => setState(() => _hasText = _msgCtrl.text.trim().isNotEmpty),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!widget.conversationId.startsWith('new_')) {
        ref.read(chatProvider.notifier).getMessages(widget.conversationId);
      }
    });
  }

  @override
  void dispose() {
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _send() {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty) return;
    ref.read(chatProvider.notifier).sendMessage(
      widget.conversationId,
      text,
      participantId: widget.participantId,
    );
    _msgCtrl.clear();
    _scrollToBottom();
  }

  void _scrollToBottom() {
    if (_scrollCtrl.hasClients) {
      _scrollCtrl.animateTo(
        _scrollCtrl.position.maxScrollExtent + 100,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final messages = ref.watch(chatProvider)[widget.conversationId] ?? [];
    final conversations = ref.watch(conversationsProvider).value ?? [];
    final convo = conversations.where((c) => c.conversationId == widget.conversationId).firstOrNull;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(context, convo),
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Column(
          children: [
            // ── Lista de Mensajes ──────────────────────────────────
            Expanded(
              child: messages.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            decoration: const BoxDecoration(
                              color: AppColors.primaryLight,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.chat_bubble_outline_rounded,
                              size: 30,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Di hola 👋',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 16,
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Inicia una conversación sobre el trabajo',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 13,
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      controller: _scrollCtrl,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                      itemCount: messages.length,
                      itemBuilder: (context, i) {
                        final msg = messages[i];
                        return _MessageBubble(msg: msg);
                      },
                    ),
            ),
            // ── Campo de escritura ────────────────────────────────
            _buildInput(context),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, ConversationData? convo) {
    final titleName = (widget.participantName != null && widget.participantName!.isNotEmpty)
        ? widget.participantName!
        : (convo?.participantName ?? 'Contacto');
    final initial = titleName.isNotEmpty ? titleName[0].toUpperCase() : 'U';
    final avatarUrl = widget.participantAvatar ?? convo?.participantAvatar;
    final isOnline = convo?.isOnline ?? false;

    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      titleSpacing: 0,
      centerTitle: false,
      leading: Padding(
        padding: const EdgeInsets.only(left: 12),
        child: IconButton(
          icon: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border),
            ),
            child: const Icon(
              Icons.arrow_back_rounded,
              color: AppColors.textPrimary,
              size: 18,
            ),
          ),
          onPressed: () => context.pop(),
        ),
      ),
      title: Row(
        children: [
          const SizedBox(width: 8),
          Stack(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.primaryLight,
                backgroundImage: (avatarUrl != null && avatarUrl.isNotEmpty)
                    ? NetworkImage(avatarUrl)
                    : null,
                child: (avatarUrl == null || avatarUrl.isEmpty)
                    ? Text(
                        initial,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                          fontFamily: 'Poppins',
                        ),
                      )
                    : null,
              ),
              if (isOnline)
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: AppColors.success,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  titleName,
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    fontFamily: 'Poppins',
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  isOnline ? 'En línea' : 'Desconectado',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: isOnline ? AppColors.success : AppColors.textSecondary,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
    );
  }

  Widget _buildInput(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(
              Icons.attach_file_rounded,
              color: AppColors.textHint,
              size: 22,
            ),
            onPressed: () {},
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.border),
              ),
              child: TextField(
                controller: _msgCtrl,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14,
                  color: AppColors.textPrimary,
                ),
                decoration: const InputDecoration(
                  hintText: 'Escribe un mensaje...',
                  hintStyle: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13.5,
                    color: AppColors.textHint,
                  ),
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _hasText ? _send : null,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _hasText ? AppColors.primary : AppColors.border,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.send_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final ChatMessage msg;

  const _MessageBubble({required this.msg});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: msg.isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: msg.isMe ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(msg.isMe ? 16 : 4),
            bottomRight: Radius.circular(msg.isMe ? 4 : 16),
          ),
          border: msg.isMe
              ? null
              : Border.all(color: AppColors.border, width: 0.8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: msg.isMe
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            Text(
              msg.text,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 13.5,
                color: msg.isMe ? Colors.white : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              msg.time,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 10.5,
                color: msg.isMe ? Colors.white70 : AppColors.textHint,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
