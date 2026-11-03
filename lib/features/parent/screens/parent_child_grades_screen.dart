import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/widgets/section_header.dart';
import '../../../models/student_models.dart';
import '../../../widgets/exam_grouped_results_view.dart';
import '../../../widgets/results_blocked_banner.dart';
import '../services/parent_family_service.dart';
import '../state/parent_child_context.dart';
import '../widgets/child_switcher.dart';

class ParentChildGradesScreen extends StatefulWidget {
  const ParentChildGradesScreen({super.key});

  @override
  State<ParentChildGradesScreen> createState() => _ParentChildGradesScreenState();
}

class _ParentChildGradesScreenState extends State<ParentChildGradesScreen> {
  int? _studentId;
  Future<StudentResultsResponse>? _future;

  @override
  Widget build(BuildContext context) {
    final activeId = context.watch<ParentChildContext>().activeStudentId;
    if (activeId != null && activeId != _studentId) {
      _studentId = activeId;
      _future = context.read<ParentFamilyService>().getChildResults(activeId);
    }

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          if (_studentId == null) return;
          setState(() {
            _future = context.read<ParentFamilyService>().getChildResults(_studentId!);
          });
          await _future;
        },
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: PageHeader(
                title: 'الدرجات والتقييم',
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
              sliver: FutureBuilder<StudentResultsResponse>(
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
                  if (data.blockedByAccounting || data.gradeResultsHidden || data.resultsBlocked) {
                    return SliverFillRemaining(
                      hasScrollBody: false,
                      child: Align(
                        alignment: Alignment.topCenter,
                        child: ResultsBlockedBanner(gradeHidden: data.gradeResultsHidden),
                      ),
                    );
                  }
                  if (data.results.isEmpty) {
                    return const SliverFillRemaining(child: Center(child: Text('لا توجد نتائج مسجلة')));
                  }

                  return SliverToBoxAdapter(
                    child: ExamGroupedResultsView(
                      key: ValueKey(_studentId),
                      results: data.results,
                    ),
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
