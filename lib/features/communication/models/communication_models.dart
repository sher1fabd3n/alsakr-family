class ConversationItem {
  final int id;
  final int studentId;
  final String studentName;
  final String studentGrade;
  final String teacherName;
  final String parentName;
  final String? lastMessagePreview;
  final DateTime? lastMessageAt;
  final int unreadCount;

  const ConversationItem({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.studentGrade,
    required this.teacherName,
    required this.parentName,
    this.lastMessagePreview,
    this.lastMessageAt,
    required this.unreadCount,
  });

  factory ConversationItem.fromJson(Map<String, dynamic> json) => ConversationItem(
        id: json['id'] as int,
        studentId: json['studentId'] as int,
        studentName: json['studentName'] as String? ?? '',
        studentGrade: json['studentGrade'] as String? ?? '',
        teacherName: json['teacherName'] as String? ?? '',
        parentName: json['parentName'] as String? ?? '',
        lastMessagePreview: json['lastMessagePreview'] as String?,
        lastMessageAt: json['lastMessageAt'] != null
            ? DateTime.parse(json['lastMessageAt'] as String)
            : null,
        unreadCount: json['unreadCount'] as int? ?? 0,
      );
}

class ChatMessageItem {
  final int id;
  final int conversationId;
  final String senderRole;
  final int senderId;
  final String? body;
  final String contentType;
  final String deliveryStatus;
  final DateTime sentAt;
  final List<ChatAttachment> attachments;

  const ChatMessageItem({
    required this.id,
    required this.conversationId,
    required this.senderRole,
    required this.senderId,
    this.body,
    required this.contentType,
    required this.deliveryStatus,
    required this.sentAt,
    required this.attachments,
  });

  factory ChatMessageItem.fromJson(Map<String, dynamic> json) {
    final attachments = json['attachments'] as List<dynamic>? ?? [];
    return ChatMessageItem(
      id: (json['id'] as num).toInt(),
      conversationId: (json['conversationId'] as num).toInt(),
      senderRole: json['senderRole'] as String? ?? '',
      senderId: json['senderId'] as int? ?? 0,
      body: json['body'] as String?,
      contentType: json['contentType'] as String? ?? 'Text',
      deliveryStatus: json['deliveryStatus'] as String? ?? 'Sent',
      sentAt: DateTime.parse(json['sentAt'] as String),
      attachments: attachments
          .map((e) => ChatAttachment.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class ChatAttachment {
  final int id;
  final String fileName;
  final String contentType;
  final String url;
  final int fileSizeBytes;

  const ChatAttachment({
    required this.id,
    required this.fileName,
    required this.contentType,
    required this.url,
    required this.fileSizeBytes,
  });

  factory ChatAttachment.fromJson(Map<String, dynamic> json) => ChatAttachment(
        id: json['id'] as int,
        fileName: json['fileName'] as String? ?? '',
        contentType: json['contentType'] as String? ?? '',
        url: json['url'] as String? ?? '',
        fileSizeBytes: json['fileSizeBytes'] as int? ?? 0,
      );
}

class NotificationItem {
  final int id;
  final String title;
  final String body;
  final String type;
  final bool isRead;
  final DateTime createdAt;
  final int? conversationId;
  final String? referenceType;
  final int? referenceId;
  final int? studentId;

  const NotificationItem({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.isRead,
    required this.createdAt,
    this.conversationId,
    this.referenceType,
    this.referenceId,
    this.studentId,
  });

  factory NotificationItem.fromJson(Map<String, dynamic> json) => NotificationItem(
        id: (json['id'] as num).toInt(),
        title: json['title'] as String? ?? '',
        body: json['body'] as String? ?? '',
        type: json['type']?.toString() ?? '',
        isRead: json['isRead'] as bool? ?? false,
        createdAt: DateTime.parse(json['createdAt'] as String),
        conversationId: (json['conversationId'] as num?)?.toInt(),
        referenceType: json['referenceType'] as String?,
        referenceId: (json['referenceId'] as num?)?.toInt(),
        studentId: (json['studentId'] as num?)?.toInt(),
      );
}

class AnnouncementItem {
  final int id;
  final String title;
  final String body;
  final bool isEmergency;
  final DateTime? sentAt;

  const AnnouncementItem({
    required this.id,
    required this.title,
    required this.body,
    required this.isEmergency,
    this.sentAt,
  });

  factory AnnouncementItem.fromJson(Map<String, dynamic> json) => AnnouncementItem(
        id: json['id'] as int,
        title: json['title'] as String? ?? '',
        body: json['body'] as String? ?? '',
        isEmergency: json['isEmergency'] as bool? ?? false,
        sentAt: json['sentAt'] != null
            ? DateTime.parse(json['sentAt'] as String)
            : null,
      );
}

class TeacherOfClassItem {
  final int teacherAccountId;
  final String fullName;
  final String? jobTitle;
  final String? subjectName;

  const TeacherOfClassItem({
    required this.teacherAccountId,
    required this.fullName,
    this.jobTitle,
    this.subjectName,
  });

  String? get subtitle {
    final job = jobTitle?.trim();
    if (job != null && job.isNotEmpty) return job;
    return null;
  }

  factory TeacherOfClassItem.fromJson(Map<String, dynamic> json) =>
      TeacherOfClassItem(
        teacherAccountId: (json['teacherAccountId'] as num?)?.toInt() ?? 0,
        fullName: json['fullName'] as String? ?? '',
        jobTitle: json['jobTitle'] as String?,
        subjectName: json['subjectName'] as String?,
      );
}
