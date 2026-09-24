import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_card.dart';
import '../models/education_content_models.dart';
import '../services/education_content_service.dart';
import 'quiz_result_screen.dart';

class QuizTakeScreen extends StatefulWidget {
  const QuizTakeScreen({super.key, required this.quiz});

  final FamilyQuizSummary quiz;

  @override
  State<QuizTakeScreen> createState() => _QuizTakeScreenState();
}

class _QuizTakeScreenState extends State<QuizTakeScreen> {
  List<FamilyQuizQuestion> _questions = [];
  final Map<int, int> _selectedAnswers = {};
  final Map<int, TextEditingController> _essayControllers = {};
  bool _loading = true;
  bool _submitting = false;
  String? _error;
  int _currentIndex = 0;
  Timer? _timer;
  int _remainingSeconds = 0;
  int _attemptId = 0;

  @override
  void initState() {
    super.initState();
    _loadQuiz();
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final c in _essayControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _loadQuiz() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final service = context.read<EducationContentService>();
      final data = await service.startQuiz(widget.quiz.id);

      _attemptId = data['attemptId'] as int;
      final timeLimit = data['timeLimitMinutes'] as int? ?? widget.quiz.timeLimitMinutes;
      final questionsList = (data['questions'] as List<dynamic>? ?? [])
          .map((e) => FamilyQuizQuestion.fromJson(e as Map<String, dynamic>))
          .toList();

      if (!mounted) return;
      final essayControllers = <int, TextEditingController>{};
      for (final q in questionsList.where((q) => q.isEssay)) {
        essayControllers[q.id] = TextEditingController();
      }
      setState(() {
        _questions = questionsList;
        _essayControllers
          ..clear()
          ..addAll(essayControllers);
        _remainingSeconds = timeLimit * 60;
        _loading = false;
      });
      _startTimer();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_remainingSeconds <= 0) {
        timer.cancel();
        _submitQuiz();
        return;
      }
      setState(() => _remainingSeconds--);
    });
  }

  String get _timeDisplay {
    final m = _remainingSeconds ~/ 60;
    final s = _remainingSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  Color get _timeColor {
    if (_remainingSeconds > 300) return AppColors.success;
    if (_remainingSeconds > 60) return AppColors.warning;
    return AppColors.danger;
  }

  Future<void> _submitQuiz() async {
    _timer?.cancel();
    setState(() => _submitting = true);
    try {
      final service = context.read<EducationContentService>();
      final answerList = <Map<String, dynamic>>[];
      for (final q in _questions) {
        if (q.isEssay) {
          final text = _essayControllers[q.id]?.text.trim();
          if (text != null && text.isNotEmpty) {
            answerList.add({'questionId': q.id, 'textAnswer': text});
          }
        } else if (_selectedAnswers.containsKey(q.id)) {
          answerList.add({
            'questionId': q.id,
            'selectedAnswerId': _selectedAnswers[q.id],
          });
        }
      }
      final result = await service.submitQuiz(
        attemptId: _attemptId,
        answers: answerList,
      );
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => QuizResultScreen(result: result),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.quiz.title),
        actions: [
          Container(
            margin: const EdgeInsetsDirectional.only(end: 12),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _timeColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.timer_outlined, color: _timeColor, size: 18),
                const SizedBox(width: 6),
                Text(
                  _timeDisplay,
                  style: TextStyle(
                    color: _timeColor,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_error!),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadQuiz,
                        child: const Text('إعادة المحاولة'),
                      ),
                    ],
                  ),
                )
              : _buildQuizBody(),
    );
  }

  Widget _buildQuizBody() {
    if (_questions.isEmpty) {
      return const Center(child: Text('لا توجد أسئلة في هذا الكويز'));
    }

    final question = _questions[_currentIndex];
    final answeredCount = _questions.where((q) {
      if (q.isEssay) {
        return (_essayControllers[q.id]?.text.trim().isNotEmpty ?? false);
      }
      return _selectedAnswers.containsKey(q.id);
    }).length;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            children: [
              Text(
                'السؤال ${_currentIndex + 1} من ${_questions.length}',
                style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              Text(
                '$answeredCount/${_questions.length} مجاب',
                style: TextStyle(color: AppColors.textMuted, fontSize: 13),
              ),
            ],
          ),
        ),
        LinearProgressIndicator(
          value: (_currentIndex + 1) / _questions.length,
          backgroundColor: AppColors.surfaceMuted,
          color: AppColors.primary,
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppCard(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      question.questionText,
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${question.points} ${question.points == 1 ? 'درجة' : 'درجات'}',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                ),
                const SizedBox(height: 16),
                if (question.isEssay)
                  TextField(
                    controller: _essayControllers[question.id],
                    maxLines: 5,
                    decoration: const InputDecoration(
                      labelText: 'اكتب إجابتك',
                      border: OutlineInputBorder(),
                      alignLabelWithHint: true,
                    ),
                    onChanged: (_) => setState(() {}),
                  )
                else
                  ...question.answers.map((answer) {
                    final isSelected = _selectedAnswers[question.id] == answer.id;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: AppCard(
                        onTap: () {
                          setState(() {
                            _selectedAnswers[question.id] = answer.id;
                          });
                        },
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          children: [
                            Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.primary
                                    : AppColors.surfaceMuted,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: isSelected
                                      ? AppColors.primary
                                      : AppColors.textMuted.withValues(alpha: 0.3),
                                  width: 1.5,
                                ),
                              ),
                              child: isSelected
                                  ? const Icon(Icons.check, color: Colors.white, size: 16)
                                  : null,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                answer.answerText,
                                style: TextStyle(
                                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                  color: isSelected ? AppColors.primary : AppColors.textPrimary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
              ],
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _currentIndex > 0
                      ? () => setState(() => _currentIndex--)
                      : null,
                  child: const Text('السابق'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _submitting
                      ? null
                      : _currentIndex < _questions.length - 1
                          ? () => setState(() => _currentIndex++)
                          : () => _showConfirmSubmit(),
                  child: _submitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(
                          _currentIndex < _questions.length - 1 ? 'التالي' : 'إنهاء',
                        ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showConfirmSubmit() {
    final answeredCount = _questions.where((q) {
      if (q.isEssay) {
        return (_essayControllers[q.id]?.text.trim().isNotEmpty ?? false);
      }
      return _selectedAnswers.containsKey(q.id);
    }).length;
    final total = _questions.length;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد إنهاء الكويز'),
        content: Text(
          answeredCount < total
              ? 'لم تتم الإجابة على ${total - answeredCount} أسئلة. هل تريد الإنهاء؟'
              : 'تمت الإجابة على جميع الأسئلة. هل تريد الإنهاء؟',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('رجوع'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _submitQuiz();
            },
            child: const Text('إنهاء'),
          ),
        ],
      ),
    );
  }
}
