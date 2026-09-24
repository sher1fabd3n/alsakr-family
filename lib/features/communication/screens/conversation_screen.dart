import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../services/api_client.dart';
import '../../parent/state/unread_badge_store.dart';
import '../models/communication_models.dart';
import '../services/communication_service.dart';
import '../services/signalr_chat_service.dart';

class ConversationScreen extends StatefulWidget {
  const ConversationScreen({super.key, required this.conversation});

  final ConversationItem conversation;

  @override
  State<ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends State<ConversationScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final _signalR = SignalRChatService();
  late Future<List<ChatMessageItem>> _future;
  List<ChatMessageItem> _messages = [];
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _future = _loadMessages();
    _connectRealtime();
  }

  Future<List<ChatMessageItem>> _loadMessages() async {
    final service = context.read<CommunicationService>();
    final badges = context.read<UnreadBadgeStore>();
    final messages = await service.getMessages(widget.conversation.id);
    await service.markRead(widget.conversation.id);
    if (mounted) {
      badges.refresh();
    }
    _messages = messages;
    return messages;
  }

  Future<void> _connectRealtime() async {
    final api = context.read<ApiClient>();
    final comm = context.read<CommunicationService>();
    final token = await api.readToken();
    if (token == null) return;

    _signalR.onMessage = (message) {
      if (!mounted) return;
      _appendMessage(message);
      if (message.senderRole != 'Parent') {
        context.read<CommunicationService>().markRead(widget.conversation.id).then((_) {
          if (mounted) context.read<UnreadBadgeStore>().refresh();
        });
      }
    };
    await _signalR.connect(comm, token);
    await _signalR.joinConversation(widget.conversation.id);
  }

  void _appendMessage(ChatMessageItem message) {
    if (_messages.any((m) => m.id == message.id)) return;
    setState(() => _messages = [..._messages, message]);
    _scrollToEnd();
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _sending) return;

    setState(() => _sending = true);
    _controller.clear();

    try {
      final sent = await context.read<CommunicationService>().sendMessage(
            conversationId: widget.conversation.id,
            body: text,
          );
      _appendMessage(sent);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تعذر إرسال الرسالة: $e')),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _signalR.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          children: [
            Text(widget.conversation.studentName),
            Text(
              widget.conversation.studentGrade,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: FutureBuilder<List<ChatMessageItem>>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final messages = _messages.isNotEmpty ? _messages : (snapshot.data ?? []);
                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isMine = message.senderRole == 'Parent';
                    return Align(
                      alignment: isMine ? Alignment.centerLeft : Alignment.centerRight,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.78,
                        ),
                        decoration: BoxDecoration(
                          color: isMine
                              ? AppColors.primary
                              : Theme.of(context).colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (message.body != null)
                              Text(
                                message.body!,
                                style: TextStyle(
                                  color: isMine ? Colors.white : null,
                                ),
                              ),
                            const SizedBox(height: 4),
                            Text(
                              DateFormat('HH:mm').format(message.sentAt.toLocal()),
                              style: TextStyle(
                                fontSize: 11,
                                color: isMine ? Colors.white70 : AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: const InputDecoration(
                        hintText: 'اكتب رسالتك...',
                        border: OutlineInputBorder(),
                      ),
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FloatingActionButton.small(
                    onPressed: _sending ? null : _send,
                    child: _sending
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.send_rounded),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
