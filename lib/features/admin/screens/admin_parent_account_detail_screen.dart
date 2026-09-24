import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_card.dart';
import '../models/parent_account_models.dart';
import '../services/parent_account_service.dart';

class AdminParentAccountDetailScreen extends StatefulWidget {
  const AdminParentAccountDetailScreen({super.key, required this.accountId});

  final int accountId;

  @override
  State<AdminParentAccountDetailScreen> createState() => _AdminParentAccountDetailScreenState();
}

class _AdminParentAccountDetailScreenState extends State<AdminParentAccountDetailScreen> {
  late Future<ParentAccountDetail> _future;
  bool _acting = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() => _future = context.read<ParentAccountService>().getAccountDetail(widget.accountId);

  Future<void> _runAction(String label, Future<void> Function() action) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(label),
        content: const Text('هل أنت متأكد من تنفيذ هذه العملية؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('تأكيد')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _acting = true);
    try {
      await action();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تم: $label')));
      setState(_load);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _acting = false);
    }
  }

  Future<void> _exportSingle(ParentAccountDetail account) async {
    final csv = StringBuffer()
      ..writeln('الرقم القومي,الاسم,النوع,الحالة,الهاتف,البريد,عدد الطلاب')
      ..writeln(
        '${account.nationalId},${account.fullName},${account.parentType.labelAr},'
        '${account.status.labelAr},${account.phone ?? ''},${account.email ?? ''},'
        '${account.linkedStudentsCount}',
      );
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/parent_account_${account.nationalId}.csv');
    await file.writeAsString(csv.toString());
    await SharePlus.instance.share(
      ShareParams(files: [XFile(file.path)], text: 'حساب ولي أمر'),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('yyyy/MM/dd HH:mm', 'ar');

    return Scaffold(
      appBar: AppBar(title: const Text('تفاصيل حساب ولي الأمر')),
      body: FutureBuilder<ParentAccountDetail>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text(snapshot.error.toString()));
          }
          final account = snapshot.data!;

          return Stack(
            children: [
              ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              account.parentType == ParentType.father
                                  ? Icons.man_rounded
                                  : Icons.woman_rounded,
                              color: AppColors.primary,
                              size: 32,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    account.fullName.isNotEmpty ? account.fullName : '—',
                                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
                                  ),
                                  Text(
                                    account.nationalId,
                                    textDirection: TextDirection.ltr,
                                    style: const TextStyle(color: AppColors.textSecondary),
                                  ),
                                ],
                              ),
                            ),
                            Chip(label: Text(account.status.labelAr)),
                          ],
                        ),
                        const Divider(height: 24),
                        _InfoRow(label: 'النوع', value: account.parentType.labelAr),
                        _InfoRow(label: 'الهاتف', value: account.phone ?? '—'),
                        _InfoRow(label: 'البريد', value: account.email ?? '—'),
                        if (account.createdAt != null)
                          _InfoRow(
                            label: 'تاريخ الإنشاء',
                            value: dateFormat.format(account.createdAt!.toLocal()),
                          ),
                        if (account.lastLoginAt != null)
                          _InfoRow(
                            label: 'آخر دخول',
                            value: dateFormat.format(account.lastLoginAt!.toLocal()),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('الطلاب المرتبطون', style: TextStyle(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 8),
                  if (account.linkedStudents.isEmpty)
                    const AppCard(
                      child: ListTile(
                        leading: Icon(Icons.info_outline_rounded),
                        title: Text('لا يوجد طلاب مرتبطون'),
                      ),
                    )
                  else
                    ...account.linkedStudents.map(
                      (s) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: AppCard(
                          child: ListTile(
                            leading: const Icon(Icons.school_rounded, color: AppColors.primary),
                            title: Text(s.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                            subtitle: Text('رقم الجلوس: ${s.rollNo} • ${s.grade}'),
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),
                  const Text('إجراءات الإدارة', style: TextStyle(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (account.status != ParentAccountStatus.active)
                        _ActionChip(
                          icon: Icons.check_circle_outline,
                          label: 'تفعيل',
                          onTap: () => _runAction(
                            'تفعيل الحساب',
                            () => context.read<ParentAccountService>().activateAccount(account.id),
                          ),
                        ),
                      if (account.status == ParentAccountStatus.active)
                        _ActionChip(
                          icon: Icons.block_rounded,
                          label: 'إلغاء التفعيل',
                          color: AppColors.danger,
                          onTap: () => _runAction(
                            'إلغاء تفعيل الحساب',
                            () => context.read<ParentAccountService>().deactivateAccount(account.id),
                          ),
                        ),
                      _ActionChip(
                        icon: Icons.lock_reset_rounded,
                        label: 'إعادة تعيين كلمة المرور',
                        onTap: () => _runAction(
                          'إعادة تعيين كلمة المرور (123456)',
                          () => context.read<ParentAccountService>().resetPassword(account.id),
                        ),
                      ),
                      _ActionChip(
                        icon: Icons.refresh_rounded,
                        label: 'إعادة إنشاء الحساب',
                        onTap: () => _runAction(
                          'إعادة إنشاء الحساب',
                          () => context.read<ParentAccountService>().regenerateAccount(account.id),
                        ),
                      ),
                      _ActionChip(
                        icon: Icons.download_rounded,
                        label: 'تصدير Excel',
                        onTap: () => _exportSingle(account),
                      ),
                    ],
                  ),
                ],
              ),
              if (_acting)
                const ColoredBox(
                  color: Color(0x44000000),
                  child: Center(child: CircularProgressIndicator()),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(label, style: const TextStyle(color: AppColors.textSecondary)),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  const _ActionChip({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      avatar: Icon(icon, size: 18, color: color ?? AppColors.primary),
      label: Text(label),
      onPressed: onTap,
    );
  }
}
