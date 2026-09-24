import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_card.dart';
import '../models/education_content_models.dart';

class QuizResultScreen extends StatelessWidget {
  const QuizResultScreen({super.key, required this.result});

  final FamilyQuizResult result;

  Color get _resultColor {
    if (result.percentage >= 80) return AppColors.success;
    if (result.percentage >= 50) return AppColors.warning;
    return AppColors.danger;
  }

  String get _resultEmoji {
    if (result.percentage >= 90) return 'ممتاز!';
    if (result.percentage >= 75) return 'جيد جداً';
    if (result.percentage >= 50) return 'مقبول';
    return 'يحتاج تحسين';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 60, 20, 30),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                  colors: [
                    _resultColor.withValues(alpha: 0.15),
                    _resultColor.withValues(alpha: 0.05),
                  ],
                ),
              ),
              child: Column(
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: _resultColor.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      result.percentage >= 50
                          ? Icons.check_circle_outline
                          : Icons.info_outline,
                      color: _resultColor,
                      size: 52,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _resultEmoji,
                    style: TextStyle(
                      color: _resultColor,
                      fontWeight: FontWeight.w800,
                      fontSize: 22,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '${result.percentage.toStringAsFixed(1)}%',
                    style: TextStyle(
                      color: _resultColor,
                      fontWeight: FontWeight.w900,
                      fontSize: 40,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                AppCard(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          result.title,
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
                        ),
                        const SizedBox(height: 16),
                        _ResultRow(
                          icon: Icons.check_circle_outline,
                          color: AppColors.success,
                          label: 'إجابات صحيحة',
                          value: '${result.correctAnswers} / ${result.totalQuestions}',
                        ),
                        const SizedBox(height: 10),
                        _ResultRow(
                          icon: Icons.star_outline,
                          color: AppColors.primary,
                          label: 'الدرجات',
                          value: '${result.earnedPoints} / ${result.totalPoints}',
                        ),
                        const SizedBox(height: 10),
                        _ResultRow(
                          icon: Icons.percent_outlined,
                          color: AppColors.accent,
                          label: 'النسبة',
                          value: '${result.percentage.toStringAsFixed(1)}%',
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('العودة'),
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

class _ResultRow extends StatelessWidget {
  const _ResultRow({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final Color color;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(width: 10),
        Expanded(
          child: Text(label, style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
        ),
        Text(
          value,
          style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 15),
        ),
      ],
    );
  }
}
