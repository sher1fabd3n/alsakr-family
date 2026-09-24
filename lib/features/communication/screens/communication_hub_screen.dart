import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app_state.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/fade_slide_in.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/unread_count_badge.dart';
import '../../parent/state/unread_badge_store.dart';
import 'announcement_center_screen.dart';
import 'chat_list_screen.dart';
import 'communication_search_screen.dart';
import 'notification_center_screen.dart';
import '../../tickets/screens/parent_tickets_screen.dart';

class CommunicationHubScreen extends StatelessWidget {
  const CommunicationHubScreen({super.key, required this.role});

  final String role;

  @override
  Widget build(BuildContext context) {
    final isParent = role == 'Parent';
    final isTeacher = role == 'Teacher';
    final perms = context.watch<AppState>();
    final showChat = !isParent || perms.parentCanChat;
    final showTickets = isParent && perms.parentCanTickets;
    final showNotifications = !isParent || perms.parentCanNotifications;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: PageHeader(
              title: 'مركز التواصل',
              subtitle: isParent
                  ? 'تواصل مع معلمي أبنائك'
                  : isTeacher
                      ? 'تواصل مع أولياء الأمور'
                      : 'الإعلانات والرسائل المدرسية',
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                if (showChat)
                FadeSlideIn(
                  child: AppCard(
                    gradient: const LinearGradient(colors: AppColors.gradientPrimary),
                    onTap: () {
                      Navigator.of(context)
                          .push(
                            MaterialPageRoute(builder: (_) => const ChatListScreen()),
                          )
                          .then((_) {
                        if (context.mounted && isParent) {
                          context.read<UnreadBadgeStore>().refresh();
                        }
                      });
                    },
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'المحادثات',
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                    ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'رسائل مباشرة مع ${isParent ? 'المعلمين' : 'أولياء الأمور'}',
                                style: TextStyle(color: Colors.white.withValues(alpha: 0.88)),
                              ),
                            ],
                          ),
                        ),
                        UnreadCountBadge(
                          count: isParent ? context.watch<UnreadBadgeStore>().chatCount : 0,
                          inverted: true,
                          offset: const Offset(-4, -8),
                          child: const Icon(Icons.chat_bubble_rounded, color: Colors.white, size: 36),
                        ),
                      ],
                    ),
                  ),
                ),
                if (showChat) const SizedBox(height: 14),
                if (showTickets)
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 140),
                    child: AppCard(
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const ParentTicketsScreen()),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.warning.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(Icons.support_agent_rounded, color: AppColors.warning),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'الشكاوى والمقترحات',
                                  style: TextStyle(fontWeight: FontWeight.w800),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'تواصل مع الإدارة بشأن مشكلة أو مقترح',
                                  style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_left_rounded),
                        ],
                      ),
                    ),
                  ),
                if (showTickets) const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: FadeSlideIn(
                        delay: const Duration(milliseconds: 80),
                        child: _HubTile(
                          title: 'الإعلانات',
                          icon: Icons.campaign_rounded,
                          color: AppColors.accent,
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const AnnouncementCenterScreen(),
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (showNotifications) ...[
                      const SizedBox(width: 12),
                      Expanded(
                        child: FadeSlideIn(
                          delay: const Duration(milliseconds: 120),
                          child: _HubTile(
                            title: 'الإشعارات',
                            icon: Icons.notifications_active_rounded,
                            color: AppColors.secondary,
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const NotificationCenterScreen(),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 20),
                FadeSlideIn(
                  delay: const Duration(milliseconds: 160),
                  child: AppCard(
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const CommunicationSearchScreen(),
                      ),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.search_rounded, color: AppColors.primary),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'بحث في المحادثات والإعلانات',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                        Icon(Icons.chevron_left_rounded),
                      ],
                    ),
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _HubTile extends StatelessWidget {
  const _HubTile({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(height: 12),
          Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}
