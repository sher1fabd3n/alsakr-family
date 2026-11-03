import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app_state.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/stat_card.dart';
import '../../transportation/screens/transportation_dashboard_screen.dart';
import '../../transportation/widgets/student_transport_summary_card.dart';
import '../models/parent_family_models.dart';
import '../state/parent_child_context.dart';
import '../widgets/child_switcher.dart';
import 'parent_child_attendance_screen.dart';
import 'parent_child_fees_screen.dart';
import 'parent_child_grades_screen.dart';
import 'parent_child_reports_screen.dart';
import '../../education/screens/educational_content_screen.dart';

class ParentChildHubScreen extends StatelessWidget {
  const ParentChildHubScreen({super.key, this.embedded = false});

  final bool embedded;

  @override
  Widget build(BuildContext context) {
    final ctx = context.watch<ParentChildContext>();
    final child = ctx.activeChild;

    final content = CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        if (!embedded)
          SliverToBoxAdapter(
            child: PageHeader(
              title: 'الرئيسية',
              subtitle: child?.name ?? 'اختر ابناً للمتابعة',
            ),
          ),
        if (!embedded)
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(12, 0, 12, 8),
              child: ChildSwitcher(compact: true, height: 120),
            ),
          ),
        if (ctx.isLoading && child == null)
          const SliverFillRemaining(child: Center(child: CircularProgressIndicator()))
        else if (ctx.error != null && child == null)
          SliverFillRemaining(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(ctx.error!, textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () => ctx.bootstrap(force: true),
                    child: const Text('إعادة المحاولة'),
                  ),
                ],
              ),
            ),
          )
        else if (ctx.children.isEmpty)
          SliverFillRemaining(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('لا يوجد أبناء مرتبطون بهذا الحساب.', textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () => ctx.bootstrap(force: true),
                    child: const Text('تحديث'),
                  ),
                ],
              ),
            ),
          )
        else if (child == null)
          SliverFillRemaining(
            child: Center(
              child: FilledButton(
                onPressed: () => ctx.bootstrap(force: true),
                child: const Text('عرض بيانات الأبناء'),
              ),
            ),
          )
        else
          SliverPadding(
            padding: EdgeInsets.all(embedded ? 16 : 20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                if (context.watch<AppState>().parentCanTransportation) ...[
                  const SectionHeader(title: 'بطاقة النقل'),
                  const SizedBox(height: 12),
                  StudentTransportSummaryCard(studentId: child.studentId),
                  const SizedBox(height: 20),
                ],
                const SectionHeader(title: 'الخدمات'),
                const SizedBox(height: 12),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.12,
                  children: _serviceCards(context, child),
                ),
              ]),
            ),
          ),
      ],
    );

    final scrollable = RefreshIndicator(
      onRefresh: () async {
        await ctx.refreshActiveChildData();
        await ctx.refreshFamily();
      },
      child: content,
    );

    if (embedded) return scrollable;
    return Scaffold(body: scrollable);
  }

  List<Widget> _serviceCards(BuildContext context, ChildDashboardSummary child) {
    final perms = context.watch<AppState>();
    return [
      if (perms.parentCanGrades)
        StatCard(
          title: 'الدرجات',
          icon: Icons.bar_chart_rounded,
          color: AppColors.primary,
          titleOnly: true,
          onTap: () => _open(context, const ParentChildGradesScreen()),
        ),
      if (perms.parentCanReports)
        StatCard(
          title: 'التقارير',
          icon: Icons.assessment_rounded,
          color: AppColors.accent,
          titleOnly: true,
          onTap: () => _open(context, const ParentChildReportsScreen()),
        ),
      if (perms.parentCanAttendance)
        StatCard(
          title: 'الحضور',
          icon: Icons.event_available_rounded,
          color: AppColors.success,
          titleOnly: true,
          onTap: () => _open(context, const ParentChildAttendanceScreen()),
        ),
      if (perms.parentCanFees)
        StatCard(
          title: 'المصاريف',
          icon: Icons.payments_rounded,
          color: AppColors.secondary,
          titleOnly: true,
          onTap: () => _open(context, const ParentChildFeesScreen()),
        ),
      if (perms.parentCanTransportation)
        StatCard(
          title: 'النقل',
          icon: Icons.directions_bus_rounded,
          color: const Color(0xFF2563EB),
          titleOnly: true,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => TransportationDashboardScreen(studentId: child.studentId),
            ),
          ),
        ),
      if (perms.parentCanEducation)
        StatCard(
          title: 'المنصة التعليمية',
          icon: Icons.menu_book_rounded,
          color: child.classId != null ? AppColors.secondary : AppColors.textMuted,
          titleOnly: true,
          onTap: child.classId != null
              ? () => _open(
                    context,
                    EducationalContentScreen(
                      studentId: child.studentId,
                      classId: child.classId!,
                      studentName: child.name,
                      academicYearId: child.academicYearId,
                    ),
                  )
              : () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'الطفل غير مسجل في فصل دراسي حالياً. يرجى تسجيل الطفل في فصل من الإدارة.',
                      ),
                      duration: Duration(seconds: 4),
                    ),
                  );
                },
        ),
    ];
  }

  void _open(BuildContext context, Widget screen) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }
}
