import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:laboraya_app/core/constants/app_colors.dart';
import 'package:laboraya_app/core/widgets/empty_state_widget.dart';
import 'package:laboraya_app/features/chat/presentation/providers/chat_provider.dart';

class ConversationsPage extends ConsumerStatefulWidget {
  const ConversationsPage({super.key});

  @override
  ConsumerState<ConversationsPage> createState() => _ConversationsPageState();
}

class _ConversationsPageState extends ConsumerState<ConversationsPage> {
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';
  bool _isSearching = false;

  static const _kBg = AppColors.background;
  static const _kHeaderBg = Colors.white;
  static const _kSurface = Colors.white;
  static const _kGreenPrimary = AppColors.primary;
  static const _kTextPrimary = AppColors.textPrimary;
  static const _kTextSecondary = AppColors.textSecondary;
  static const _kBorder = AppColors.border;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final conversationsAsync = ref.watch(conversationsProvider);

    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kHeaderBg,
        elevation: 0,
        centerTitle: false,
        automaticallyImplyLeading: false,
        title: const Text(
          'Chats',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: _kTextPrimary,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _isSearching ? Icons.close_rounded : Icons.search_rounded,
              color: _kGreenPrimary,
            ),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _searchCtrl.clear();
                  _searchQuery = '';
                }
              });
            },
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: Column(
        children: [
          // ── Buscador ──────────────────────────────────────────────
          if (_isSearching)
            Container(
              color: _kHeaderBg,
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
              child: TextField(
                controller: _searchCtrl,
                onChanged: (v) =>
                    setState(() => _searchQuery = v.trim().toLowerCase()),
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14,
                  color: _kTextPrimary,
                ),
                decoration: InputDecoration(
                  hintText: 'Buscar conversaciones...',
                  hintStyle: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13.5,
                    color: _kTextSecondary,
                  ),
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    color: _kTextSecondary,
                    size: 20,
                  ),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(
                            Icons.clear_rounded,
                            size: 18,
                            color: _kTextSecondary,
                          ),
                          onPressed: () {
                            _searchCtrl.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: _kSurface,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: _kBorder),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: _kBorder),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(
                      color: _kGreenPrimary,
                      width: 1.5,
                    ),
                  ),
                ),
              ),
            ),
          // ── Lista ──────────────────────────────────────────────────
          Expanded(
            child: conversationsAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: _kGreenPrimary),
              ),
              error: (err, _) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.wifi_off_rounded,
                      size: 48,
                      color: _kTextSecondary,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Error al cargar conversaciones',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 14,
                        color: _kTextSecondary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => ref.invalidate(conversationsProvider),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _kGreenPrimary,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Reintentar'),
                    ),
                  ],
                ),
              ),
              data: (list) {
                final filtered = list.where((c) {
                  if (_searchQuery.isEmpty) return true;
                  return c.participantName.toLowerCase().contains(
                        _searchQuery,
                      ) ||
                      (c.lastMessage?.toLowerCase().contains(_searchQuery) ??
                          false);
                }).toList();

                if (filtered.isEmpty) {
                  return const EmptyStateWidget(
                    icon: Icons.chat_bubble_outline_rounded,
                    title: 'No hay mensajes aún',
                    description:
                        'Tus chats con trabajadores o empleadores aparecerán aquí.',
                  );
                }

                return Container(
                  color: Colors.white,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) =>
                        const Divider(color: _kBorder, height: 1, indent: 80),
                    itemBuilder: (ctx, index) {
                      final item = filtered[index];
                      final initial = item.participantName.isNotEmpty
                          ? item.participantName[0].toUpperCase()
                          : 'U';

                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 4,
                        ),
                        onTap: () => context.push('/chat/${item.conversationId}'),
                        leading: Stack(
                          children: [
                            CircleAvatar(
                              radius: 26,
                              backgroundColor: AppColors.primaryLight,
                              child: Text(
                                initial,
                                style: const TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: _kGreenPrimary,
                                ),
                              ),
                            ),
                            if (item.isOnline)
                              Positioned(
                                right: 0,
                                bottom: 0,
                                child: Container(
                                  width: 13,
                                  height: 13,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF30B878),
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 2),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        title: Row(
                          children: [
                            Expanded(
                              child: Text(
                                item.participantName,
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 15,
                                  fontWeight: item.unreadCount > 0
                                      ? FontWeight.w700
                                      : FontWeight.w600,
                                  color: _kTextPrimary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (item.lastMessageAt != null)
                              Text(
                                _formatTime(item.lastMessageAt!),
                                style: const TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 11.5,
                                  color: _kTextSecondary,
                                ),
                              ),
                          ],
                        ),
                        subtitle: Row(
                          children: [
                            Expanded(
                              child: Text(
                                item.lastMessage ?? 'Inicia una conversación',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 13,
                                  color: item.unreadCount > 0
                                      ? _kTextPrimary
                                      : _kTextSecondary,
                                  fontWeight: item.unreadCount > 0
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (item.unreadCount > 0) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: _kGreenPrimary,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '${item.unreadCount}',
                                  style: const TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime date) {
    final now = DateTime.now();
    if (now.day == date.day &&
        now.month == date.month &&
        now.year == date.year) {
      return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    }
    return '${date.day}/${date.month}';
  }
}
