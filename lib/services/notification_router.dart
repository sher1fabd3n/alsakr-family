import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../features/communication/models/communication_models.dart';
import '../features/communication/screens/announcement_center_screen.dart';
import '../features/communication/screens/conversation_screen.dart';
import '../features/parent/screens/parent_child_grades_screen.dart';
import '../features/parent/screens/parent_child_reports_screen.dart';
import '../features/parent/state/parent_child_context.dart';
import '../features/tickets/screens/parent_ticket_detail_screen.dart';

class NotificationRouter {
  static final navigatorKey = GlobalKey<NavigatorState>();

  static Future<void> open(Map<String, String> data) async {
    final nav = navigatorKey.currentState;
    final context = navigatorKey.currentContext;
    if (nav == null || context == null) return;

    final type = '${data['type'] ?? ''} ${data['referenceType'] ?? ''}'.toLowerCase();
    final conversationId = int.tryParse(data['conversationId'] ?? '');
    final ticketId = int.tryParse(data['ticketId'] ?? data['referenceId'] ?? '');
    final studentId = int.tryParse(data['studentId'] ?? '');

    if (studentId != null && studentId > 0) {
      try {
        await context.read<ParentChildContext>().selectChild(studentId);
      } catch (_) {}
    }

    if (type.contains('announcement') || type.contains('emergency')) {
      nav.push(MaterialPageRoute(builder: (_) => const AnnouncementCenterScreen()));
      return;
    }

    if (conversationId != null && (type.contains('chat') || type.contains('chatmessage'))) {
      nav.push(MaterialPageRoute(
        builder: (_) => ConversationScreen(
          conversation: ConversationItem(
            id: conversationId,
            studentId: studentId ?? 0,
            studentName: data['title'] ?? 'محادثة',
            studentGrade: '',
            teacherName: data['senderName'] ?? '',
            parentName: '',
            unreadCount: 0,
          ),
        ),
      ));
      return;
    }

    if (type.contains('ticket') || type.contains('studentticket')) {
      if (ticketId == null) return;
      nav.push(MaterialPageRoute(builder: (_) => ParentTicketDetailScreen(ticketId: ticketId)));
      return;
    }

    if (type.contains('report') || type.contains('parentreport')) {
      nav.push(MaterialPageRoute(builder: (_) => const ParentChildReportsScreen()));
      return;
    }

    if (type.contains('result') || type.contains('grade') || type.contains('exam')) {
      nav.push(MaterialPageRoute(builder: (_) => const ParentChildGradesScreen()));
    }
  }
}
