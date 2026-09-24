class FamilyQuizSummary {
  final int id;
  final String title;
  final String subjectName;
  final String teacherName;
  final int totalPoints;
  final int timeLimitMinutes;
  final int questionCount;

  const FamilyQuizSummary({
    required this.id,
    required this.title,
    required this.subjectName,
    required this.teacherName,
    required this.totalPoints,
    required this.timeLimitMinutes,
    required this.questionCount,
  });

  factory FamilyQuizSummary.fromJson(Map<String, dynamic> json) {
    return FamilyQuizSummary(
      id: json['id'] as int,
      title: json['title'] as String? ?? '',
      subjectName: json['subjectName'] as String? ?? '',
      teacherName: json['teacherName'] as String? ?? '',
      totalPoints: json['totalPoints'] as int? ?? 0,
      timeLimitMinutes: json['timeLimitMinutes'] as int? ?? 30,
      questionCount: json['questionCount'] as int? ?? 0,
    );
  }
}

class FamilyQuizQuestion {
  final int id;
  final String questionText;
  final int points;
  final String questionType;
  final List<FamilyQuizAnswer> answers;

  const FamilyQuizQuestion({
    required this.id,
    required this.questionText,
    required this.points,
    required this.questionType,
    required this.answers,
  });

  bool get isEssay => questionType == 'Essay';
  bool get isTrueFalse => questionType == 'TrueFalse';

  factory FamilyQuizQuestion.fromJson(Map<String, dynamic> json) {
    final answers = (json['answers'] as List<dynamic>? ?? [])
        .map((e) => FamilyQuizAnswer.fromJson(e as Map<String, dynamic>))
        .toList();
    return FamilyQuizQuestion(
      id: json['id'] as int,
      questionText: json['questionText'] as String? ?? '',
      points: json['points'] as int? ?? 1,
      questionType: json['questionType'] as String? ?? 'MultipleChoice',
      answers: answers,
    );
  }
}

class FamilyQuizAnswer {
  final int id;
  final String answerText;

  const FamilyQuizAnswer({
    required this.id,
    required this.answerText,
  });

  factory FamilyQuizAnswer.fromJson(Map<String, dynamic> json) {
    return FamilyQuizAnswer(
      id: json['id'] as int,
      answerText: json['answerText'] as String? ?? '',
    );
  }
}

class FamilyQuizResult {
  final int attemptId;
  final String title;
  final int totalPoints;
  final int earnedPoints;
  final double percentage;
  final int totalQuestions;
  final int correctAnswers;

  const FamilyQuizResult({
    required this.attemptId,
    required this.title,
    required this.totalPoints,
    required this.earnedPoints,
    required this.percentage,
    required this.totalQuestions,
    required this.correctAnswers,
  });

  factory FamilyQuizResult.fromJson(Map<String, dynamic> json) {
    return FamilyQuizResult(
      attemptId: json['attemptId'] as int,
      title: json['title'] as String? ?? '',
      totalPoints: json['totalPoints'] as int? ?? 0,
      earnedPoints: json['earnedPoints'] as int? ?? 0,
      percentage: (json['percentage'] as num?)?.toDouble() ?? 0,
      totalQuestions: json['totalQuestions'] as int? ?? 0,
      correctAnswers: json['correctAnswers'] as int? ?? 0,
    );
  }
}

class FamilyScheduleResult {
  final String? imageUrl;
  final String? fileType;
  final List<FamilyScheduleDay> days;

  const FamilyScheduleResult({
    this.imageUrl,
    this.fileType,
    required this.days,
  });

  bool get hasFile => imageUrl != null && imageUrl!.isNotEmpty;
  bool get hasImage => hasFile && !isPdf;
  bool get isPdf {
    if (fileType?.toLowerCase() == 'pdf') return true;
    final clean = (imageUrl ?? '').split('?').first.toLowerCase();
    return clean.endsWith('.pdf');
  }
  bool get hasSlots => days.any((d) => d.slots.isNotEmpty);
}

class FamilyScheduleDay {
  final String dayName;
  final int dayOfWeek;
  final List<FamilyScheduleSlot> slots;

  const FamilyScheduleDay({
    required this.dayName,
    required this.dayOfWeek,
    required this.slots,
  });
}

class FamilyScheduleSlot {
  final int id;
  final String subjectName;
  final String teacherName;
  final String startTime;
  final String endTime;
  final String? roomName;

  const FamilyScheduleSlot({
    required this.id,
    required this.subjectName,
    required this.teacherName,
    required this.startTime,
    required this.endTime,
    this.roomName,
  });

  static String _formatTime(dynamic value) {
    final raw = value?.toString() ?? '';
    if (raw.length >= 5) return raw.substring(0, 5);
    return raw;
  }

  static int dayIndexFromJson(dynamic value) {
    if (value is int) return value;
    const map = {
      'Sunday': 0,
      'Monday': 1,
      'Tuesday': 2,
      'Wednesday': 3,
      'Thursday': 4,
      'Friday': 5,
      'Saturday': 6,
    };
    return map[value as String?] ?? 0;
  }

  factory FamilyScheduleSlot.fromJson(Map<String, dynamic> json) {
    return FamilyScheduleSlot(
      id: json['id'] as int,
      subjectName: json['subjectName'] as String? ?? '',
      teacherName: json['teacherName'] as String? ?? '',
      startTime: _formatTime(json['startTime']),
      endTime: _formatTime(json['endTime']),
      roomName: json['roomName'] as String?,
    );
  }
}

class FamilyEducationalVideo {
  final int id;
  final String title;
  final String? description;
  final String youtubeVideoId;
  final String subjectName;
  final DateTime createdAt;

  const FamilyEducationalVideo({
    required this.id,
    required this.title,
    this.description,
    required this.youtubeVideoId,
    required this.subjectName,
    required this.createdAt,
  });

  factory FamilyEducationalVideo.fromJson(Map<String, dynamic> json) {
    return FamilyEducationalVideo(
      id: json['id'] as int,
      title: json['title'] as String? ?? '',
      description: json['description'] as String?,
      youtubeVideoId: json['youtubeVideoId'] as String? ?? '',
      subjectName: json['subjectName'] as String? ?? '',
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
    );
  }
}
