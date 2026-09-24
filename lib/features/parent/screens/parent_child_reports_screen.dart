import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/fade_slide_in.dart';
import '../../../core/widgets/section_header.dart';
import '../models/parent_family_models.dart';
import '../services/parent_family_service.dart';
import '../state/parent_child_context.dart';
import '../widgets/child_switcher.dart';
import 'parent_upload_report_screen.dart';

class ParentChildReportsScreen extends StatefulWidget {
  const ParentChildReportsScreen({super.key});

  @override
  State<ParentChildReportsScreen> createState() => _ParentChildReportsScreenState();
}

class _ParentChildReportsScreenState extends State<ParentChildReportsScreen> {
  int? _studentId;
  Future<List<ParentPublishedReport>>? _future;

  void _load(int studentId) {
    _studentId = studentId;
    _future = context.read<ParentFamilyService>().getChildReports(studentId);
  }

  Future<void> _openPdf(String url) async {
    final uri = Uri.parse(url);
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذر فتح المرفق')),
      );
    }
  }

  Future<void> _openUpload() async {
    if (_studentId == null) return;
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => ParentUploadReportScreen(studentId: _studentId!),
      ),
    );
    if (saved == true && mounted && _studentId != null) {
      setState(() => _load(_studentId!));
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeId = context.watch<ParentChildContext>().activeStudentId;
    if (activeId != null && activeId != _studentId) {
      _load(activeId);
    }

    return Scaffold(
      floatingActionButton: _studentId == null
          ? null
          : FloatingActionButton.extended(
              onPressed: _openUpload,
              icon: const Icon(Icons.upload_file_rounded),
              label: const Text('رفع تقرير'),
            ),
      body: RefreshIndicator(
        onRefresh: () async {
          if (_studentId == null) return;
          setState(() => _load(_studentId!));
          await _future;
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: PageHeader(
                title: 'التقارير',
                subtitle: context.watch<ParentChildContext>().activeChild?.name ?? 'تقارير المدرسة',
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
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              sliver: FutureBuilder<List<ParentPublishedReport>>(
                future: _future,
                builder: (context, snapshot) {
                  if (_studentId == null) {
                    return const SliverFillRemaining(
                      child: Center(child: Text('اختر ابناً أولاً')),
                    );
                  }
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const SliverFillRemaining(
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  if (snapshot.hasError) {
                    return SliverFillRemaining(
                      child: Center(
                        child: Text(snapshot.error.toString().replaceFirst('Exception: ', '')),
                      ),
                    );
                  }

                  final reports = snapshot.data ?? [];
                  final mine = reports.where((r) => r.isFromParent).toList();
                  final school = reports.where((r) => !r.isFromParent).toList();
                  if (reports.isEmpty) {
                    return const SliverFillRemaining(
                      child: Center(child: Text('لا توجد تقارير بعد. يمكنك رفع تقرير طبي أو أي تقرير يخص الطالب.')),
                    );
                  }

                  Widget cards(List<ParentPublishedReport> items, {int delay = 0}) {
                    return Column(
                      children: items.asMap().entries.map((entry) {
                        final report = entry.value;
                        return FadeSlideIn(
                          delay: Duration(milliseconds: delay + 40 * entry.key),
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _ReportCard(
                              report: report,
                              onOpenPdf: report.hasPdf ? () => _openPdf(report.pdfUrl!) : null,
                            ),
                          ),
                        );
                      }).toList(),
                    );
                  }

                  return SliverList(
                    delegate: SliverChildListDelegate([
                      if (mine.isNotEmpty) ...[
                        const SectionHeader(title: 'تقاريري المرسلة للإدارة'),
                        const SizedBox(height: 12),
                        cards(mine),
                        const SizedBox(height: 8),
                      ],
                      const SectionHeader(title: 'تقارير المدرسة'),
                      const SizedBox(height: 12),
                      if (school.isEmpty)
                        const Padding(
                          padding: EdgeInsets.only(bottom: 16),
                          child: Text('لا توجد تقارير منشورة من المدرسة حالياً'),
                        )
                      else
                        cards(school, delay: 40),
                      const SizedBox(height: 72),
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

class _ReportCard extends StatelessWidget {
  const _ReportCard({required this.report, this.onOpenPdf});

  final ParentPublishedReport report;
  final VoidCallback? onOpenPdf;

  @override
  Widget build(BuildContext context) {
    final date = DateFormat('yyyy/MM/dd').format(report.createdAt.toLocal());

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: AppColors.gradientPrimary),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  report.isImage
                      ? Icons.image_rounded
                      : report.hasPdf
                          ? Icons.picture_as_pdf_rounded
                          : Icons.description_rounded,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      report.title,
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      [
                        if (report.category != null && report.category!.isNotEmpty) report.category!,
                        report.isFromParent ? 'أرسلته للإدارة' : report.targetLabel,
                        date,
                      ].join(' • '),
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (report.hasBody) ...[
            const SizedBox(height: 16),
            Text(
              report.body!,
              style: const TextStyle(height: 1.55, fontSize: 15),
            ),
          ],
          if (onOpenPdf != null) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onOpenPdf,
                icon: const Icon(Icons.download_rounded),
                label: Text(report.pdfFileName?.isNotEmpty == true
                    ? 'فتح ${report.pdfFileName}'
                    : report.isImage
                        ? 'فتح الصورة'
                        : 'فتح المرفق'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
