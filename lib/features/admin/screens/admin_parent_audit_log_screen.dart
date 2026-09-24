import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_card.dart';
import '../models/parent_account_models.dart';
import '../services/parent_account_service.dart';

class AdminParentAuditLogScreen extends StatefulWidget {
  const AdminParentAuditLogScreen({super.key});

  @override
  State<AdminParentAuditLogScreen> createState() => _AdminParentAuditLogScreenState();
}

class _AdminParentAuditLogScreenState extends State<AdminParentAuditLogScreen> {
  final _nationalIdController = TextEditingController();
  ParentAuditAction? _actionFilter;
  late Future<List<ParentAuditLogEntry>> _future;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _future = context.read<ParentAccountService>().getAuditLog(
          nationalId: _nationalIdController.text.trim(),
          action: _actionFilter,
        );
  }

  @override
  void dispose() {
    _nationalIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('yyyy/MM/dd HH:mm', 'ar');

    return Scaffold(
      appBar: AppBar(title: const Text('سجل عمليات حسابات أولياء الأمور')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _nationalIdController,
                    keyboardType: TextInputType.number,
                    textDirection: TextDirection.ltr,
                    decoration: InputDecoration(
                      hintText: 'فلترة بالرقم القومي',
                      prefixIcon: const Icon(Icons.badge_outlined),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.search_rounded),
                        onPressed: () => setState(_load),
                      ),
                    ),
                    onSubmitted: (_) => setState(_load),
                  ),
                ),
                const SizedBox(width: 8),
                PopupMenuButton<ParentAuditAction?>(
                  onSelected: (v) => setState(() {
                    _actionFilter = v;
                    _load();
                  }),
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: null, child: Text('جميع العمليات')),
                    ...ParentAuditAction.values
                        .where((a) => a != ParentAuditAction.unknown)
                        .map((a) => PopupMenuItem(value: a, child: Text(a.labelAr))),
                  ],
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.textMuted.withValues(alpha: 0.4)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.filter_list_rounded),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                setState(_load);
                await _future;
              },
              child: FutureBuilder<List<ParentAuditLogEntry>>(
                future: _future,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return ListView(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(snapshot.error.toString(), textAlign: TextAlign.center),
                        ),
                      ],
                    );
                  }
                  final items = snapshot.data ?? [];
                  if (items.isEmpty) {
                    return ListView(
                      children: const [
                        SizedBox(height: 80),
                        Text('لا توجد عمليات مسجلة', textAlign: TextAlign.center),
                      ],
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final entry = items[index];
                      return AppCard(
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.history_rounded, size: 18, color: AppColors.primary),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      entry.action.labelAr,
                                      style: const TextStyle(fontWeight: FontWeight.w700),
                                    ),
                                  ),
                                  Text(
                                    dateFormat.format(entry.performedAt.toLocal()),
                                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text('بواسطة: ${entry.performedBy}'),
                              if (entry.parentNationalId != null)
                                Text(
                                  'الرقم القومي: ${entry.parentNationalId}',
                                  textDirection: TextDirection.ltr,
                                ),
                              if (entry.oldValue != null || entry.newValue != null) ...[
                                const SizedBox(height: 4),
                                if (entry.oldValue != null)
                                  Text(
                                    'القيمة السابقة: ${entry.oldValue}',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                if (entry.newValue != null)
                                  Text(
                                    'القيمة الجديدة: ${entry.newValue}',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                              ],
                              if (entry.notes != null && entry.notes!.isNotEmpty)
                                Text(
                                  entry.notes!,
                                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
