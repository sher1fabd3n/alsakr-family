import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_card.dart';
import '../models/student_ticket_models.dart';
import '../services/ticket_service.dart';
import 'admin_ticket_detail_screen.dart';

class AdminTicketsScreen extends StatefulWidget {
  const AdminTicketsScreen({super.key});

  @override
  State<AdminTicketsScreen> createState() => _AdminTicketsScreenState();
}

class _AdminTicketsScreenState extends State<AdminTicketsScreen> {
  final _searchController = TextEditingController();
  String _statusFilter = 'all';
  late Future<({List<StudentTicketSummary> tickets, StudentTicketStats stats})> _future;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    final service = context.read<AdminTicketService>();
    _future = () async {
      final results = await Future.wait([
        service.searchTickets(
          status: _statusFilter == 'all' ? null : _statusFilter,
          search: _searchController.text.trim(),
        ),
        service.getStats(),
      ]);
      return (
        tickets: results[0] as List<StudentTicketSummary>,
        stats: results[1] as StudentTicketStats,
      );
    }();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('yyyy/MM/dd HH:mm');

    return Scaffold(
      appBar: AppBar(title: const Text('شكاوى ومقترحات أولياء الأمور')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                FutureBuilder<({List<StudentTicketSummary> tickets, StudentTicketStats stats})>(
                  future: _future,
                  builder: (context, snapshot) {
                    final stats = snapshot.data?.stats;
                    if (stats == null) return const SizedBox.shrink();
                    return Row(
                      children: [
                        _StatChip(label: 'مفتوحة', value: stats.openCount, color: AppColors.danger),
                        const SizedBox(width: 8),
                        if (stats.unviewedCount > 0)
                          _StatChip(label: 'جديدة', value: stats.unviewedCount, color: AppColors.warning),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _statusFilter,
                        decoration: const InputDecoration(labelText: 'الحالة'),
                        items: const [
                          DropdownMenuItem(value: 'all', child: Text('كل التذاكر')),
                          DropdownMenuItem(value: 'open', child: Text('المفتوحة فقط')),
                          DropdownMenuItem(value: 'closed', child: Text('المغلقة فقط')),
                        ],
                        onChanged: (v) => setState(() {
                          _statusFilter = v ?? 'all';
                          _load();
                        }),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'بحث بالعنوان أو اسم الطالب أو كود التسجيل...',
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.search),
                      onPressed: () => setState(_load),
                    ),
                  ),
                  onSubmitted: (_) => setState(_load),
                ),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<({List<StudentTicketSummary> tickets, StudentTicketStats stats})>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text(snapshot.error.toString()));
                }
                final tickets = snapshot.data?.tickets ?? [];
                if (tickets.isEmpty) {
                  return const Center(child: Text('لا توجد تذاكر مطابقة'));
                }
                return RefreshIndicator(
                  onRefresh: () async {
                    setState(_load);
                    await _future;
                  },
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    itemCount: tickets.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final ticket = tickets[index];
                      return AppCard(
                        onTap: () async {
                          await Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => AdminTicketDetailScreen(ticketId: ticket.id),
                            ),
                          );
                          if (mounted) setState(_load);
                        },
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  '#${ticket.id}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.textMuted,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                if (ticket.hasNewReply)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: AppColors.warning,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Text(
                                      'جديد',
                                      style: TextStyle(color: Colors.white, fontSize: 11),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              ticket.studentName,
                              style: const TextStyle(fontWeight: FontWeight.w800),
                            ),
                            Text(
                              '${ticket.studentRollNo} — ${ticket.studentGrade ?? '—'}',
                              style: const TextStyle(color: AppColors.textSecondary),
                            ),
                            const SizedBox(height: 8),
                            Text(ticket.title),
                            const SizedBox(height: 8),
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
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              dateFormat.format(ticket.createdAt.toLocal()),
                              style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.label, required this.value, required this.color});

  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '$label: $value',
        style: TextStyle(color: color, fontWeight: FontWeight.w700),
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
