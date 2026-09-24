import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/fade_slide_in.dart';
import '../../../core/widgets/section_header.dart';
import '../../../services/notification_router.dart';
import '../models/parent_family_models.dart';
import '../services/parent_family_service.dart';
import '../state/unread_badge_store.dart';

class ParentNotificationsScreen extends StatefulWidget {
  const ParentNotificationsScreen({super.key, this.active = false});

  final bool active;

  @override
  State<ParentNotificationsScreen> createState() => _ParentNotificationsScreenState();
}

class _ParentNotificationsScreenState extends State<ParentNotificationsScreen> {
  late Future<List<ParentChildNotification>> _future;

  @override
  void initState() {
    super.initState();
    _load();
    if (widget.active) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _onOpened());
    }
  }

  @override
  void didUpdateWidget(covariant ParentNotificationsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !oldWidget.active) {
      _onOpened();
    }
  }

  void _load() {
    _future = context.read<ParentFamilyService>().getNotifications();
  }

  Future<void> _onOpened() async {
    await context.read<UnreadBadgeStore>().markNotificationsOpened();
    if (!mounted) return;
    setState(_load);
  }

  String _timeAgo(DateTime time) {
    final local = time.toLocal();
    if (local.year < 2000) return 'الآن';
    final diff = DateTime.now().difference(local);
    if (diff.isNegative || diff.inMinutes < 1) return 'الآن';
    if (diff.inMinutes < 60) return 'منذ ${diff.inMinutes} دقيقة';
    if (diff.inHours < 24) return 'منذ ${diff.inHours} ساعة';
    if (diff.inDays < 30) return 'منذ ${diff.inDays} يوم';
    return '${local.year}/${local.month.toString().padLeft(2, '0')}/${local.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          if (widget.active) {
            await context.read<UnreadBadgeStore>().markNotificationsOpened();
          }
          if (!mounted) return;
          setState(_load);
          await _future;
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: PageHeader(
                title: 'الإشعارات',
                subtitle: 'إشعارات مرتبطة بكل ابن',
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
              sliver: FutureBuilder<List<ParentChildNotification>>(
                future: _future,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const SliverFillRemaining(child: Center(child: CircularProgressIndicator()));
                  }
                  if (snapshot.hasError) {
                    return SliverFillRemaining(
                      child: Center(child: Text(snapshot.error.toString().replaceFirst('Exception: ', ''))),
                    );
                  }

                  final notifications = snapshot.data ?? [];
                  if (notifications.isEmpty) {
                    return const SliverFillRemaining(child: Center(child: Text('لا توجد إشعارات')));
                  }

                  final unread = notifications.where((n) => !n.isRead).length;

                  return SliverList(
                    delegate: SliverChildListDelegate([
                      if (unread > 0)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Text('$unread إشعارات جديدة',
                              style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700)),
                        ),
                      ...notifications.asMap().entries.map((entry) {
                        final item = entry.value;
                        return FadeSlideIn(
                          delay: Duration(milliseconds: 70 * entry.key),
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: AppCard(
                              onTap: () => NotificationRouter.open({
                                'type': item.type ?? item.referenceType ?? '',
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
                                  Stack(
                                    children: [
                                      CircleAvatar(
                                        radius: 24,
                                        backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                                        backgroundImage: item.studentPhotoUrl != null
                                            ? NetworkImage(item.studentPhotoUrl!)
                                            : null,
                                        child: item.studentPhotoUrl == null
                                            ? Text(
                                                (item.studentName?.isNotEmpty == true)
                                                    ? item.studentName![0]
                                                    : '?',
                                              )
                                            : null,
                                      ),
                                      if (!item.isRead)
                                        Positioned(
                                          right: 0,
                                          top: 0,
                                          child: Container(
                                            width: 10,
                                            height: 10,
                                            decoration: const BoxDecoration(
                                              color: AppColors.primary,
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
                                        if (item.studentName != null)
                                          Text(
                                            item.studentName!,
                                            style: const TextStyle(
                                              color: AppColors.primary,
                                              fontWeight: FontWeight.w700,
                                              fontSize: 12,
                                            ),
                                          ),
                                        Text(
                                          item.title,
                                          style: TextStyle(
                                            fontWeight: item.isRead ? FontWeight.w600 : FontWeight.w800,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(item.body, style: const TextStyle(color: AppColors.textSecondary)),
                                        const SizedBox(height: 8),
                                        Text(_timeAgo(item.createdAt),
                                            style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
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
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
