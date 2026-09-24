import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/fade_slide_in.dart';
import '../../../core/widgets/section_header.dart';
import '../models/education_content_models.dart';
import '../services/education_content_service.dart';
import 'quiz_take_screen.dart';
import 'video_player_screen.dart';

class EducationalContentScreen extends StatefulWidget {
  const EducationalContentScreen({
    super.key,
    required this.studentId,
    required this.classId,
    required this.studentName,
    this.academicYearId,
  });

  final int studentId;
  final int classId;
  final String studentName;
  final int? academicYearId;

  @override
  State<EducationalContentScreen> createState() => _EducationalContentScreenState();
}

class _EducationalContentScreenState extends State<EducationalContentScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: PageHeader(
              title: 'المنصة التعليمية',
              subtitle: widget.studentName,
              trailing: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_forward_rounded, color: Colors.white),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
              ),
              child: TabBar(
                controller: _tabController,
                labelColor: AppColors.primary,
                unselectedLabelColor: AppColors.textMuted,
                indicatorColor: AppColors.primary,
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                tabs: const [
                  Tab(icon: Icon(Icons.quiz_outlined), text: 'الكويزات'),
                  Tab(icon: Icon(Icons.calendar_month_rounded), text: 'الجدول'),
                  Tab(icon: Icon(Icons.play_circle_outline), text: 'الفيديوهات'),
                ],
              ),
            ),
          ),
          SliverFillRemaining(
            child: TabBarView(
              controller: _tabController,
              children: [
                _QuizzesTab(studentId: widget.studentId, classId: widget.classId),
                _ScheduleTab(
                  classId: widget.classId,
                  academicYearId: widget.academicYearId,
                ),
                _VideosTab(classId: widget.classId),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Quizzes Tab ─────────────────────────────────────────────────────

class _QuizzesTab extends StatefulWidget {
  const _QuizzesTab({required this.studentId, required this.classId});

  final int studentId;
  final int classId;

  @override
  State<_QuizzesTab> createState() => _QuizzesTabState();
}

class _QuizzesTabState extends State<_QuizzesTab> {
  List<FamilyQuizSummary> _quizzes = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final service = context.read<EducationContentService>();
      final quizzes = await service.getAvailableQuizzes(widget.classId);
      if (!mounted) return;
      setState(() {
        _quizzes = quizzes;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_error!),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _load, child: const Text('إعادة المحاولة')),
          ],
        ),
      );
    }
    if (_quizzes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.quiz_outlined, size: 64, color: AppColors.textMuted.withValues(alpha: 0.4)),
            const SizedBox(height: 16),
            Text('لا توجد كويزات متاحة', style: TextStyle(color: AppColors.textMuted)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: _quizzes.length,
        itemBuilder: (context, index) {
          final quiz = _quizzes[index];
          return FadeSlideIn(
            delay: Duration(milliseconds: 50 * index),
            child: Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: AppCard(
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => QuizTakeScreen(quiz: quiz),
                    ),
                  );
                  _load();
                },
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.quiz_outlined,
                        color: AppColors.primary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            quiz.title,
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${quiz.subjectName} | ${quiz.questionCount} أسئلة',
                            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                          ),
                          Text(
                            '${quiz.timeLimitMinutes} دقيقة | ${quiz.totalPoints} درجة',
                            style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_left_rounded, color: AppColors.textMuted),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ── Schedule Tab ────────────────────────────────────────────────────

class _ScheduleTab extends StatefulWidget {
  const _ScheduleTab({
    required this.classId,
    this.academicYearId,
  });

  final int classId;
  final int? academicYearId;

  @override
  State<_ScheduleTab> createState() => _ScheduleTabState();
}

class _ScheduleTabState extends State<_ScheduleTab> {
  FamilyScheduleResult? _schedule;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final service = context.read<EducationContentService>();
      final schedule = await service.getClassSchedule(
        widget.classId,
        academicYearId: widget.academicYearId,
      );
      if (!mounted) return;
      setState(() {
        _schedule = schedule;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  void _openFile(String url, {required bool isPdf}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => isPdf
            ? _SchedulePdfViewer(fileUrl: url)
            : _ScheduleImageViewer(imageUrl: url),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_error!),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _load, child: const Text('إعادة المحاولة')),
          ],
        ),
      );
    }

    final schedule = _schedule;
    final fileUrl = schedule?.imageUrl;
    final isPdf = schedule?.isPdf ?? false;
    final hasFile = fileUrl != null && fileUrl.isNotEmpty;
    final hasAnySlots = schedule?.hasSlots ?? false;
    if (!hasAnySlots && !hasFile) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.calendar_month_outlined, size: 56, color: AppColors.textMuted.withValues(alpha: 0.7)),
              const SizedBox(height: 16),
              const Text(
                'لم يتم رفع الجدول الدراسي بعد',
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
              ),
              const SizedBox(height: 8),
              Text(
                'سيتم عرض الجدول هنا بعد رفع صورة أو ملف PDF من لوحة تحكم الإدارة',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textMuted, fontSize: 13),
              ),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: _load, child: const Text('تحديث')),
            ],
          ),
        ),
      );
    }

    final days = schedule?.days ?? const <FamilyScheduleDay>[];
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          if (fileUrl != null && fileUrl.isNotEmpty) ...[
            AppCard(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'الجدول الدراسي',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                  ),
                  const SizedBox(height: 12),
                  if (isPdf)
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceMuted,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          const Icon(Icons.picture_as_pdf_rounded, size: 56, color: AppColors.danger),
                          const SizedBox(height: 8),
                          const Text(
                            'ملف PDF للجدول',
                            style: TextStyle(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 12),
                          FilledButton.icon(
                            onPressed: () => _openFile(fileUrl, isPdf: true),
                            icon: const Icon(Icons.visibility_rounded),
                            label: const Text('عرض الملف'),
                          ),
                        ],
                      ),
                    )
                  else ...[
                    GestureDetector(
                      onTap: () => _openFile(fileUrl, isPdf: false),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: CachedNetworkImage(
                          imageUrl: fileUrl,
                          fit: BoxFit.contain,
                          placeholder: (_, _) => const SizedBox(
                            height: 220,
                            child: Center(child: CircularProgressIndicator()),
                          ),
                          errorWidget: (_, _, _) => const SizedBox(
                            height: 180,
                            child: Center(child: Icon(Icons.broken_image_outlined, size: 48)),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: () => _openFile(fileUrl, isPdf: false),
                      icon: const Icon(Icons.zoom_in_rounded),
                      label: const Text('عرض أكبر / تكبير'),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          if (hasAnySlots)
            ...List.generate(days.length, (index) {
              final day = days[index];
              return FadeSlideIn(
                delay: Duration(milliseconds: 50 * index),
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 16,
                              backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                              child: Text(
                                '${index + 1}',
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              day.dayName,
                              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                            ),
                          ],
                        ),
                        if (day.slots.isEmpty) ...[
                          const SizedBox(height: 12),
                          Text(
                            'لا توجد حصص',
                            style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                          ),
                        ] else ...[
                          const SizedBox(height: 10),
                          ...day.slots.map(
                            (slot) => Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceMuted.withValues(alpha: 0.5),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 3,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      color: AppColors.primary,
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          slot.subjectName,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 14,
                                          ),
                                        ),
                                        Text(
                                          slot.teacherName,
                                          style: TextStyle(
                                            color: AppColors.textSecondary,
                                            fontSize: 12,
                                          ),
                                        ),
                                        if (slot.roomName != null && slot.roomName!.isNotEmpty)
                                          Text(
                                            'قاعة ${slot.roomName}',
                                            style: TextStyle(
                                              color: AppColors.textMuted,
                                              fontSize: 11,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    '${slot.startTime} - ${slot.endTime}',
                                    style: TextStyle(
                                      color: AppColors.textMuted,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }
}

class _ScheduleImageViewer extends StatelessWidget {
  const _ScheduleImageViewer({required this.imageUrl});

  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('الجدول الدراسي'),
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 0.8,
          maxScale: 5,
          child: CachedNetworkImage(
            imageUrl: imageUrl,
            fit: BoxFit.contain,
            placeholder: (_, _) => const CircularProgressIndicator(color: Colors.white),
            errorWidget: (_, _, _) => const Icon(Icons.broken_image_outlined, color: Colors.white, size: 56),
          ),
        ),
      ),
    );
  }
}

class _SchedulePdfViewer extends StatefulWidget {
  const _SchedulePdfViewer({required this.fileUrl});

  final String fileUrl;

  @override
  State<_SchedulePdfViewer> createState() => _SchedulePdfViewerState();
}

class _SchedulePdfViewerState extends State<_SchedulePdfViewer> {
  Future<Uint8List>? _bytesFuture;

  @override
  void initState() {
    super.initState();
    _bytesFuture = _download();
  }

  Future<Uint8List> _download() async {
    final response = await Dio().get<List<int>>(
      widget.fileUrl,
      options: Options(responseType: ResponseType.bytes),
    );
    return Uint8List.fromList(response.data ?? const []);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('الجدول الدراسي')),
      body: FutureBuilder<Uint8List>(
        future: _bytesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || snapshot.data == null || snapshot.data!.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  snapshot.hasError ? '${snapshot.error}' : 'تعذر فتح ملف الجدول.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          final bytes = snapshot.data!;
          return PdfPreview(
            build: (_) async => bytes,
            canChangePageFormat: false,
            canChangeOrientation: false,
            canDebug: false,
            allowPrinting: true,
            allowSharing: true,
            pdfFileName: 'study-schedule.pdf',
          );
        },
      ),
    );
  }
}

// ── Videos Tab ──────────────────────────────────────────────────────

class _VideosTab extends StatefulWidget {
  const _VideosTab({required this.classId});

  final int classId;

  @override
  State<_VideosTab> createState() => _VideosTabState();
}

class _VideosTabState extends State<_VideosTab> {
  List<FamilyEducationalVideo> _videos = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final service = context.read<EducationContentService>();
      final videos = await service.getClassVideos(widget.classId);
      if (!mounted) return;
      setState(() {
        _videos = videos;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_error!),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _load, child: const Text('إعادة المحاولة')),
          ],
        ),
      );
    }
    if (_videos.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.play_circle_outline, size: 64, color: AppColors.textMuted.withValues(alpha: 0.4)),
            const SizedBox(height: 16),
            Text('لا توجد فيديوهات بعد', style: TextStyle(color: AppColors.textMuted)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: _videos.length,
        itemBuilder: (context, index) {
          final video = _videos[index];
          return FadeSlideIn(
            delay: Duration(milliseconds: 50 * index),
            child: Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: AppCard(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => VideoPlayerScreen(video: video),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        height: 180,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: AppColors.surfaceMuted,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Image.network(
                              'https://img.youtube.com/vi/${video.youtubeVideoId}/mqdefault.jpg',
                              fit: BoxFit.cover,
                              width: double.infinity,
                              errorBuilder: (_, _, _) => Container(
                                color: AppColors.surfaceMuted,
                                child: Icon(Icons.play_circle_outline, size: 48, color: AppColors.textMuted),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.6),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 32),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      video.title,
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      video.subjectName,
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                    ),
                    if (video.description != null && video.description!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        video.description!,
                        style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
