class AdminStats {
  final int totalConversations;
  final int totalMessages;
  final int totalAnnouncements;
  final int unreadNotifications;

  const AdminStats({
    required this.totalConversations,
    required this.totalMessages,
    required this.totalAnnouncements,
    required this.unreadNotifications,
  });

  factory AdminStats.fromJson(Map<String, dynamic> json) => AdminStats(
        totalConversations: json['totalConversations'] as int? ?? 0,
        totalMessages: json['totalMessages'] as int? ?? 0,
        totalAnnouncements: json['totalAnnouncements'] as int? ?? 0,
        unreadNotifications: json['unreadNotifications'] as int? ?? 0,
      );
}

class AdminConversationSummary {
  final int id;
  final int studentId;
  final String studentName;
  final String studentGrade;
  final String teacherName;
  final String parentName;
  final String? lastMessagePreview;
  final DateTime? lastMessageAt;

  const AdminConversationSummary({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.studentGrade,
    required this.teacherName,
    required this.parentName,
    this.lastMessagePreview,
    this.lastMessageAt,
  });

  factory AdminConversationSummary.fromJson(Map<String, dynamic> json) =>
      AdminConversationSummary(
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
      );
}

class AdminProfile {
  final int id;
  final String fullName;
  final String userName;

  const AdminProfile({
    required this.id,
    required this.fullName,
    required this.userName,
  });

  factory AdminProfile.fromJson(Map<String, dynamic> json) => AdminProfile(
        id: json['id'] as int,
        fullName: json['fullName'] as String? ?? '',
        userName: json['userName'] as String? ?? '',
      );
}
