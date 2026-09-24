import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../models/student_ticket_models.dart';

class TicketThreadView extends StatelessWidget {
  const TicketThreadView({
    super.key,
    required this.ticket,
    this.studentLabel = 'ولي الأمر',
  });

  final StudentTicketDetail ticket;
  final String studentLabel;

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('yyyy/MM/dd HH:mm');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'المحادثة',
          style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.primary),
        ),
        const SizedBox(height: 12),
        _Bubble(
          title: studentLabel,
          message: ticket.content,
          time: dateFormat.format(ticket.createdAt.toLocal()),
          isAdmin: false,
        ),
        ...ticket.messages.map(
          (msg) => _Bubble(
            title: msg.isAdmin ? 'الإدارة' : studentLabel,
            subtitle: msg.isAdmin ? msg.senderName : null,
            message: msg.message,
            time: dateFormat.format(msg.createdAt.toLocal()),
            isAdmin: msg.isAdmin,
          ),
        ),
        if (ticket.legacyAdminResponse != null)
          _Bubble(
            title: 'الإدارة',
            message: ticket.legacyAdminResponse!,
            time: dateFormat.format((ticket.closedAt ?? ticket.updatedAt).toLocal()),
            isAdmin: true,
          ),
      ],
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({
    required this.title,
    required this.message,
    required this.time,
    required this.isAdmin,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final String message;
  final String time;
  final bool isAdmin;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isAdmin
            ? AppColors.success.withValues(alpha: 0.1)
            : AppColors.background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isAdmin
              ? AppColors.success.withValues(alpha: 0.35)
              : AppColors.textMuted.withValues(alpha: 0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: title,
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: isAdmin ? AppColors.success : AppColors.primary,
                        ),
                      ),
                      if (subtitle != null)
                        TextSpan(
                          text: ' ($subtitle)',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textMuted,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              Text(time, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
            ],
          ),
          const SizedBox(height: 8),
          Text(message),
        ],
      ),
    );
  }
}
