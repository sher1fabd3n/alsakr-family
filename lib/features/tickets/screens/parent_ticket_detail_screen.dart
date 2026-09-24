import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_card.dart';
import '../models/student_ticket_models.dart';
import '../services/ticket_service.dart';
import '../widgets/ticket_thread_view.dart';

class ParentTicketDetailScreen extends StatefulWidget {
  const ParentTicketDetailScreen({super.key, required this.ticketId});

  final int ticketId;

  @override
  State<ParentTicketDetailScreen> createState() => _ParentTicketDetailScreenState();
}

class _ParentTicketDetailScreenState extends State<ParentTicketDetailScreen> {
  final _replyController = TextEditingController();
  late Future<StudentTicketDetail> _future;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _future = context.read<ParentTicketService>().getTicket(widget.ticketId);
  }

  @override
  void dispose() {
    _replyController.dispose();
    super.dispose();
  }

  Future<void> _sendReply() async {
    final text = _replyController.text.trim();
    if (text.isEmpty) return;

    setState(() => _sending = true);
    try {
      await context.read<ParentTicketService>().reply(widget.ticketId, text);
      _replyController.clear();
      if (!mounted) return;
      setState(_load);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم إرسال ردك للإدارة')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('yyyy/MM/dd HH:mm');

    return Scaffold(
      appBar: AppBar(title: const Text('تفاصيل التذكرة')),
      body: FutureBuilder<StudentTicketDetail>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text(snapshot.error.toString()));
          }
          final ticket = snapshot.data!;
          final isOpen = ticket.status == StudentTicketStatus.open;

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _Badge(
                          label: ticket.typeLabel,
                          color: ticket.type == StudentTicketType.complaint
                              ? AppColors.danger
                              : AppColors.secondary,
                        ),
                        _Badge(
                          label: ticket.statusLabel,
                          color: isOpen ? AppColors.success : AppColors.textMuted,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '#${ticket.id} — ${dateFormat.format(ticket.createdAt.toLocal())}',
                      style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      ticket.title,
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${ticket.studentName} • جلوس ${ticket.studentRollNo} • ${ticket.studentGrade ?? '—'}',
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              TicketThreadView(ticket: ticket),
              const SizedBox(height: 16),
              if (isOpen)
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text('ردك', style: TextStyle(fontWeight: FontWeight.w800)),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _replyController,
                        decoration: const InputDecoration(
                          hintText: 'اكتب ردك هنا...',
                        ),
                        maxLines: 4,
                        maxLength: 4000,
                      ),
                      const SizedBox(height: 8),
                      FilledButton.icon(
                        onPressed: _sending ? null : _sendReply,
                        icon: _sending
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.send_rounded),
                        label: const Text('إرسال الرد للإدارة'),
                      ),
                    ],
                  ),
                )
              else
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.lock_outline, size: 18, color: AppColors.textSecondary),
                          SizedBox(width: 8),
                          Text('تم إغلاق هذه التذكرة من الإدارة.'),
                        ],
                      ),
                      if (ticket.closedAt != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            'تاريخ الإغلاق: ${dateFormat.format(ticket.closedAt!.toLocal())}',
                            style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                          ),
                        ),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontWeight: FontWeight.w700),
      ),
    );
  }
}
