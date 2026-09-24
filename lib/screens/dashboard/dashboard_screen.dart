import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/fade_slide_in.dart';
import '../../core/widgets/section_header.dart';
import '../../core/widgets/stat_card.dart';
import '../../data/mock_content.dart';
import '../../models/student_models.dart';
import '../../services/student_services.dart';
import '../../utils/score_format.dart';
import '../../features/transportation/screens/transportation_dashboard_screen.dart';
import '../../features/transportation/widgets/student_transport_summary_card.dart';
import '../attendance/attendance_screen.dart';
import '../grades/grades_screen.dart';
import '../homework/homework_screen.dart';
import '../notifications/notifications_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late Future<StudentResultsResponse> _resultsFuture;
  late Future<StudentFeesResponse> _feesFuture;

  @override
  void initState() {
    super.initState();
    final service = context.read<StudentService>();
    _resultsFuture = service.getResults();
    _feesFuture = service.getFees();
  }

  double _average(List<StudentResult> results) {
    if (results.isEmpty) return 0;
    final total = results.fold<double>(0, (sum, r) => sum + r.percentage);
    return total / results.length;
  }

  @override
  Widget build(BuildContext context) {
    final student = context.watch<AuthService>().currentStudent;
    final homework = MockContent.homeworkItems();
    final pendingHomework =
        homework.where((h) => h.status != 'مكتمل').length;

    return RefreshIndicator(
      onRefresh: () async {
        final service = context.read<StudentService>();
        setState(() {
          _resultsFuture = service.getResults();
          _feesFuture = service.getFees();
        });
        await Future.wait([_resultsFuture, _feesFuture]);
      },
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: PageHeader(
              title: 'أهلاً ${student?.name.split(' ').first ?? 'بك'} 👋',
              subtitle: student == null
                  ? 'لوحة الطالب'
                  : 'الصف ${student.grade} • رقم الجلوس ${student.rollNo}',
              trailing: CircleAvatar(
                radius: 26,
                backgroundColor: Colors.white.withValues(alpha: 0.2),
                backgroundImage: student?.profilePhotoUrl != null
                    ? NetworkImage(student!.profilePhotoUrl!)
                    : null,
                child: student?.profilePhotoUrl == null
                    ? Text(
                        student?.name.isNotEmpty == true
                            ? student!.name[0]
                            : 'ط',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : null,
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                FutureBuilder<StudentResultsResponse>(
                  future: _resultsFuture,
                  builder: (context, snapshot) {
                    final results = snapshot.data?.results ?? [];
                    final average = _average(results);
                    return FadeSlideIn(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final width = constraints.maxWidth;
                          final crossCount = width > 700 ? 4 : 2;
                          return GridView.count(
                            crossAxisCount: crossCount,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            childAspectRatio: 1.05,
                            children: [
                              StatCard(
                                title: 'المعدل العام',
                                value: '${formatScore(average)}%',
                                subtitle: 'من النتائج الحالية',
                                icon: Icons.trending_up_rounded,
                                color: AppColors.primary,
                                onTap: () => _openGrades(context),
                              ),
                              StatCard(
                                title: 'المواد',
                                value: '${results.length}',
                                subtitle: 'نتائج مسجلة',
                                icon: Icons.menu_book_rounded,
                                color: AppColors.secondary,
                                onTap: () => _openGrades(context),
                              ),
                              StatCard(
                                title: 'الواجبات',
                                value: '$pendingHomework',
                                subtitle: 'قيد التنفيذ',
                                icon: Icons.assignment_rounded,
                                color: AppColors.accent,
                                onTap: () => _openHomework(context),
                              ),
                              StatCard(
                                title: 'الحضور',
                                value: '94%',
                                subtitle: 'هذا الشهر',
                                icon: Icons.event_available_rounded,
                                color: AppColors.success,
                                onTap: () => Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => const AttendanceScreen(),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    );
                  },
                ),
                const SizedBox(height: 24),
                FadeSlideIn(
                  delay: const Duration(milliseconds: 140),
                  child: const SectionHeader(title: 'بطاقة النقل'),
                ),
                const SizedBox(height: 12),
                const FadeSlideIn(
                  delay: Duration(milliseconds: 180),
                  child: StudentTransportSummaryCard(),
                ),
                const SizedBox(height: 24),
                FadeSlideIn(
                  delay: const Duration(milliseconds: 200),
                  child: const SectionHeader(title: 'إجراءات سريعة'),
                ),
                const SizedBox(height: 12),
                FadeSlideIn(
                  delay: const Duration(milliseconds: 120),
                  child: SizedBox(
                    height: 112,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        _QuickAction(
                          label: 'الدرجات',
                          icon: Icons.bar_chart_rounded,
                          colors: AppColors.gradientPrimary,
                          onTap: () => _openGrades(context),
                        ),
                        _QuickAction(
                          label: 'الواجبات',
                          icon: Icons.edit_note_rounded,
                          colors: AppColors.gradientCool,
                          onTap: () => _openHomework(context),
                        ),
                        _QuickAction(
                          label: 'النقل',
                          icon: Icons.directions_bus_rounded,
                          colors: const [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const TransportationDashboardScreen(),
                            ),
                          ),
                        ),
                        _QuickAction(
                          label: 'الإشعارات',
                          icon: Icons.notifications_active_rounded,
                          colors: AppColors.gradientWarm,
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const NotificationsScreen(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                FadeSlideIn(
                  delay: const Duration(milliseconds: 160),
                  child: const SectionHeader(title: 'آخر النتائج'),
                ),
                const SizedBox(height: 12),
                FutureBuilder<StudentResultsResponse>(
                  future: _resultsFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final results = snapshot.data?.results.take(4).toList() ?? [];
                    if (results.isEmpty) {
                      return const AppCard(
                        child: Text('لا توجد نتائج حالياً'),
                      );
                    }
                    return Column(
                      children: results
                          .map(
                            (r) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: AppCard(
                                child: Row(
                                  children: [
                                    Container(
                                      width: 48,
                                      height: 48,
                                      decoration: BoxDecoration(
                                        color: AppColors.primary.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      child: const Icon(
                                        Icons.translate_rounded,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            r.subject,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                          Text(
                                            r.month,
                                            style: const TextStyle(
                                              color: AppColors.textSecondary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Text(
                                      formatScorePair(r.totalMark, r.totalMaxMark),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    );
                  },
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  void _openGrades(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const GradesScreen()),
    );
  }

  void _openHomework(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const HomeworkScreen()),
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.label,
    required this.icon,
    required this.colors,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final List<Color> colors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 12),
      child: AppCard(
        onTap: onTap,
        gradient: LinearGradient(colors: colors),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        child: SizedBox(
          width: 120,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: Colors.white),
              const Spacer(),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
