import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_card.dart';
import '../models/transportation_models.dart';
import '../services/transportation_service.dart';

class TransportNotificationsScreen extends StatefulWidget {
  const TransportNotificationsScreen({super.key, this.studentId});

  final int? studentId;

  @override
  State<TransportNotificationsScreen> createState() => _TransportNotificationsScreenState();
}

class _TransportNotificationsScreenState extends State<TransportNotificationsScreen> {
  late Future<List<TransportNotificationItem>> _future;

  @override
  void initState() {
    super.initState();
    _future = context.read<TransportationService>().getNotifications(studentId: widget.studentId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('إشعارات النقل')),
      body: FutureBuilder<List<TransportNotificationItem>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final items = snapshot.data ?? [];
          if (items.isEmpty) {
            return const Center(child: Text('لا توجد إشعارات نقل'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final item = items[index];
              return AppCard(
                onTap: () async {
                  if (!item.isRead) {
                    await context.read<TransportationService>().markNotificationRead(item.id);
                  }
                },
                child: ListTile(
                  leading: Icon(
                    Icons.notifications_rounded,
                    color: item.isRead ? AppColors.textMuted : AppColors.primary,
                  ),
                  title: Text(item.body, style: const TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: Text(
                    _formatNotificationTime(item.createdAt),
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                  trailing: item.isRead
                      ? null
                      : Container(
                          width: 10,
                          height: 10,
                          decoration: const BoxDecoration(
                            color: AppColors.danger,
                            shape: BoxShape.circle,
                          ),
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

String _formatNotificationTime(DateTime createdAt) {
  final local = createdAt.toLocal();
  if (local.year < 2000) return 'الآن';
  return DateFormat('yyyy/MM/dd HH:mm').format(local);
}
