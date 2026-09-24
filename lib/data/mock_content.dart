import 'package:flutter/material.dart';

class AttendanceRecord {
  const AttendanceRecord({
    required this.date,
    required this.status,
    required this.subject,
    required this.note,
  });

  final DateTime date;
  final String status;
  final String subject;
  final String note;
}

class HomeworkItem {
  const HomeworkItem({
    required this.title,
    required this.subject,
    required this.dueDate,
    required this.status,
    required this.color,
  });

  final String title;
  final String subject;
  final DateTime dueDate;
  final String status;
  final Color color;
}

class AppNotification {
  const AppNotification({
    required this.title,
    required this.body,
    required this.time,
    required this.icon,
    required this.color,
    required this.isUnread,
  });

  final String title;
  final String body;
  final DateTime time;
  final IconData icon;
  final Color color;
  final bool isUnread;
}

class ParentChildSummary {
  const ParentChildSummary({
    required this.name,
    required this.grade,
    required this.attendanceRate,
    required this.averageGrade,
    required this.pendingHomework,
  });

  final String name;
  final String grade;
  final double attendanceRate;
  final double averageGrade;
  final int pendingHomework;
}

abstract final class MockContent {
  static List<AttendanceRecord> attendanceRecords() => [
        AttendanceRecord(
          date: DateTime.now().subtract(const Duration(days: 1)),
          status: 'حاضر',
          subject: 'اللغة الإنجليزية',
          note: 'حضور في الوقت',
        ),
        AttendanceRecord(
          date: DateTime.now().subtract(const Duration(days: 2)),
          status: 'حاضر',
          subject: 'اللغة الفرنسية',
          note: 'مشاركة ممتازة',
        ),
        AttendanceRecord(
          date: DateTime.now().subtract(const Duration(days: 3)),
          status: 'غائب',
          subject: 'اللغة الألمانية',
          note: 'غياب بعذر',
        ),
        AttendanceRecord(
          date: DateTime.now().subtract(const Duration(days: 4)),
          status: 'حاضر',
          subject: 'اللغة الإسبانية',
          note: 'نشاط صفي',
        ),
      ];

  static List<HomeworkItem> homeworkItems() => [
        HomeworkItem(
          title: 'تمرين المحادثة اليومية',
          subject: 'اللغة الإنجليزية',
          dueDate: DateTime.now().add(const Duration(days: 1)),
          status: 'قيد التنفيذ',
          color: const Color(0xFF4F46E5),
        ),
        HomeworkItem(
          title: 'كتابة فقرة بالماضي',
          subject: 'اللغة الفرنسية',
          dueDate: DateTime.now().add(const Duration(days: 2)),
          status: 'جديد',
          color: const Color(0xFF06B6D4),
        ),
        HomeworkItem(
          title: 'حفظ 20 كلمة جديدة',
          subject: 'اللغة الألمانية',
          dueDate: DateTime.now().add(const Duration(days: 4)),
          status: 'مكتمل',
          color: const Color(0xFF10B981),
        ),
      ];

  static List<AppNotification> notifications() => [
        AppNotification(
          title: 'نتيجة جديدة',
          body: 'تم رفع نتيجة اختبار اللغة الإنجليزية.',
          time: DateTime.now().subtract(const Duration(hours: 2)),
          icon: Icons.grade_rounded,
          color: const Color(0xFF4F46E5),
          isUnread: true,
        ),
        AppNotification(
          title: 'واجب مستحق غداً',
          body: 'لا تنسَ تسليم تمرين المحادثة اليومية.',
          time: DateTime.now().subtract(const Duration(hours: 8)),
          icon: Icons.assignment_rounded,
          color: const Color(0xFFF59E0B),
          isUnread: true,
        ),
        AppNotification(
          title: 'تذكير بالحضور',
          body: 'حضورك هذا الأسبوع ممتاز — استمر!',
          time: DateTime.now().subtract(const Duration(days: 1)),
          icon: Icons.event_available_rounded,
          color: const Color(0xFF10B981),
          isUnread: false,
        ),
      ];

  static List<ParentChildSummary> parentChildren() => [
        const ParentChildSummary(
          name: 'أحمد محمد',
          grade: 'الصف الخامس',
          attendanceRate: 94,
          averageGrade: 88,
          pendingHomework: 2,
        ),
        const ParentChildSummary(
          name: 'سارة محمد',
          grade: 'الصف الثالث',
          attendanceRate: 91,
          averageGrade: 92,
          pendingHomework: 1,
        ),
      ];
}
