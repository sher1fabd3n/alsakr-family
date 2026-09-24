import '../models/student_models.dart';

class ExamResultGroup {
  const ExamResultGroup({
    required this.academicYear,
    required this.month,
    required this.results,
  });

  final String academicYear;
  final String month;
  final List<StudentResult> results;

  String get key => '$academicYear|$month';

  String get title {
    if (month.trim().isEmpty) {
      return academicYear.isEmpty ? 'نتائج دراسية' : 'نتائج $academicYear';
    }
    return month.trim();
  }

  String chipLabel({required bool showYear}) {
    if (!showYear || academicYear.trim().isEmpty) return title;
    return '$title • $academicYear';
  }

  double get average {
    if (results.isEmpty) return 0;
    final total = results.fold<double>(0, (sum, item) => sum + item.percentage);
    return total / results.length;
  }
}

int examPeriodRank(String month) {
  final value = month.trim();
  if (value.contains('نهاية العام') || value.contains('آخر العام')) return 30;
  if (value.contains('منتصف العام')) return 20;
  if (value.contains('يوليو') || value.toLowerCase().contains('july')) return 7;
  if (value.contains('يونيو') || value.toLowerCase().contains('june')) return 6;
  if (value.contains('مايو') || value.toLowerCase().contains('may')) return 5;
  if (value.contains('أبريل') || value.contains('ابريل') || value.toLowerCase().contains('april')) {
    return 4;
  }
  if (value.contains('مارس') || value.toLowerCase().contains('march')) return 3;
  if (value.contains('فبراير') || value.toLowerCase().contains('february')) return 2;
  if (value.contains('يناير') || value.toLowerCase().contains('january')) return 1;
  if (value.contains('ديسمبر') || value.toLowerCase().contains('december')) return 12;
  if (value.contains('نوفمبر') || value.toLowerCase().contains('november')) return 11;
  if (value.contains('أكتوبر') || value.contains('اكتوبر') || value.toLowerCase().contains('october')) {
    return 10;
  }
  if (value.contains('سبتمبر') || value.toLowerCase().contains('september')) return 9;
  if (value.contains('أغسطس') || value.contains('اغسطس') || value.toLowerCase().contains('august')) {
    return 8;
  }
  return 10;
}

List<ExamResultGroup> groupResultsByExam(List<StudentResult> results) {
  final grouped = <String, List<StudentResult>>{};
  for (final result in results) {
    final key = '${result.academicYear}|${result.month}';
    grouped.putIfAbsent(key, () => []).add(result);
  }

  final exams = grouped.entries.map((entry) {
    final first = entry.value.first;
    final subjects = [...entry.value]
      ..sort((a, b) => a.subject.compareTo(b.subject));
    return ExamResultGroup(
      academicYear: first.academicYear,
      month: first.month,
      results: subjects,
    );
  }).toList();

  exams.sort((a, b) {
    final yearCompare = b.academicYear.compareTo(a.academicYear);
    if (yearCompare != 0) return yearCompare;
    final rankCompare = examPeriodRank(b.month).compareTo(examPeriodRank(a.month));
    if (rankCompare != 0) return rankCompare;
    return a.month.compareTo(b.month);
  });

  return exams;
}
