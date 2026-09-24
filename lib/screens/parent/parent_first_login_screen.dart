import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app_state.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_card.dart';
import '../../features/admin/services/parent_account_service.dart';
import '../../features/parent/state/unread_badge_store.dart';
import '../../services/api_client.dart';
import '../../services/remembered_credentials.dart';
import '../../services/student_services.dart';
import 'parent_shell.dart';

class ParentFirstLoginScreen extends StatefulWidget {
  const ParentFirstLoginScreen({super.key});

  @override
  State<ParentFirstLoginScreen> createState() => _ParentFirstLoginScreenState();
}

class _ParentFirstLoginScreenState extends State<ParentFirstLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  bool _loading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  @override
  void initState() {
    super.initState();
    final profile = context.read<AuthService>().currentParent;
    if (profile?.phone != null) _phoneController.text = profile!.phone!;
    if (profile?.email != null) _emailController.text = profile!.email!;
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit({bool skipPassword = false}) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    try {
      final service = context.read<ParentAccountService>();
      final auth = context.read<AuthService>();
      final password = skipPassword ? null : _passwordController.text.trim();
      await service.completeFirstLogin(
        newPassword: password != null && password.isNotEmpty ? password : null,
        phone: _phoneController.text.trim(),
        email: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
      );
      final api = context.read<ApiClient>();
      final updated = await service.getProfile();
      auth.updateCurrentParent(updated);
      if (password != null && password.isNotEmpty) {
        await RememberedCredentials(api).updatePassword(password);
      }
      if (!mounted) return;
      try {
        await context.read<UnreadBadgeStore>().refresh();
      } catch (_) {}
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const ParentShell()),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _logout() async {
    final badges = context.read<UnreadBadgeStore>();
    final auth = context.read<AuthService>();
    final appState = context.read<AppState>();
    await badges.reset();
    await auth.logout();
    if (!mounted) return;
    appState.clearSession();
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<AuthService>().currentParent;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                children: [
                  const Icon(Icons.security_rounded, size: 64, color: AppColors.primary),
                  const SizedBox(height: 16),
                  Text(
                    'إعداد الحساب لأول مرة',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'مرحبًا ${profile?.fullName ?? ''}. يُرجى تأكيد بيانات التواصل. تغيير كلمة المرور اختياري.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 24),
                  AppCard(
                    padding: const EdgeInsets.all(22),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            decoration: InputDecoration(
                              labelText: 'كلمة المرور الجديدة (اختياري)',
                              prefixIcon: const Icon(Icons.lock_outline_rounded),
                              suffixIcon: IconButton(
                                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                ),
                              ),
                            ),
                            validator: (v) {
                              if (v == null || v.isEmpty) return null;
                              if (v.length < 6) return 'كلمة المرور 6 أحرف على الأقل';
                              if (v == '123456') return 'لا يمكن استخدام كلمة المرور الافتراضية';
                              return null;
                            },
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _confirmPasswordController,
                            obscureText: _obscureConfirm,
                            decoration: InputDecoration(
                              labelText: 'تأكيد كلمة المرور (اختياري)',
                              prefixIcon: const Icon(Icons.lock_rounded),
                              suffixIcon: IconButton(
                                onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                                icon: Icon(
                                  _obscureConfirm
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                ),
                              ),
                            ),
                            validator: (v) {
                              if (_passwordController.text.isEmpty) return null;
                              if (v == null || v.isEmpty) return 'أكّد كلمة المرور';
                              return v != _passwordController.text ? 'كلمتا المرور غير متطابقتين' : null;
                            },
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            textDirection: TextDirection.ltr,
                            decoration: const InputDecoration(
                              labelText: 'رقم الهاتف *',
                              prefixIcon: Icon(Icons.phone_rounded),
                            ),
                            validator: (v) =>
                                v == null || v.trim().length < 10 ? 'رقم هاتف صالح مطلوب' : null,
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            textDirection: TextDirection.ltr,
                            decoration: const InputDecoration(
                              labelText: 'البريد الإلكتروني (اختياري)',
                              prefixIcon: Icon(Icons.email_outlined),
                            ),
                          ),
                          const SizedBox(height: 22),
                          FilledButton(
                            onPressed: _loading ? null : () => _submit(),
                            child: _loading
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Text('حفظ والمتابعة'),
                          ),
                          TextButton(
                            onPressed: _loading ? null : () => _submit(skipPassword: true),
                            child: const Text('المتابعة دون تغيير كلمة المرور'),
                          ),
                          TextButton(
                            onPressed: _logout,
                            child: const Text('تسجيل الخروج'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
