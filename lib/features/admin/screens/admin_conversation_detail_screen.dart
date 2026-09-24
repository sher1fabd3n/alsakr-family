import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../communication/models/communication_models.dart';
import '../../../core/theme/app_colors.dart';
import '../models/admin_models.dart';
import '../services/admin_service.dart';

class AdminConversationDetailScreen extends StatefulWidget {
  const AdminConversationDetailScreen({super.key, required this.conversation});

  final AdminConversationSummary conversation;

  @override
  State<AdminConversationDetailScreen> createState() =>
      _AdminConversationDetailScreenState();
}

class _AdminConversationDetailScreenState extends State<AdminConversationDetailScreen> {
  late Future<List<ChatMessageItem>> _future;

  @override
  void initState() {
    super.initState();
    _future = context.read<AdminService>().getConversationMessages(widget.conversation.id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          children: [
            Text(widget.conversation.studentName),
            Text(
              'مراقبة — ${widget.conversation.teacherName}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
      body: FutureBuilder<List<ChatMessageItem>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final messages = snapshot.data ?? [];
          if (messages.isEmpty) {
            return const Center(child: Text('لا توجد رسائل في هذه المحادثة'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: messages.length,
            itemBuilder: (context, index) {
              final message = messages[index];
              final isTeacher = message.senderRole == 'Teacher';
              return Align(
                alignment: isTeacher ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(12),
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.8,
                  ),
                  decoration: BoxDecoration(
                    color: isTeacher
                        ? AppColors.primary.withValues(alpha: 0.12)
                        : AppColors.secondary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        message.senderRole,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textMuted,
                        ),
                      ),
                      if (message.body != null) Text(message.body!),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat('HH:mm').format(message.sentAt.toLocal()),
                        style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
