enum StudentTicketType { complaint, suggestion }

enum StudentTicketStatus { open, closed }

class StudentTicketSummary {
  const StudentTicketSummary({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.studentRollNo,
    this.studentGrade,
    required this.type,
    required this.title,
    required this.status,
    required this.hasNewReply,
    required this.createdAt,
    required this.updatedAt,
  });

  final int id;
  final int studentId;
  final String studentName;
  final int studentRollNo;
  final String? studentGrade;
  final StudentTicketType type;
  final String title;
  final StudentTicketStatus status;
  final bool hasNewReply;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory StudentTicketSummary.fromJson(Map<String, dynamic> json) => StudentTicketSummary(
        id: json['id'] as int,
        studentId: json['studentId'] as int,
        studentName: json['studentName'] as String? ?? '',
        studentRollNo: json['studentRollNo'] as int? ?? 0,
        studentGrade: json['studentGrade'] as String?,
        type: _parseType(json['type'] as String?),
        title: json['title'] as String? ?? '',
        status: json['status'] == 'closed' ? StudentTicketStatus.closed : StudentTicketStatus.open,
        hasNewReply: json['hasNewReply'] as bool? ?? false,
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
      );

  String get typeLabel => type == StudentTicketType.complaint ? 'شكوى' : 'مقترح';

  String get statusLabel => status == StudentTicketStatus.open ? 'مفتوحة' : 'مغلقة';
}

class StudentTicketMessage {
  const StudentTicketMessage({
    required this.id,
    required this.senderKind,
    this.senderName,
    required this.message,
    required this.createdAt,
  });

  final int id;
  final String senderKind;
  final String? senderName;
  final String message;
  final DateTime createdAt;

  factory StudentTicketMessage.fromJson(Map<String, dynamic> json) => StudentTicketMessage(
        id: json['id'] as int,
        senderKind: json['senderKind'] as String? ?? 'student',
        senderName: json['senderName'] as String?,
        message: json['message'] as String? ?? '',
        createdAt: DateTime.parse(json['createdAt'] as String),
      );

  bool get isAdmin => senderKind == 'admin';
}

class StudentTicketDetail extends StudentTicketSummary {
  const StudentTicketDetail({
    required super.id,
    required super.studentId,
    required super.studentName,
    required super.studentRollNo,
    super.studentGrade,
    required super.type,
    required super.title,
    required super.status,
    required super.hasNewReply,
    required super.createdAt,
    required super.updatedAt,
    required this.content,
    this.closedAt,
    this.closedByUserName,
    this.legacyAdminResponse,
    required this.messages,
  });

  final String content;
  final DateTime? closedAt;
  final String? closedByUserName;
  final String? legacyAdminResponse;
  final List<StudentTicketMessage> messages;

  factory StudentTicketDetail.fromJson(Map<String, dynamic> json) => StudentTicketDetail(
        id: json['id'] as int,
        studentId: json['studentId'] as int,
        studentName: json['studentName'] as String? ?? '',
        studentRollNo: json['studentRollNo'] as int? ?? 0,
        studentGrade: json['studentGrade'] as String?,
        type: _parseType(json['type'] as String?),
        title: json['title'] as String? ?? '',
        status: json['status'] == 'closed' ? StudentTicketStatus.closed : StudentTicketStatus.open,
        hasNewReply: json['hasNewReply'] as bool? ?? false,
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
        content: json['content'] as String? ?? '',
        closedAt: json['closedAt'] != null ? DateTime.parse(json['closedAt'] as String) : null,
        closedByUserName: json['closedByUserName'] as String?,
        legacyAdminResponse: json['legacyAdminResponse'] as String?,
        messages: (json['messages'] as List<dynamic>? ?? [])
            .map((e) => StudentTicketMessage.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class StudentTicketStats {
  const StudentTicketStats({required this.openCount, required this.unviewedCount});

  final int openCount;
  final int unviewedCount;

  factory StudentTicketStats.fromJson(Map<String, dynamic> json) => StudentTicketStats(
        openCount: json['openCount'] as int? ?? 0,
        unviewedCount: json['unviewedCount'] as int? ?? 0,
      );
}

StudentTicketType _parseType(String? value) =>
    value == 'suggestion' ? StudentTicketType.suggestion : StudentTicketType.complaint;

int ticketTypeToApi(StudentTicketType type) =>
    type == StudentTicketType.complaint ? 0 : 1;
