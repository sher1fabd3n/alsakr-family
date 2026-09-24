import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../features/admin/services/parent_account_service.dart';
import '../../services/api_client.dart';
import '../../services/remembered_credentials.dart';

class ParentChangePasswordScreen extends StatefulWidget {
  const ParentChangePasswordScreen({super.key});

  @override
  State<ParentChangePasswordScreen> createState() => _ParentChangePasswordScreenState();
}

class _ParentChangePasswordScreenState extends State<ParentChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _loading = false;
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final api = context.read<ApiClient>();
      await context.read<ParentAccountService>().changePassword(
            currentPassword: _currentController.text,
            newPassword: _newController.text.trim(),
          );
      await RememberedCredentials(api).updatePassword(_newController.text.trim());
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم تغيير كلمة المرور بنجاح')),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('تغيير كلمة المرور')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text(
              'أدخل كلمة المرور الحالية ثم كلمة المرور الجديدة.',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _currentController,
              obscureText: _obscureCurrent,
              decoration: InputDecoration(
                labelText: 'كلمة المرور الحالية',
                prefixIcon: const Icon(Icons.lock_outline_rounded),
                suffixIcon: IconButton(
                  onPressed: () => setState(() => _obscureCurrent = !_obscureCurrent),
                  icon: Icon(_obscureCurrent ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                ),
              ),
              validator: (v) => v == null || v.isEmpty ? 'مطلوب' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _newController,
              obscureText: _obscureNew,
              decoration: InputDecoration(
                labelText: 'كلمة المرور الجديدة',
                prefixIcon: const Icon(Icons.lock_reset_rounded),
                suffixIcon: IconButton(
                  onPressed: () => setState(() => _obscureNew = !_obscureNew),
                  icon: Icon(_obscureNew ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                ),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'مطلوب';
                if (v.trim().length < 6) return 'يجب ألا تقل عن 6 أحرف';
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _confirmController,
              obscureText: _obscureConfirm,
              decoration: InputDecoration(
                labelText: 'تأكيد كلمة المرور',
                prefixIcon: const Icon(Icons.verified_user_outlined),
                suffixIcon: IconButton(
                  onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                  icon: Icon(_obscureConfirm ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                ),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'مطلوب';
                if (v != _newController.text) return 'كلمتا المرور غير متطابقتين';
                return null;
              },
            ),
            const SizedBox(height: 28),
            FilledButton.icon(
              onPressed: _loading ? null : _submit,
              icon: _loading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.save_rounded),
              label: Text(_loading ? 'جاري الحفظ...' : 'حفظ كلمة المرور'),
            ),
          ],
        ),
      ),
    );
  }
}
