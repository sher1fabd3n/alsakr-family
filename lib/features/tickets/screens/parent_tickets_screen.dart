import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/fade_slide_in.dart';
import '../../../core/widgets/section_header.dart';
import '../../parent/state/parent_child_context.dart';
import '../models/student_ticket_models.dart';
import '../services/ticket_service.dart';
import 'parent_ticket_detail_screen.dart';

class ParentTicketsScreen extends StatefulWidget {
  const ParentTicketsScreen({super.key});

  @override
  State<ParentTicketsScreen> createState() => _ParentTicketsScreenState();
}

class _ParentTicketsScreenState extends State<ParentTicketsScreen> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  StudentTicketType _type = StudentTicketType.complaint;
  int? _filterStudentId;
  late Future<List<StudentTicketSummary>> _future;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _future = context.read<ParentTicketService>().getTickets(studentId: _filterStudentId);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _submitTicket() async {
    final ctx = context.read<ParentChildContext>();
    final studentId = _filterStudentId ?? ctx.activeStudentId;
    if (studentId == null) {
      _showSnack('اختر ابناً أولاً');
      return;
    }

    final title = _titleController.text.trim();
    final content = _contentController.text.trim();
    if (title.isEmpty || content.isEmpty) {
      _showSnack('يرجى إدخال العنوان والمضمون');
      return;
    }

    setState(() => _submitting = true);
    try {
      await context.read<ParentTicketService>().createTicket(
            studentId: studentId,
            type: _type,
            title: title,
            content: content,
          );
      _titleController.clear();
      _contentController.clear();
      if (!mounted) return;
      _showSnack(_type == StudentTicketType.complaint
          ? 'تم إرسال الشكوى بنجاح'
          : 'تم إرسال المقترح بنجاح');
      setState(_load);
    } catch (e) {
      _showSnack(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final childCtx = context.watch<ParentChildContext>();
    final children = childCtx.children;
    final dateFormat = DateFormat('yyyy/MM/dd HH:mm');

    return Scaffold(
      appBar: AppBar(title: const Text('الشكاوى والمقترحات')),
      body: RefreshIndicator(
        onRefresh: () async {
          setState(_load);
          await _future;
        },
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            FadeSlideIn(
              child: AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'فتح تذكرة جديدة',
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                    ),
                    const SizedBox(height: 14),
                    if (children.length > 1) ...[
                      DropdownButtonFormField<int>(
                        value: _filterStudentId ?? childCtx.activeStudentId,
                        decoration: const InputDecoration(labelText: 'الابن'),
                        items: children
                            .map(
                              (c) => DropdownMenuItem(
                                value: c.studentId,
                                child: Text(c.name),
                              ),
                            )
                            .toList(),
                        onChanged: (v) => setState(() => _filterStudentId = v),
                      ),
                      const SizedBox(height: 12),
                    ],
                    DropdownButtonFormField<StudentTicketType>(
                      value: _type,
                      decoration: const InputDecoration(labelText: 'النوع'),
                      items: const [
                        DropdownMenuItem(
                          value: StudentTicketType.complaint,
                          child: Text('شكوى'),
                        ),
                        DropdownMenuItem(
                          value: StudentTicketType.suggestion,
                          child: Text('مقترح'),
                        ),
                      ],
                      onChanged: (v) => setState(() => _type = v ?? StudentTicketType.complaint),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'عنوان المشكلة أو المقترح',
                        hintText: 'مثال: مشكلة في النتائج',
                      ),
                      maxLength: 200,
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _contentController,
                      decoration: const InputDecoration(
                        labelText: 'المضمون',
                        hintText: 'اشرح المشكلة أو المقترح بالتفصيل...',
                      ),
                      maxLines: 5,
                      maxLength: 4000,
                    ),
                    const SizedBox(height: 8),
                    FilledButton.icon(
                      onPressed: _submitting ? null : _submitTicket,
                      icon: _submitting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.send_rounded),
                      label: Text(
                        _type == StudentTicketType.complaint
                            ? 'إرسال الشكوى'
                            : 'إرسال المقترح',
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                const Expanded(
                  child: SectionHeader(title: 'تذاكري'),
                ),
                if (children.length > 1)
                  DropdownButton<int?>(
                    value: _filterStudentId,
                    hint: const Text('كل الأبناء'),
                    underline: const SizedBox.shrink(),
                    items: [
                      const DropdownMenuItem<int?>(value: null, child: Text('كل الأبناء')),
                      ...children.map(
                        (c) => DropdownMenuItem<int?>(
                          value: c.studentId,
                          child: Text(c.name),
                        ),
                      ),
                    ],
                    onChanged: (v) => setState(() {
                      _filterStudentId = v;
                      _load();
                    }),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            FutureBuilder<List<StudentTicketSummary>>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: Padding(
                    padding: EdgeInsets.all(32),
                    child: CircularProgressIndicator(),
                  ));
                }
                if (snapshot.hasError) {
                  return Center(child: Text(snapshot.error.toString()));
                }
                final tickets = snapshot.data ?? [];
                if (tickets.isEmpty) {
                  return const AppCard(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('لم تُرسل أي تذاكر بعد.'),
                    ),
                  );
                }
                return Column(
                  children: tickets.map((ticket) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: AppCard(
                        onTap: () async {
                          await Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => ParentTicketDetailScreen(ticketId: ticket.id),
                            ),
                          );
                          if (mounted) setState(_load);
                        },
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    ticket.title,
                                    style: const TextStyle(fontWeight: FontWeight.w800),
                                  ),
                                ),
                                if (ticket.hasNewReply)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: AppColors.danger,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Text(
                                      'رد جديد',
                                      style: TextStyle(color: Colors.white, fontSize: 11),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: [
                                _Badge(
                                  label: ticket.typeLabel,
                                  color: ticket.type == StudentTicketType.complaint
                                      ? AppColors.danger
                                      : AppColors.secondary,
                                ),
                                _Badge(
                                  label: ticket.statusLabel,
                                  color: ticket.status == StudentTicketStatus.open
                                      ? AppColors.success
                                      : AppColors.textMuted,
                                ),
                                if (children.length > 1)
                                  _Badge(label: ticket.studentName, color: AppColors.primary),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              dateFormat.format(ticket.createdAt.toLocal()),
                              style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w700),
      ),
    );
  }
}
