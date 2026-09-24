import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_card.dart';
import '../../../services/notification_router.dart';
import '../models/communication_models.dart';
import '../services/communication_service.dart';

class NotificationCenterScreen extends StatefulWidget {
  const NotificationCenterScreen({super.key});

  @override
  State<NotificationCenterScreen> createState() => _NotificationCenterScreenState();
}

class _NotificationCenterScreenState extends State<NotificationCenterScreen> {
  late Future<({int unread, List<NotificationItem> items})> _future;

  @override
  void initState() {
    super.initState();
    _future = context.read<CommunicationService>().getNotifications();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('الإشعارات')),
      body: FutureBuilder<({int unread, List<NotificationItem> items})>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final data = snapshot.data;
          final items = data?.items ?? [];
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              if ((data?.unread ?? 0) > 0)
                AppCard(
                  child: Text('لديك ${data!.unread} إشعار غير مقروء'),
                ),
              const SizedBox(height: 12),
              ...items.map((item) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: AppCard(
                    onTap: () => NotificationRouter.open({
                      'type': item.type,
                      'referenceType': item.referenceType ?? '',
                      'referenceId': '${item.referenceId ?? ''}',
                      'conversationId': '${item.conversationId ?? ''}',
                      'ticketId': item.referenceType == 'StudentTicket' ? '${item.referenceId ?? ''}' : '',
                      'studentId': '${item.studentId ?? ''}',
                      'title': item.title,
                    }),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          item.isRead
                              ? Icons.notifications_none_rounded
                              : Icons.notifications_active_rounded,
                          color: item.isRead ? AppColors.textMuted : AppColors.primary,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.title,
                                style: TextStyle(
                                  fontWeight: item.isRead ? FontWeight.w600 : FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(item.body),
                              const SizedBox(height: 6),
                              Text(
                                DateFormat('yyyy/MM/dd HH:mm').format(item.createdAt.toLocal()),
                                style: const TextStyle(
                                  color: AppColors.textMuted,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          );
        },
      ),
    );
  }
}
