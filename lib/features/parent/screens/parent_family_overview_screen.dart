import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/fade_slide_in.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/student_avatar.dart';
import '../models/parent_family_models.dart';
import '../services/parent_family_service.dart';
import '../widgets/child_switcher.dart';

class ParentFamilyOverviewScreen extends StatefulWidget {
  const ParentFamilyOverviewScreen({super.key});

  @override
  State<ParentFamilyOverviewScreen> createState() => _ParentFamilyOverviewScreenState();
}

class _ParentFamilyOverviewScreenState extends State<ParentFamilyOverviewScreen> {
  late Future<FamilyDashboardSummary> _future;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _future = context.read<ParentFamilyService>().getFamilyOverview();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          setState(_load);
          await _future;
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: PageHeader(
                title: 'نظرة عامة للعائلة',
                subtitle: 'مؤشرات سريعة لكل الأبناء',
                trailing: IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_forward_rounded, color: Colors.white),
                ),
              ),
            ),
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(12, 0, 12, 8),
                child: ChildSwitcher(compact: true, height: 120),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.all(20),
              sliver: FutureBuilder<FamilyDashboardSummary>(
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

                  final children = snapshot.data!.children;
                  if (children.isEmpty) {
                    return const SliverFillRemaining(child: Center(child: Text('لا يوجد أبناء مرتبطون.')));
                  }

                  return SliverList(
                    delegate: SliverChildListDelegate([
                      _LegendRow(),
                      const SizedBox(height: 16),
                      ...children.asMap().entries.map((entry) {
                        final child = entry.value;
                        return FadeSlideIn(
                          delay: Duration(milliseconds: 60 * entry.key),
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 14),
                            child: _OverviewCard(child: child),
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

class _LegendRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      children: const [
        _LegendItem(color: AppColors.success, label: 'جيد'),
        _LegendItem(color: AppColors.accent, label: 'يحتاج متابعة'),
        _LegendItem(color: AppColors.danger, label: 'إجراء مطلوب'),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
      ],
    );
  }
}

class _OverviewCard extends StatelessWidget {
  const _OverviewCard({required this.child});

  final ChildDashboardSummary child;

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat('#,##0', 'ar');
    final statusColor = switch (child.statusIndicator) {
      ChildStatusIndicator.green => AppColors.success,
      ChildStatusIndicator.yellow => AppColors.accent,
      ChildStatusIndicator.red => AppColors.danger,
    };

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              StudentAvatar(
                studentId: child.studentId,
                name: child.name,
                photoUrl: child.profilePhotoUrl,
                radius: 22,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(child.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                    Text(child.grade, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  switch (child.statusIndicator) {
                    ChildStatusIndicator.green => 'جيد',
                    ChildStatusIndicator.yellow => 'متابعة',
                    ChildStatusIndicator.red => 'مطلوب',
                  },
                  style: TextStyle(color: statusColor, fontWeight: FontWeight.w700, fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const SectionHeader(title: 'ملخص سريع'),
          const SizedBox(height: 8),
          _MetricRow(
            icon: Icons.event_available_rounded,
            label: 'الحضور',
            value: '${child.attendancePercentage.toStringAsFixed(0)}%',
            color: child.attendancePercentage >= 85 ? AppColors.success : AppColors.accent,
          ),
          _MetricRow(
            icon: Icons.school_rounded,
            label: 'آخر امتحان',
            value: child.latestExamSubject != null
                ? '${child.latestExamSubject}: ${child.latestExamPercentage?.toStringAsFixed(0)}%'
                : '—',
            color: AppColors.primary,
          ),
          _MetricRow(
            icon: Icons.assignment_rounded,
            label: 'الواجبات',
            value: child.pendingHomeworkCount > 0 ? '${child.pendingHomeworkCount} معلّق' : 'مكتمل',
            color: child.pendingHomeworkCount > 0 ? AppColors.accent : AppColors.success,
          ),
          _MetricRow(
            icon: Icons.directions_bus_rounded,
            label: 'النقل',
            value: child.transportationTypeAr,
            color: AppColors.secondary,
          ),
          _MetricRow(
            icon: Icons.payments_rounded,
            label: 'المصاريف',
            value: child.outstandingFees > 0 ? 'متبقي ${currency.format(child.outstandingFees)}' : 'مسدّد',
            color: child.outstandingFees > 0 ? AppColors.danger : AppColors.success,
          ),
        ],
      ),
    );
  }
}

class _MetricRow extends StatelessWidget {
  const _MetricRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 10),
          Expanded(child: Text(label, style: const TextStyle(color: AppColors.textSecondary))),
          Text(value, style: TextStyle(fontWeight: FontWeight.w700, color: color)),
        ],
      ),
    );
  }
}
