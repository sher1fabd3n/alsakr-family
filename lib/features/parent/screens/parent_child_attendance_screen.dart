import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/fade_slide_in.dart';
import '../../../core/widgets/section_header.dart';
import '../models/parent_family_models.dart';
import '../services/parent_family_service.dart';
import '../state/parent_child_context.dart';
import '../widgets/child_switcher.dart';

class ParentChildAttendanceScreen extends StatefulWidget {
  const ParentChildAttendanceScreen({super.key});

  @override
  State<ParentChildAttendanceScreen> createState() => _ParentChildAttendanceScreenState();
}

class _ParentChildAttendanceScreenState extends State<ParentChildAttendanceScreen> {
  int? _studentId;
  Future<ParentAttendanceSummary>? _future;

  Color _statusColor(String status) {
    if (status.contains('حاض') || status.toLowerCase() == 'present') return AppColors.success;
    if (status.contains('غائ') || status.toLowerCase() == 'absent') return AppColors.danger;
    return AppColors.warning;
  }

  @override
  Widget build(BuildContext context) {
    final activeId = context.watch<ParentChildContext>().activeStudentId;
    if (activeId != null && activeId != _studentId) {
      _studentId = activeId;
      _future = context.read<ParentFamilyService>().getChildAttendance(activeId);
    }

    final dateFormat = DateFormat('d MMM yyyy', 'ar');

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          if (_studentId == null) return;
          setState(() {
            _future = context.read<ParentFamilyService>().getChildAttendance(_studentId!);
          });
          await _future;
        },
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: PageHeader(
                title: 'سجل الحضور',
                subtitle: context.watch<ParentChildContext>().activeChild?.name,
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
              sliver: FutureBuilder<ParentAttendanceSummary>(
                future: _future,
                builder: (context, snapshot) {
                  if (_studentId == null) {
                    return const SliverFillRemaining(child: Center(child: Text('اختر ابناً أولاً')));
                  }
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const SliverFillRemaining(child: Center(child: CircularProgressIndicator()));
                  }
                  if (snapshot.hasError) {
                    return SliverFillRemaining(
                      child: Center(child: Text(snapshot.error.toString().replaceFirst('Exception: ', ''))),
                    );
                  }

                  final data = snapshot.data!;
                  final records = data.records;

                  return SliverList(
                    delegate: SliverChildListDelegate([
                      FadeSlideIn(
                        child: AppCard(
                          gradient: const LinearGradient(colors: AppColors.gradientCool),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('نسبة الحضور', style: TextStyle(color: Colors.white70)),
                                    const SizedBox(height: 6),
                                    Text(
                                      '${data.attendancePercentage.toStringAsFixed(0)}%',
                                      style: Theme.of(context).textTheme.displaySmall?.copyWith(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w800,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.verified_rounded, color: Colors.white, size: 36),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const SectionHeader(title: 'السجل الأخير'),
                      const SizedBox(height: 12),
                      if (records.isEmpty)
                        const Center(child: Text('لا توجد سجلات حضور'))
                      else
                        ...records.asMap().entries.map((entry) {
                          final record = entry.value;
                          final color = _statusColor(record.status);
                          return FadeSlideIn(
                            delay: Duration(milliseconds: 60 * entry.key),
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: AppCard(
                                child: Row(
                                  children: [
                                    Container(
                                      width: 10,
                                      height: 48,
                                      decoration: BoxDecoration(
                                        color: color,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(dateFormat.format(record.date),
                                              style: const TextStyle(fontWeight: FontWeight.w700)),
                                          if (record.tripType.isNotEmpty)
                                            Text(record.tripType,
                                                style: const TextStyle(color: AppColors.textSecondary)),
                                        ],
                                      ),
                                    ),
                                    Text(record.status, style: TextStyle(color: color, fontWeight: FontWeight.w800)),
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
