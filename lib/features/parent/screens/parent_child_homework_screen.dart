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

class ParentChildHomeworkScreen extends StatefulWidget {
  const ParentChildHomeworkScreen({super.key});

  @override
  State<ParentChildHomeworkScreen> createState() => _ParentChildHomeworkScreenState();
}

class _ParentChildHomeworkScreenState extends State<ParentChildHomeworkScreen> {
  int? _studentId;
  Future<List<ParentHomeworkItem>>? _future;

  @override
  Widget build(BuildContext context) {
    final activeId = context.watch<ParentChildContext>().activeStudentId;
    if (activeId != null && activeId != _studentId) {
      _studentId = activeId;
      _future = context.read<ParentFamilyService>().getChildHomework(activeId);
    }

    final dateFormat = DateFormat('d MMM yyyy', 'ar');

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          if (_studentId == null) return;
          setState(() {
            _future = context.read<ParentFamilyService>().getChildHomework(_studentId!);
          });
          await _future;
        },
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: PageHeader(
                title: 'الواجبات',
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
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
              sliver: FutureBuilder<List<ParentHomeworkItem>>(
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

                  final items = snapshot.data ?? [];
                  if (items.isEmpty) {
                    return const SliverFillRemaining(child: Center(child: Text('لا توجد واجبات')));
                  }

                  return SliverList(
                    delegate: SliverChildListDelegate([
                      const SectionHeader(title: 'قائمة الواجبات'),
                      const SizedBox(height: 12),
                      ...items.asMap().entries.map((entry) {
                        final item = entry.value;
                        final color = item.isOverdue ? AppColors.danger : AppColors.primary;
                        return FadeSlideIn(
                          delay: Duration(milliseconds: 60 * entry.key),
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: AppCard(
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: color.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: Icon(Icons.assignment_rounded, color: color),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(item.title,
                                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                                        if (item.description.isNotEmpty) ...[
                                          const SizedBox(height: 6),
                                          Text(item.description,
                                              style: const TextStyle(color: AppColors.textSecondary)),
                                        ],
                                        const SizedBox(height: 8),
                                        Text(
                                          'التسليم: ${dateFormat.format(item.dueDate)}',
                                          style: TextStyle(
                                            color: item.isOverdue ? AppColors.danger : AppColors.textMuted,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
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
