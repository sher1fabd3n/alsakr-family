import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/widgets/app_card.dart';
import '../core/widgets/fade_slide_in.dart';
import '../core/widgets/section_header.dart';
import '../models/student_models.dart';
import '../utils/exam_result_groups.dart';
import '../utils/score_format.dart';

class ExamGroupedResultsView extends StatefulWidget {
  const ExamGroupedResultsView({super.key, required this.results});

  final List<StudentResult> results;

  @override
  State<ExamGroupedResultsView> createState() => _ExamGroupedResultsViewState();
}

class _ExamGroupedResultsViewState extends State<ExamGroupedResultsView> {
  String? _selectedKey;

  Color _gradeColor(String color) {
    switch (color) {
      case 'success':
        return AppColors.success;
      case 'primary':
        return AppColors.primary;
      case 'info':
        return AppColors.secondary;
      case 'warning':
        return AppColors.warning;
      case 'danger':
        return AppColors.danger;
      default:
        return AppColors.textMuted;
    }
  }

  @override
  Widget build(BuildContext context) {
    final groups = groupResultsByExam(widget.results);
    if (groups.isEmpty) {
      return const Center(child: Text('لا توجد نتائج مسجلة'));
    }

    final selected = groups.firstWhere(
      (group) => group.key == _selectedKey,
      orElse: () => groups.first,
    );
    final showYear = groups.map((group) => group.academicYear).toSet().length > 1;
    final chartWidth = math.max(320.0, selected.results.length * 56.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (groups.length > 1) ...[
          Text(
            'اختر الاختبار لعرض كل مواده',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final group in groups)
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: ChoiceChip(
                      label: Text(group.chipLabel(showYear: showYear)),
                      selected: group.key == selected.key,
                      showCheckmark: false,
                      avatar: Icon(
                        Icons.assignment_turned_in_rounded,
                        size: 18,
                        color: group.key == selected.key
                            ? Colors.white
                            : AppColors.primary,
                      ),
                      selectedColor: AppColors.primary,
                      labelStyle: TextStyle(
                        color: group.key == selected.key
                            ? Colors.white
                            : AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                      onSelected: (_) {
                        setState(() => _selectedKey = group.key);
                      },
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
        FadeSlideIn(
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
                colors: AppColors.gradientPrimary,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.18),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.insights_rounded, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        selected.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        [
                          if (selected.academicYear.isNotEmpty) selected.academicYear,
                          '${selected.results.length} مواد',
                          'المتوسط ${formatScore(selected.average)}%',
                        ].join(' • '),
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        FadeSlideIn(
          child: AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionHeader(title: 'مخطط أداء المواد'),
                const SizedBox(height: 16),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                    width: chartWidth,
                    height: 220,
                    child: BarChart(
                      BarChartData(
                        alignment: BarChartAlignment.spaceAround,
                        maxY: 100,
                        barGroups: [
                          for (var i = 0; i < selected.results.length; i++)
                            BarChartGroupData(
                              x: i,
                              barRods: [
                                BarChartRodData(
                                  toY: selected.results[i].percentage.clamp(0, 100),
                                  width: 18,
                                  borderRadius: BorderRadius.circular(8),
                                  gradient: const LinearGradient(
                                    begin: Alignment.bottomCenter,
                                    end: Alignment.topCenter,
                                    colors: AppColors.gradientPrimary,
                                  ),
                                ),
                              ],
                            ),
                        ],
                        titlesData: FlTitlesData(
                          topTitles: const AxisTitles(),
                          rightTitles: const AxisTitles(),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 30,
                              getTitlesWidget: (value, meta) => Text(
                                '${value.toInt()}',
                                style: const TextStyle(fontSize: 11),
                              ),
                            ),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                final index = value.toInt();
                                if (index < 0 || index >= selected.results.length) {
                                  return const SizedBox.shrink();
                                }
                                final label = selected.results[index].subject;
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Text(
                                    label.length > 8 ? '${label.substring(0, 8)}…' : label,
                                    style: const TextStyle(fontSize: 10),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: false,
                          getDrawingHorizontalLine: (value) => FlLine(
                            color: Colors.black.withValues(alpha: 0.05),
                            strokeWidth: 1,
                          ),
                        ),
                        borderData: FlBorderData(show: false),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        SectionHeader(title: 'مواد ${selected.title}'),
        const SizedBox(height: 12),
        ...selected.results.asMap().entries.map((entry) {
          final result = entry.value;
          return FadeSlideIn(
            delay: Duration(milliseconds: 50 * entry.key),
            child: Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            result.subject,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: _gradeColor(result.color).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            result.gradeText.isNotEmpty
                                ? result.gradeText
                                : '${formatScore(result.percentage)}%',
                            style: TextStyle(
                              color: _gradeColor(result.color),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${formatScore(result.percentage)}%',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 14),
                    if (result.hasMonthlyAssessment)
                      _ScoreLine(
                        label: 'التقييم الشهري',
                        value: result.isMonthlyAbsent
                            ? 'غائب'
                            : formatScore(result.monthlyAssessmentMark),
                      ),
                    if (!result.isMonthlyOnly)
                      _ScoreLine(
                        label: 'الاختبار',
                        value: result.isFirstTermAbsent
                            ? 'غائب'
                            : formatScore(result.firstTermExamMark),
                      ),
                    _ScoreLine(
                      label: 'المجموع',
                      value: formatScorePair(result.totalMark, result.totalMaxMark),
                      bold: true,
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }
}

class _ScoreLine extends StatelessWidget {
  const _ScoreLine({
    required this.label,
    required this.value,
    this.bold = false,
  });

  final String label;
  final String value;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
              color: bold ? AppColors.primary : AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
