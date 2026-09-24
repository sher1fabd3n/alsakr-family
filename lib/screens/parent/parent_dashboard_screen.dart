import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/fade_slide_in.dart';
import '../../core/widgets/section_header.dart';
import '../../core/widgets/stat_card.dart';
import '../../features/transportation/models/transportation_models.dart';
import '../../features/transportation/screens/live_tracking_screen.dart';
import '../../features/transportation/screens/parent_trip_history_screen.dart';
import '../../features/transportation/screens/transportation_dashboard_screen.dart';
import '../../features/transportation/services/transportation_service.dart';
import '../auth/login_screen.dart';

class ParentDashboardScreen extends StatefulWidget {
  const ParentDashboardScreen({super.key});

  @override
  State<ParentDashboardScreen> createState() => _ParentDashboardScreenState();
}

class _ParentDashboardScreenState extends State<ParentDashboardScreen> {
  late Future<List<ParentChildTransport>> _childrenFuture;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _childrenFuture = context.read<TransportationService>().getParentChildren();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          setState(_load);
          await _childrenFuture;
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: PageHeader(
                title: 'لوحة ولي الأمر',
                subtitle: 'متابعة أبنائك في مكان واحد',
                trailing: IconButton(
                  onPressed: () {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                      (_) => false,
                    );
                  },
                  icon: const Icon(Icons.logout_rounded, color: Colors.white),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.all(20),
              sliver: FutureBuilder<List<ParentChildTransport>>(
                future: _childrenFuture,
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

                  final children = snapshot.data ?? [];
                  if (children.isEmpty) {
                    return const SliverFillRemaining(
                      child: Center(child: Text('لا يوجد أبناء مرتبطون بحسابك.')),
                    );
                  }

                  return SliverList(
                    delegate: SliverChildListDelegate([
                      FadeSlideIn(
                        child: AppCard(
                          gradient: const LinearGradient(colors: AppColors.gradientPrimary),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('نظرة عامة', style: TextStyle(color: Colors.white70)),
                                    const SizedBox(height: 8),
                                    Text(
                                      '${children.length} أبناء مسجلين',
                                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w800,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.insights_rounded, color: Colors.white, size: 36),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const SectionHeader(title: 'أبنائي'),
                      const SizedBox(height: 12),
                      ...children.asMap().entries.map((entry) {
                        final index = entry.key;
                        final child = entry.value;
                        return FadeSlideIn(
                          delay: Duration(milliseconds: 80 * index),
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            child.name,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w800,
                                              fontSize: 17,
                                            ),
                                          ),
                                          Text(
                                            '${child.grade} • جلوس ${child.rollNo}',
                                            style: const TextStyle(color: AppColors.textSecondary),
                                          ),
                                        ],
                                      ),
                                    ),
                                    _TransportBadge(child: child),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                GridView.count(
                                  crossAxisCount: 2,
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  mainAxisSpacing: 12,
                                  crossAxisSpacing: 12,
                                  childAspectRatio: 1.15,
                                  children: [
                                    StatCard(
                                      title: 'بطاقة النقل',
                                      value: child.transportationTypeAr,
                                      subtitle: 'عرض وطباعة',
                                      icon: Icons.badge_rounded,
                                      color: child.isSchoolBus
                                          ? AppColors.success
                                          : const Color(0xFF2563EB),
                                      onTap: () => Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) => TransportationDashboardScreen(
                                            studentId: child.studentId,
                                          ),
                                        ),
                                      ),
                                    ),
                                    if (child.isSchoolBus)
                                      StatCard(
                                        title: 'تتبع مباشر',
                                        value: 'مباشر',
                                        subtitle: 'خريطة وETA',
                                        icon: Icons.map_rounded,
                                        color: const Color(0xFF1E3A8A),
                                        onTap: () => Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (_) => LiveTrackingScreen(
                                              studentId: child.studentId,
                                            ),
                                          ),
                                        ),
                                      )
                                    else
                                      StatCard(
                                        title: 'بيانات السائق',
                                        value: 'خاص',
                                        subtitle: 'تحديث المركبة',
                                        icon: Icons.directions_car_rounded,
                                        color: const Color(0xFF2563EB),
                                        onTap: () => Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (_) => TransportationDashboardScreen(
                                              studentId: child.studentId,
                                            ),
                                          ),
                                        ),
                                      ),
                                    StatCard(
                                      title: 'الإشعارات',
                                      value: 'النقل',
                                      subtitle: 'سجل الإشعارات',
                                      icon: Icons.notifications_active_rounded,
                                      color: AppColors.accent,
                                      onTap: () => Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) => TransportationDashboardScreen(
                                            studentId: child.studentId,
                                          ),
                                        ),
                                      ),
                                    ),
                                    StatCard(
                                      title: 'سجل الرحلات',
                                      value: 'تاريخ',
                                      subtitle: 'صعود ونزول',
                                      icon: Icons.history_rounded,
                                      color: AppColors.secondary,
                                      onTap: () => Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) => ParentTripHistoryScreen(studentId: child.studentId),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
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

class _TransportBadge extends StatelessWidget {
  const _TransportBadge({required this.child});

  final ParentChildTransport child;

  @override
  Widget build(BuildContext context) {
    if (!child.isSchoolBus && !child.isPrivate) {
      return const SizedBox.shrink();
    }
    final isBus = child.isSchoolBus;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: (isBus ? AppColors.success : const Color(0xFF2563EB)).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        child.transportationTypeAr,
        style: TextStyle(
          color: isBus ? AppColors.success : const Color(0xFF2563EB),
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}
