import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_card.dart';
import '../../../utils/national_id_validator.dart';
import '../models/parent_account_models.dart';
import '../services/parent_account_service.dart';
import 'admin_parent_account_detail_screen.dart';

class AdminParentIdValidationScreen extends StatefulWidget {
  const AdminParentIdValidationScreen({super.key});

  @override
  State<AdminParentIdValidationScreen> createState() => _AdminParentIdValidationScreenState();
}

class _AdminParentIdValidationScreenState extends State<AdminParentIdValidationScreen> {
  final _searchController = TextEditingController();
  late Future<List<InvalidParentIdRecord>> _future;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _future = context.read<ParentAccountService>().getInvalidRecords(
          search: _searchController.text.trim(),
        );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _showCorrectionDialog(InvalidParentIdRecord record) async {
    final controller = TextEditingController(text: record.invalidId ?? '');
    final formKey = GlobalKey<FormState>();
    var generateAccount = true;

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('تصحيح الرقم القومي'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('الطالب: ${record.studentName} (${record.grade})'),
                Text('${record.parentType.labelAr} — ${record.validationMessage}'),
                const SizedBox(height: 12),
                TextFormField(
                  controller: controller,
                  keyboardType: TextInputType.number,
                  textDirection: TextDirection.ltr,
                  maxLength: 14,
                  decoration: const InputDecoration(
                    labelText: 'الرقم القومي الصحيح (14 رقم)',
                    counterText: '',
                  ),
                  validator: (v) => NationalIdValidator.validationMessage(v),
                ),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('إنشاء حساب ولي الأمر فورًا'),
                  value: generateAccount,
                  onChanged: (v) => setDialogState(() => generateAccount = v ?? true),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
            FilledButton(
              onPressed: () {
                if (formKey.currentState!.validate()) Navigator.pop(ctx, true);
              },
              child: const Text('حفظ التصحيح'),
            ),
          ],
        ),
      ),
    );

    if (result != true || !mounted) return;

    try {
      final account = await context.read<ParentAccountService>().correctInvalidId(
            recordId: record.id,
            correctedNationalId: controller.text.trim(),
            generateAccount: generateAccount,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم حفظ التصحيح بنجاح')),
      );
      if (account != null) {
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => AdminParentAccountDetailScreen(accountId: account.id),
          ),
        );
      }
      setState(_load);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('مركز التحقق من الأرقام القومية')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'بحث باسم الطالب أو الرقم...',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () => setState(_load),
                ),
              ),
              onSubmitted: (_) => setState(_load),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                setState(_load);
                await _future;
              },
              child: FutureBuilder<List<InvalidParentIdRecord>>(
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
                        Icon(Icons.verified_rounded, size: 64, color: AppColors.accent),
                        SizedBox(height: 16),
                        Text('لا توجد سجلات غير صالحة', textAlign: TextAlign.center),
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
                        child: ListTile(
                          leading: const Icon(Icons.error_outline_rounded, color: AppColors.danger),
                          title: Text(
                            item.studentName,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('${item.parentType.labelAr} • ${item.grade} • جلوس ${item.rollNo}'),
                              Text(
                                'قيمة غير صالحة: ${item.invalidId ?? '—'}',
                                textDirection: TextDirection.ltr,
                              ),
                              Text(
                                item.validationMessage,
                                style: const TextStyle(color: AppColors.danger, fontSize: 12),
                              ),
                            ],
                          ),
                          trailing: FilledButton.tonal(
                            onPressed: () => _showCorrectionDialog(item),
                            child: const Text('تصحيح'),
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
