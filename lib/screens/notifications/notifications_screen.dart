import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/section_header.dart';
import '../../core/widgets/fade_slide_in.dart';
import '../../data/mock_content.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  String _timeAgo(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 60) return 'منذ ${diff.inMinutes} دقيقة';
    if (diff.inHours < 24) return 'منذ ${diff.inHours} ساعة';
    return 'منذ ${diff.inDays} يوم';
  }

  @override
  Widget build(BuildContext context) {
    final notifications = MockContent.notifications();
    final unread = notifications.where((n) => n.isUnread).length;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: PageHeader(
              title: 'مركز الإشعارات',
              subtitle: unread > 0 ? '$unread إشعارات جديدة' : 'لا توجد إشعارات جديدة',
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                ...notifications.asMap().entries.map((entry) {
                  final index = entry.key;
                  final item = entry.value;
                  return FadeSlideIn(
                    delay: Duration(milliseconds: 70 * index),
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: AppCard(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Stack(
                              children: [
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: item.color.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Icon(item.icon, color: item.color),
                                ),
                                if (item.isUnread)
                                  Positioned(
                                    right: 0,
                                    top: 0,
                                    child: Container(
                                      width: 10,
                                      height: 10,
                                      decoration: const BoxDecoration(
                                        color: AppColors.danger,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.title,
                                    style: TextStyle(
                                      fontWeight: item.isUnread
                                          ? FontWeight.w800
                                          : FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    item.body,
                                    style: const TextStyle(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    _timeAgo(item.time),
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
                    ),
                  );
                }),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}
