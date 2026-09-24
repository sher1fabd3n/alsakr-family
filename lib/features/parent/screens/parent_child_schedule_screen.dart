import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/fade_slide_in.dart';
import '../../../core/widgets/section_header.dart';
import '../state/parent_child_context.dart';

class ParentChildScheduleScreen extends StatelessWidget {
  const ParentChildScheduleScreen({super.key});

  static const _days = [
    'الأحد',
    'الإثنين',
    'الثلاثاء',
    'الأربعاء',
    'الخميس',
  ];

  @override
  Widget build(BuildContext context) {
    final childName = context.watch<ParentChildContext>().activeChild?.name;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: PageHeader(
              title: 'الجدول المدرسي',
              subtitle: childName ?? 'جدول الحصص الأسبوعي',
              trailing: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_forward_rounded, color: Colors.white),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                FadeSlideIn(
                  child: AppCard(
                    gradient: const LinearGradient(colors: AppColors.gradientPrimary),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'الجدول الأسبوعي',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'يعرض حصص اليوم الدراسي لكل يوم من أيام الأسبوع',
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.88)),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const SectionHeader(title: 'أيام الأسبوع'),
                const SizedBox(height: 12),
                for (var i = 0; i < _days.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: FadeSlideIn(
                      delay: Duration(milliseconds: 50 * i),
                      child: AppCard(
                        child: ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: CircleAvatar(
                            backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                            child: Text(
                              '${i + 1}',
                              style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w800),
                            ),
                          ),
                          title: Text(_days[i], style: const TextStyle(fontWeight: FontWeight.w800)),
                          subtitle: const Text(
                            'لم يتم رفع جدول الحصص بعد من إدارة المدرسة',
                            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                          ),
                        ),
                      ),
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
