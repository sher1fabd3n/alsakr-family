import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/section_header.dart';
import '../../core/widgets/fade_slide_in.dart';
import '../../data/mock_content.dart';

class HomeworkScreen extends StatelessWidget {
  const HomeworkScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final items = MockContent.homeworkItems();

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: PageHeader(
              title: 'الواجبات',
              subtitle: 'نظّم مهامك ولا تفوّت المواعيد',
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                ...items.asMap().entries.map((entry) {
                  final index = entry.key;
                  final item = entry.value;
                  return FadeSlideIn(
                    delay: Duration(milliseconds: 70 * index),
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: AppCard(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                color: item.color.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Icon(
                                Icons.assignment_turned_in_rounded,
                                color: item.color,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.title,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    item.subject,
                                    style: const TextStyle(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.schedule_rounded,
                                        size: 16,
                                        color: AppColors.textMuted,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        'التسليم: ${item.dueDate.day}/${item.dueDate.month}',
                                        style: const TextStyle(
                                          color: AppColors.textMuted,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Chip(
                              label: Text(item.status),
                              backgroundColor: item.color.withValues(alpha: 0.12),
                              labelStyle: TextStyle(
                                color: item.color,
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
