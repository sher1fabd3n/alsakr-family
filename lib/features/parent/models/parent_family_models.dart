import '../../../models/student_models.dart';

enum ChildStatusIndicator { green, yellow, red }

enum TransportationChip { onBus, arrived, private, notAssigned }

enum AttendanceTrend { up, down, stable }

ChildStatusIndicator childStatusFromString(String? value) => switch (value?.toLowerCase()) {
      'red' => ChildStatusIndicator.red,
      'yellow' => ChildStatusIndicator.yellow,
      _ => ChildStatusIndicator.green,
    };

TransportationChip transportationChipFromString(String? value) => switch (value) {
      'OnBus' => TransportationChip.onBus,
      'Arrived' => TransportationChip.arrived,
      'Private' => TransportationChip.private,
      _ => TransportationChip.notAssigned,
    };

AttendanceTrend attendanceTrendFromString(String? value) => switch (value) {
      'Up' => AttendanceTrend.up,
      'Down' => AttendanceTrend.down,
      _ => AttendanceTrend.stable,
    };

String childPhotoHeroTag(int studentId) => 'child-photo-$studentId';

class ChildDashboardSummary {
  final int studentId;
  final String name;
  final int rollNo;
  final String grade;
  final String? profilePhotoUrl;
  final String transportationStatus;
  final String transportationTypeAr;
  final String? routeName;
  final String? busNumber;
  final double attendancePercentage;
  final String? latestExamSubject;
  final double? latestExamPercentage;
  final double outstandingFees;
  final int pendingHomeworkCount;
  final ChildStatusIndicator statusIndicator;
  final TransportationChip transportationChip;
  final int unreadNotificationCount;
  final AttendanceTrend attendanceTrend;
  final int? classId;
  final int? academicYearId;

  const ChildDashboardSummary({
    required this.studentId,
    required this.name,
    required this.rollNo,
    required this.grade,
    this.profilePhotoUrl,
    required this.transportationStatus,
    required this.transportationTypeAr,
    this.routeName,
    this.busNumber,
    required this.attendancePercentage,
    this.latestExamSubject,
    this.latestExamPercentage,
    required this.outstandingFees,
    required this.pendingHomeworkCount,
    required this.statusIndicator,
    this.transportationChip = TransportationChip.notAssigned,
    this.unreadNotificationCount = 0,
    this.attendanceTrend = AttendanceTrend.stable,
    this.classId,
    this.academicYearId,
  });

  factory ChildDashboardSummary.fromJson(Map<String, dynamic> json) => ChildDashboardSummary(
        studentId: (json['studentId'] as num?)?.toInt() ?? 0,
        name: json['name'] as String? ?? '',
        rollNo: (json['rollNo'] as num?)?.toInt() ?? 0,
        grade: json['grade'] as String? ?? '',
        profilePhotoUrl: json['profilePhotoUrl'] as String?,
        transportationStatus: json['transportationStatus'] as String? ?? '',
        transportationTypeAr: json['transportationTypeAr'] as String? ?? '',
        routeName: json['routeName'] as String?,
        busNumber: json['busNumber'] as String?,
        attendancePercentage: (json['attendancePercentage'] as num?)?.toDouble() ?? 0,
        latestExamSubject: json['latestExamSubject'] as String?,
        latestExamPercentage: (json['latestExamPercentage'] as num?)?.toDouble(),
        outstandingFees: (json['outstandingFees'] as num?)?.toDouble() ?? 0,
        pendingHomeworkCount: json['pendingHomeworkCount'] as int? ?? 0,
        statusIndicator: childStatusFromString(json['statusIndicator'] as String?),
        transportationChip: transportationChipFromString(json['transportationChip'] as String?),
        unreadNotificationCount: json['unreadNotificationCount'] as int? ?? 0,
        attendanceTrend: attendanceTrendFromString(json['attendanceTrend'] as String?),
        classId: json['classId'] as int?,
        academicYearId: json['academicYearId'] as int?,
      );

  ChildDashboardSummary copyWith({String? profilePhotoUrl}) => ChildDashboardSummary(
        studentId: studentId,
        name: name,
        rollNo: rollNo,
        grade: grade,
        profilePhotoUrl: profilePhotoUrl ?? this.profilePhotoUrl,
        transportationStatus: transportationStatus,
        transportationTypeAr: transportationTypeAr,
        routeName: routeName,
        busNumber: busNumber,
        attendancePercentage: attendancePercentage,
        latestExamSubject: latestExamSubject,
        latestExamPercentage: latestExamPercentage,
        outstandingFees: outstandingFees,
        pendingHomeworkCount: pendingHomeworkCount,
        statusIndicator: statusIndicator,
        transportationChip: transportationChip,
        unreadNotificationCount: unreadNotificationCount,
        attendanceTrend: attendanceTrend,
        classId: classId,
        academicYearId: academicYearId,
      );
}

class FamilyDashboardSummary {
  final int totalChildren;
  final int? activeStudentId;
  final List<ChildDashboardSummary> children;

  const FamilyDashboardSummary({
    required this.totalChildren,
    this.activeStudentId,
    required this.children,
  });

  factory FamilyDashboardSummary.fromJson(Map<String, dynamic> json) {
    final list = json['children'] as List<dynamic>? ?? [];
    return FamilyDashboardSummary(
      totalChildren: (json['totalChildren'] as num?)?.toInt() ?? list.length,
      activeStudentId: (json['activeStudentId'] as num?)?.toInt(),
      children: list.map((e) => ChildDashboardSummary.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }
}

class FamilyTransportationRoute {
  final String routeName;
  final String? busNumber;
  final String? driverName;
  final String? driverPhone;
  final String? supervisorName;
  final String? supervisorPhone;
  final List<FamilyTransportChild> children;

  const FamilyTransportationRoute({
    required this.routeName,
    this.busNumber,
    this.driverName,
    this.driverPhone,
    this.supervisorName,
    this.supervisorPhone,
    required this.children,
  });

  factory FamilyTransportationRoute.fromJson(Map<String, dynamic> json) {
    final list = json['children'] as List<dynamic>? ?? [];
    return FamilyTransportationRoute(
      routeName: json['routeName'] as String? ?? '',
      busNumber: json['busNumber'] as String?,
      driverName: json['driverName'] as String?,
      driverPhone: json['driverPhone'] as String?,
      supervisorName: json['supervisorName'] as String?,
      supervisorPhone: json['supervisorPhone'] as String?,
      children: list.map((e) => FamilyTransportChild.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }
}

class FamilyTransportChild {
  final int studentId;
  final String name;
  final String grade;

  const FamilyTransportChild({required this.studentId, required this.name, required this.grade});

  factory FamilyTransportChild.fromJson(Map<String, dynamic> json) => FamilyTransportChild(
        studentId: json['studentId'] as int,
        name: json['name'] as String? ?? '',
        grade: json['grade'] as String? ?? '',
      );
}

class FamilyTransportationSummary {
  final List<FamilyTransportationRoute> routes;
  final List<ChildDashboardSummary> privateTransportChildren;

  const FamilyTransportationSummary({required this.routes, required this.privateTransportChildren});

  factory FamilyTransportationSummary.fromJson(Map<String, dynamic> json) {
    final routes = (json['routes'] as List<dynamic>? ?? [])
        .map((e) => FamilyTransportationRoute.fromJson(e as Map<String, dynamic>))
        .toList();
    final priv = (json['privateTransportChildren'] as List<dynamic>? ?? [])
        .map((e) => ChildDashboardSummary.fromJson(e as Map<String, dynamic>))
        .toList();
    return FamilyTransportationSummary(routes: routes, privateTransportChildren: priv);
  }
}

class ParentHomeworkItem {
  final int id;
  final String title;
  final String description;
  final DateTime dueDate;
  final String grade;
  final bool isOverdue;

  const ParentHomeworkItem({
    required this.id,
    required this.title,
    required this.description,
    required this.dueDate,
    required this.grade,
    required this.isOverdue,
  });

  factory ParentHomeworkItem.fromJson(Map<String, dynamic> json) => ParentHomeworkItem(
        id: (json['id'] as num).toInt(),
        title: json['title'] as String? ?? '',
        description: json['description'] as String? ?? '',
        dueDate: DateTime.parse(json['dueDate'] as String),
        grade: json['grade'] as String? ?? '',
        isOverdue: json['isOverdue'] as bool? ?? false,
      );
}

class ParentAttendanceRecord {
  final DateTime date;
  final String status;
  final String tripType;

  const ParentAttendanceRecord({required this.date, required this.status, required this.tripType});

  factory ParentAttendanceRecord.fromJson(Map<String, dynamic> json) => ParentAttendanceRecord(
        date: DateTime.parse(json['date'] as String),
        status: json['status'] as String? ?? '',
        tripType: json['tripType'] as String? ?? '',
      );
}

class ParentAttendanceSummary {
  final int studentId;
  final double attendancePercentage;
  final List<ParentAttendanceRecord> records;

  const ParentAttendanceSummary({
    required this.studentId,
    required this.attendancePercentage,
    required this.records,
  });

  factory ParentAttendanceSummary.fromJson(Map<String, dynamic> json) {
    final list = json['records'] as List<dynamic>? ?? [];
    return ParentAttendanceSummary(
      studentId: json['studentId'] as int,
      attendancePercentage: (json['attendancePercentage'] as num?)?.toDouble() ?? 0,
      records: list.map((e) => ParentAttendanceRecord.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }
}

class ParentUnreadSummary {
  final int notifications;
  final int chats;
  final int total;

  const ParentUnreadSummary({
    required this.notifications,
    required this.chats,
    required this.total,
  });

  factory ParentUnreadSummary.fromJson(Map<String, dynamic> json) {
    final notifications = json['notifications'] as int? ?? 0;
    final chats = json['chats'] as int? ?? 0;
    return ParentUnreadSummary(
      notifications: notifications,
      chats: chats,
      total: json['total'] as int? ?? notifications + chats,
    );
  }
}

class ParentChildNotification {
  final int id;
  final String title;
  final String body;
  final bool isRead;
  final DateTime createdAt;
  final int? studentId;
  final String? studentName;
  final String? studentPhotoUrl;
  final int? conversationId;
  final String? type;
  final String? referenceType;
  final int? referenceId;

  const ParentChildNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.isRead,
    required this.createdAt,
    this.studentId,
    this.studentName,
    this.studentPhotoUrl,
    this.conversationId,
    this.type,
    this.referenceType,
    this.referenceId,
  });

  factory ParentChildNotification.fromJson(Map<String, dynamic> json) => ParentChildNotification(
        id: (json['id'] as num).toInt(),
        title: json['title'] as String? ?? '',
        body: json['body'] as String? ?? '',
        isRead: json['isRead'] as bool? ?? false,
        createdAt: _parseParentDateTime(json['createdAt']) ?? DateTime.now(),
        studentId: (json['studentId'] as num?)?.toInt(),
        studentName: json['studentName'] as String?,
        studentPhotoUrl: json['studentPhotoUrl'] as String?,
        conversationId: (json['conversationId'] as num?)?.toInt(),
        type: json['type']?.toString(),
        referenceType: json['referenceType'] as String?,
        referenceId: (json['referenceId'] as num?)?.toInt(),
      );
}

class ParentPublishedReport {
  final int id;
  final String title;
  final String? body;
  final String? pdfUrl;
  final String? pdfFileName;
  final String targetType;
  final String targetLabel;
  final String source;
  final bool isFromParent;
  final String? category;
  final String? createdByName;
  final DateTime createdAt;

  const ParentPublishedReport({
    required this.id,
    required this.title,
    this.body,
    this.pdfUrl,
    this.pdfFileName,
    required this.targetType,
    required this.targetLabel,
    this.source = 'Admin',
    this.isFromParent = false,
    this.category,
    this.createdByName,
    required this.createdAt,
  });

  bool get hasPdf => pdfUrl != null && pdfUrl!.isNotEmpty;
  bool get hasBody => body != null && body!.trim().isNotEmpty;
  bool get isImage {
    final name = (pdfFileName ?? pdfUrl ?? '').toLowerCase();
    return name.endsWith('.jpg') ||
        name.endsWith('.jpeg') ||
        name.endsWith('.png') ||
        name.endsWith('.webp');
  }

  factory ParentPublishedReport.fromJson(Map<String, dynamic> json) => ParentPublishedReport(
        id: (json['id'] as num).toInt(),
        title: json['title'] as String? ?? '',
        body: json['body'] as String?,
        pdfUrl: json['pdfUrl'] as String?,
        pdfFileName: json['pdfFileName'] as String?,
        targetType: json['targetType'] as String? ?? '',
        targetLabel: json['targetLabel'] as String? ?? '',
        source: json['source'] as String? ?? 'Admin',
        isFromParent: json['isFromParent'] as bool? ?? false,
        category: json['category'] as String?,
        createdByName: json['createdByName'] as String?,
        createdAt: _parseParentDateTime(json['createdAt']) ?? DateTime.now(),
      );
}

DateTime? _parseParentDateTime(dynamic value) {
  if (value == null) return null;
  if (value is int) {
    final ms = value < 100000000000 ? value * 1000 : value;
    final dt = DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true);
    return dt.year >= 2000 ? dt : null;
  }
  if (value is String && value.isNotEmpty) {
    final dt = DateTime.tryParse(value);
    if (dt == null || dt.year < 2000) return null;
    return dt;
  }
  return null;
}

// Re-export student models for parent child data screens
typedef ParentChildResults = StudentResultsResponse;
typedef ParentChildFees = StudentFeesResponse;
