import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/fade_slide_in.dart';
import '../../core/widgets/section_header.dart';
import '../../data/mock_content.dart';

class AttendanceScreen extends StatelessWidget {
  const AttendanceScreen({super.key});

  Color _statusColor(String status) {
    switch (status) {
      case 'حاضر':
        return AppColors.success;
      case 'غائب':
        return AppColors.danger;
      default:
        return AppColors.warning;
    }
  }

  @override
  Widget build(BuildContext context) {
    final records = MockContent.attendanceRecords();
    final present = records.where((r) => r.status == 'حاضر').length;
    final rate = records.isEmpty ? 0 : (present / records.length) * 100;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: PageHeader(
              title: 'سجل الحضور',
              subtitle: 'متابعة حضورك في الحصص',
              trailing: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close_rounded, color: Colors.white),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
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
                              const Text(
                                'نسبة الحضور',
                                style: TextStyle(color: Colors.white70),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '${rate.toStringAsFixed(0)}%',
                                style: Theme.of(context)
                                    .textTheme
                                    .displaySmall
                                    ?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                    ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(
                            Icons.verified_rounded,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const SectionHeader(title: 'السجل الأخير'),
                const SizedBox(height: 12),
                ...records.asMap().entries.map((entry) {
                  final index = entry.key;
                  final record = entry.value;
                  final color = _statusColor(record.status);
                  return FadeSlideIn(
                    delay: Duration(milliseconds: 70 * index),
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: AppCard(
                        child: Row(
                          children: [
                            Container(
                              width: 54,
                              height: 54,
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    '${record.date.day}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      color: color,
                                    ),
                                  ),
                                  Text(
                                    '${record.date.month}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: color,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    record.subject,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    record.note,
                                    style: const TextStyle(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Chip(
                              label: Text(record.status),
                              backgroundColor: color.withValues(alpha: 0.12),
                              labelStyle: TextStyle(
                                color: color,
                                fontWeight: FontWeight.w700,
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
