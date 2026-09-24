import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_card.dart';
import '../models/parent_account_models.dart';
import '../services/parent_account_service.dart';
import 'admin_parent_account_detail_screen.dart';
import 'admin_parent_audit_log_screen.dart';
import 'admin_parent_id_validation_screen.dart';

class AdminParentAccountsScreen extends StatefulWidget {
  const AdminParentAccountsScreen({super.key});

  @override
  State<AdminParentAccountsScreen> createState() => _AdminParentAccountsScreenState();
}

class _AdminParentAccountsScreenState extends State<AdminParentAccountsScreen> {
  final _nationalIdController = TextEditingController();
  final _nameController = TextEditingController();
  ParentAccountStatus? _statusFilter;
  late Future<List<ParentAccountSummary>> _future;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _future = context.read<ParentAccountService>().searchAccounts(
          nationalId: _nationalIdController.text.trim(),
          name: _nameController.text.trim(),
          status: _statusFilter,
        );
  }

  @override
  void dispose() {
    _nationalIdController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Color _statusColor(ParentAccountStatus status) => switch (status) {
        ParentAccountStatus.active => AppColors.accent,
        ParentAccountStatus.inactive => AppColors.textSecondary,
        ParentAccountStatus.pendingValidation => AppColors.secondary,
        ParentAccountStatus.invalidNationalId => AppColors.danger,
      };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة حسابات أولياء الأمور'),
        actions: [
          IconButton(
            tooltip: 'سجل العمليات',
            icon: const Icon(Icons.history_rounded),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const AdminParentAuditLogScreen()),
            ),
          ),
          IconButton(
            tooltip: 'مركز التحقق من الأرقام القومية',
            icon: const Icon(Icons.verified_user_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const AdminParentIdValidationScreen()),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  controller: _nationalIdController,
                  keyboardType: TextInputType.number,
                  textDirection: TextDirection.ltr,
                  decoration: InputDecoration(
                    hintText: 'بحث بالرقم القومي (14 رقم)',
                    prefixIcon: const Icon(Icons.badge_outlined),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.search_rounded),
                      onPressed: () => setState(_load),
                    ),
                  ),
                  onSubmitted: (_) => setState(_load),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          hintText: 'بحث باسم ولي الأمر',
                          prefixIcon: const Icon(Icons.person_search_rounded),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.search_rounded),
                            onPressed: () => setState(_load),
                          ),
                        ),
                        onSubmitted: (_) => setState(_load),
                      ),
                    ),
                    const SizedBox(width: 8),
                    PopupMenuButton<ParentAccountStatus?>(
                      tooltip: 'فلترة بالحالة',
                      onSelected: (v) => setState(() {
                        _statusFilter = v;
                        _load();
                      }),
                      itemBuilder: (context) => [
                        const PopupMenuItem(value: null, child: Text('جميع الحالات')),
                        ...ParentAccountStatus.values.map(
                          (s) => PopupMenuItem(value: s, child: Text(s.labelAr)),
                        ),
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
                if (_statusFilter != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: InputChip(
                      label: Text('الحالة: ${_statusFilter!.labelAr}'),
                      onDeleted: () => setState(() {
                        _statusFilter = null;
                        _load();
                      }),
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
              child: FutureBuilder<List<ParentAccountSummary>>(
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
                          child: Text(
                            snapshot.error.toString().replaceFirst('Exception: ', ''),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    );
                  }
                  final items = snapshot.data ?? [];
                  if (items.isEmpty) {
                    return ListView(
                      children: const [
                        SizedBox(height: 80),
                        Icon(Icons.family_restroom_rounded, size: 64, color: AppColors.textSecondary),
                        SizedBox(height: 16),
                        Text('لا توجد حسابات', textAlign: TextAlign.center),
                      ],
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return AppCard(
                        onTap: () async {
                          await Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => AdminParentAccountDetailScreen(accountId: item.id),
                            ),
                          );
                          if (mounted) setState(_load);
                        },
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: _statusColor(item.status).withValues(alpha: 0.15),
                            child: Icon(
                              item.parentType == ParentType.father
                                  ? Icons.man_rounded
                                  : Icons.woman_rounded,
                              color: _statusColor(item.status),
                            ),
                          ),
                          title: Text(
                            item.fullName.isNotEmpty ? item.fullName : item.nationalId,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${item.parentType.labelAr} • ${item.nationalId}',
                                textDirection: TextDirection.ltr,
                              ),
                              Text(
                                '${item.linkedStudentsCount} طالب مرتبط • ${item.status.labelAr}',
                                style: const TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                          trailing: const Icon(Icons.chevron_left_rounded),
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
