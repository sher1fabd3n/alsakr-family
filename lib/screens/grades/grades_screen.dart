import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/widgets/section_header.dart';
import '../../models/student_models.dart';
import '../../services/student_services.dart';
import '../../widgets/exam_grouped_results_view.dart';
import '../../widgets/results_blocked_banner.dart';

class GradesScreen extends StatefulWidget {
  const GradesScreen({super.key});

  @override
  State<GradesScreen> createState() => _GradesScreenState();
}

class _GradesScreenState extends State<GradesScreen> {
  late Future<StudentResultsResponse> _future;

  @override
  void initState() {
    super.initState();
    _future = context.read<StudentService>().getResults();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() {
            _future = context.read<StudentService>().getResults();
          });
          await _future;
        },
        child: CustomScrollView(
          slivers: [
            const SliverToBoxAdapter(
              child: PageHeader(
                title: 'الدرجات والتقييم',
                subtitle: 'تابع أداءك في كل مادة داخل كل اختبار',
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
              sliver: FutureBuilder<StudentResultsResponse>(
                future: _future,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const SliverFillRemaining(
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  if (snapshot.hasError) {
                    return SliverFillRemaining(
                      child: Center(
                        child: Text(
                          snapshot.error.toString().replaceFirst('Exception: ', ''),
                        ),
                      ),
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
                    return const SliverFillRemaining(
                      child: Center(child: Text('لا توجد نتائج مسجلة')),
                    );
                  }

                  return SliverToBoxAdapter(
                    child: ExamGroupedResultsView(results: data.results),
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
