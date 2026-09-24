import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/fade_slide_in.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/stat_card.dart';
import '../models/admin_models.dart';
import '../services/admin_service.dart';
import 'admin_announcements_screen.dart';
import 'admin_conversations_screen.dart';
import 'admin_parent_accounts_screen.dart';
import 'admin_parent_id_validation_screen.dart';
import '../../tickets/screens/admin_tickets_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  late Future<AdminStats> _future;

  @override
  void initState() {
    super.initState();
    _future = context.read<AdminService>().getStats();
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        setState(() => _future = context.read<AdminService>().getStats());
        await _future;
      },
      child: CustomScrollView(
        slivers: [
          const SliverToBoxAdapter(
            child: PageHeader(
              title: 'لوحة الإدارة',
              subtitle: 'مراقبة التواصل المدرسي',
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: FutureBuilder<AdminStats>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                if (snapshot.hasError) {
                  return SliverFillRemaining(
                    child: Center(child: Text(snapshot.error.toString())),
                  );
                }
                final stats = snapshot.data!;
                return SliverList(
                  delegate: SliverChildListDelegate([
                    FadeSlideIn(
                      child: GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 1.1,
                        children: [
                          StatCard(
                            title: 'المحادثات',
                            value: '${stats.totalConversations}',
                            icon: Icons.forum_rounded,
                            color: AppColors.primary,
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const AdminConversationsScreen(),
                              ),
                            ),
                          ),
                          StatCard(
                            title: 'الرسائل',
                            value: '${stats.totalMessages}',
                            icon: Icons.chat_rounded,
                            color: AppColors.secondary,
                          ),
                          StatCard(
                            title: 'الإعلانات',
                            value: '${stats.totalAnnouncements}',
                            icon: Icons.campaign_rounded,
                            color: AppColors.accent,
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const AdminAnnouncementsScreen(),
                              ),
                            ),
                          ),
                          StatCard(
                            title: 'إشعارات غير مقروءة',
                            value: '${stats.unreadNotifications}',
                            icon: Icons.notifications_active_rounded,
                            color: AppColors.danger,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    const SectionHeader(title: 'إجراءات سريعة'),
                    const SizedBox(height: 12),
                    AppCard(
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const AdminConversationsScreen(),
                        ),
                      ),
                      child: const ListTile(
                        leading: Icon(Icons.manage_search_rounded, color: AppColors.primary),
                        title: Text('مراجعة المحادثات', style: TextStyle(fontWeight: FontWeight.w700)),
                        subtitle: Text('بحث وفلترة حسب معلم / ولي أمر / صف'),
                        trailing: Icon(Icons.chevron_left_rounded),
                      ),
                    ),
                    const SizedBox(height: 10),
                    AppCard(
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const AdminAnnouncementsScreen(),
                        ),
                      ),
                      child: const ListTile(
                        leading: Icon(Icons.campaign_rounded, color: AppColors.accent),
                        title: Text('جميع الإعلانات', style: TextStyle(fontWeight: FontWeight.w700)),
                        subtitle: Text('مراجعة الإعلانات المرسلة للمدرسة'),
                        trailing: Icon(Icons.chevron_left_rounded),
                      ),
                    ),
                    const SizedBox(height: 10),
                    AppCard(
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const AdminParentAccountsScreen(),
                        ),
                      ),
                      child: const ListTile(
                        leading: Icon(Icons.family_restroom_rounded, color: AppColors.primary),
                        title: Text('حسابات أولياء الأمور', style: TextStyle(fontWeight: FontWeight.w700)),
                        subtitle: Text('عرض وإدارة حسابات الأب والأم'),
                        trailing: Icon(Icons.chevron_left_rounded),
                      ),
                    ),
                    const SizedBox(height: 10),
                    AppCard(
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const AdminTicketsScreen(),
                        ),
                      ),
                      child: const ListTile(
                        leading: Icon(Icons.support_agent_rounded, color: AppColors.warning),
                        title: Text('شكاوى ومقترحات أولياء الأمور', style: TextStyle(fontWeight: FontWeight.w700)),
                        subtitle: Text('مراجعة التذاكر والرد عليها'),
                        trailing: Icon(Icons.chevron_left_rounded),
                      ),
                    ),
                    const SizedBox(height: 10),
                    AppCard(
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const AdminParentIdValidationScreen(),
                        ),
                      ),
                      child: const ListTile(
                        leading: Icon(Icons.verified_user_outlined, color: AppColors.danger),
                        title: Text('مركز التحقق من الأرقام القومية', style: TextStyle(fontWeight: FontWeight.w700)),
                        subtitle: Text('تصحيح أرقام قومية غير صالحة وإنشاء الحسابات'),
                        trailing: Icon(Icons.chevron_left_rounded),
                      ),
                    ),
                  ]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
