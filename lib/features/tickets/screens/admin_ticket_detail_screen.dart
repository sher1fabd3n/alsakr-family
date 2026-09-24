import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_card.dart';
import '../models/student_ticket_models.dart';
import '../services/ticket_service.dart';
import '../widgets/ticket_thread_view.dart';

class AdminTicketDetailScreen extends StatefulWidget {
  const AdminTicketDetailScreen({super.key, required this.ticketId});

  final int ticketId;

  @override
  State<AdminTicketDetailScreen> createState() => _AdminTicketDetailScreenState();
}

class _AdminTicketDetailScreenState extends State<AdminTicketDetailScreen> {
  final _replyController = TextEditingController();
  late Future<StudentTicketDetail> _future;
  bool _sending = false;
  bool _closing = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _future = context.read<AdminTicketService>().getTicket(widget.ticketId);
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
      await context.read<AdminTicketService>().reply(widget.ticketId, text);
      _replyController.clear();
      if (!mounted) return;
      setState(_load);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم إرسال الرد لولي الأمر')),
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

  Future<void> _closeTicket() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إغلاق التذكرة'),
        content: const Text('هل أنت متأكد من إغلاق هذه التذكرة؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('إغلاق')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _closing = true);
    try {
      await context.read<AdminTicketService>().close(widget.ticketId);
      if (!mounted) return;
      setState(_load);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم إغلاق التذكرة')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _closing = false);
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
                    Text(
                      'تذكرة #${ticket.id} — ${ticket.typeLabel}',
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                    ),
                    const SizedBox(height: 12),
                    const Text('بيانات الطالب', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.primary)),
                    const SizedBox(height: 6),
                    Text('الاسم: ${ticket.studentName}'),
                    Text('كود التسجيل: ${ticket.studentRollNo}'),
                    Text('الفصل: ${ticket.studentGrade ?? '—'}'),
                    const Divider(height: 24),
                    const Text('حالة التذكرة', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.primary)),
                    const SizedBox(height: 6),
                    Text('الحالة: ${ticket.statusLabel}'),
                    Text('تاريخ الإنشاء: ${dateFormat.format(ticket.createdAt.toLocal())}'),
                    if (ticket.closedAt != null)
                      Text('تاريخ الإغلاق: ${dateFormat.format(ticket.closedAt!.toLocal())}'),
                    if (ticket.closedByUserName != null)
                      Text('أُغلقت بواسطة: ${ticket.closedByUserName}'),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                ticket.title,
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
              ),
              const SizedBox(height: 12),
              TicketThreadView(ticket: ticket, studentLabel: 'ولي الأمر'),
              const SizedBox(height: 16),
              if (isOpen)
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text('رد الإدارة', style: TextStyle(fontWeight: FontWeight.w800)),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _replyController,
                        decoration: const InputDecoration(
                          hintText: 'اكتب ردك أو اطلب بيانات إضافية من ولي الأمر...',
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
                        label: const Text('حفظ الرد وإرساله لولي الأمر'),
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        onPressed: _closing ? null : _closeTicket,
                        icon: _closing
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.lock_outline),
                        style: OutlinedButton.styleFrom(foregroundColor: AppColors.danger),
                        label: const Text('إغلاق التذكرة'),
                      ),
                    ],
                  ),
                )
              else
                const AppCard(
                  child: Row(
                    children: [
                      Icon(Icons.lock_outline, color: AppColors.textSecondary),
                      SizedBox(width: 8),
                      Expanded(child: Text('هذه التذكرة مغلقة ولا يمكن إضافة ردود جديدة.')),
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
