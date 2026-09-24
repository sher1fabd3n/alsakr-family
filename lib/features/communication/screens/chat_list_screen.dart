import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/fade_slide_in.dart';
import '../../../core/widgets/unread_count_badge.dart';
import '../../parent/state/unread_badge_store.dart';
import '../models/communication_models.dart';
import '../services/communication_service.dart';
import 'conversation_screen.dart';
import 'start_conversation_screen.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  late Future<List<ConversationItem>> _future;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _future = context.read<CommunicationService>().getConversations(
          search: _searchController.text.trim(),
        );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('المحادثات')),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'new_chat_parent',
        onPressed: () async {
          await Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const StartConversationScreen()),
          );
          setState(_load);
        },
        icon: const Icon(Icons.add_comment_rounded),
        label: const Text('محادثة جديدة'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'بحث في المحادثات...',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: IconButton(
                  onPressed: () => setState(_load),
                  icon: const Icon(Icons.arrow_forward_rounded),
                ),
              ),
              onSubmitted: (_) => setState(_load),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<ConversationItem>>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text(snapshot.error.toString()));
                }
                final items = snapshot.data ?? [];
                if (items.isEmpty) {
                  return const Center(child: Text('لا توجد محادثات بعد'));
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return FadeSlideIn(
                      delay: Duration(milliseconds: 40 * index),
                      child: AppCard(
                        onTap: () async {
                          final badges = context.read<UnreadBadgeStore>();
                          await Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => ConversationScreen(conversation: item),
                            ),
                          );
                          if (!mounted) return;
                          setState(_load);
                          badges.refresh();
                        },
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                              child: Text(
                                item.studentName.isNotEmpty ? item.studentName[0] : 'ط',
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.studentName,
                                    style: const TextStyle(fontWeight: FontWeight.w800),
                                  ),
                                  Text(
                                    item.teacherName,
                                    style: const TextStyle(color: AppColors.textSecondary),
                                  ),
                                  if (item.lastMessagePreview != null)
                                    Text(
                                      item.lastMessagePreview!,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(color: AppColors.textMuted),
                                    ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                if (item.lastMessageAt != null)
                                  Text(
                                    DateFormat('HH:mm').format(item.lastMessageAt!.toLocal()),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textMuted,
                                    ),
                                  ),
                                if (item.unreadCount > 0)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 6),
                                    child: UnreadCountPill(count: item.unreadCount),
                                  ),
                              ],
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
        ],
      ),
    );
  }
}
