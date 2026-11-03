import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app_state.dart';
import '../../config/app_variant.dart';
import '../../core/constants/app_branding.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_logo.dart';
import '../../core/widgets/fade_slide_in.dart';
import '../../core/widgets/login_footer.dart';
import '../../services/api_client.dart';
import '../../services/remembered_credentials.dart';
import '../../services/student_services.dart';
import '../../features/driver/screens/driver_shell.dart';
import '../../features/driver/services/driver_service.dart';
import '../../features/admin/services/admin_service.dart';
import '../../features/admin/screens/admin_shell.dart';
import '../../features/parent/state/unread_badge_store.dart';
import '../../services/push_notification_service.dart';
import '../../features/transportation/services/transportation_service.dart';
import '../../utils/national_id_validator.dart';
import '../../features/parent/state/parent_child_context.dart';
import '../parent/parent_first_login_screen.dart';
import '../parent/parent_shell.dart';
import '../shell/main_shell.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;
  bool _obscurePassword = true;
  bool _rememberMe = true;
  AppRole _selectedRole = AppRole.student;
  bool _roleInitialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _restoreRemembered());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_roleInitialized) {
      _selectedRole = context.read<AppVariantConfig>().defaultRole;
      _roleInitialized = true;
    }
  }

  Future<void> _restoreRemembered() async {
    final saved = await RememberedCredentials(context.read<ApiClient>()).read();
    if (!mounted || saved == null) return;
    final variant = context.read<AppVariantConfig>();
    final role = RememberedCredentials.parseRole(saved.role);
    setState(() {
      _rememberMe = true;
      _usernameController.text = saved.username;
      _passwordController.text = saved.password;
      if (role != null && variant.allowedRoles.contains(role)) {
        _selectedRole = role;
      }
    });
  }

  Future<void> _persistCredentials(AppRole role, String username, String password) async {
    final store = RememberedCredentials(context.read<ApiClient>());
    if (_rememberMe) {
      await store.save(username: username, password: password, role: role.name);
    } else {
      await store.clear();
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _registerPush() async {
    try {
      await context.read<PushNotificationService>().registerAfterLogin(
            context.read<TransportationService>(),
          );
    } catch (_) {}
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    try {
      final variant = context.read<AppVariantConfig>();
      final role = variant.singleRole ? variant.fixedRole : _selectedRole;
      context.read<AppState>().setRole(role);

      if (role == AppRole.parent) {
        final nationalId = NationalIdValidator.normalize(_usernameController.text) ??
            _usernameController.text.trim();
        final password = _passwordController.text.trim();
        final loginResponse = await context.read<AuthService>().loginParent(
              nationalId,
              password,
            );
        await _persistCredentials(role, nationalId, password);
        if (!mounted) return;
        context.read<AppState>().setMobileRole('Parent');
        context.read<AppState>().setParentPermissions(loginResponse.profile.permissions);
        await _registerPush();
        if (!mounted) return;
        final needsSetup = loginResponse.profile.needsFirstLoginSetup;
        if (!needsSetup) {
          final childCtx = context.read<ParentChildContext>();
          final badges = context.read<UnreadBadgeStore>();
          childCtx.clear();
          try {
            await childCtx.bootstrap(force: true);
          } catch (_) {}
          try {
            await badges.refresh();
          } catch (_) {}
        }
        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => needsSetup ? const ParentFirstLoginScreen() : const ParentShell(),
          ),
        );
        return;
      }

      if (role == AppRole.teacher) {
        final username = _usernameController.text.trim();
        final password = _passwordController.text;
        await context.read<AuthService>().loginTeacher(username, password);
        await _persistCredentials(role, username, password);
        if (!mounted) return;
        context.read<AppState>().setMobileRole('Teacher');
        await _registerPush();
        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const MainShell()),
        );
        return;
      }

      if (role == AppRole.admin) {
        final username = _usernameController.text.trim();
        final password = _passwordController.text;
        await context.read<AdminService>().login(username, password);
        await _persistCredentials(role, username, password);
        if (!mounted) return;
        context.read<AppState>().setMobileRole('Admin');
        await _registerPush();
        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const AdminShell()),
        );
        return;
      }

      if (role == AppRole.driver) {
        final username = _usernameController.text.trim();
        final password = _passwordController.text;
        await context.read<DriverService>().login(username, password);
        await _persistCredentials(role, username, password);
        if (!mounted) return;
        context.read<AppState>().setMobileRole('Driver');
        await _registerPush();
        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const DriverShell()),
        );
        return;
      }

      final studentUser = _usernameController.text.trim();
      final studentPass = _passwordController.text;
      await context.read<AuthService>().loginStudent(studentUser, studentPass);
      await _persistCredentials(role, studentUser, studentPass);
      if (!mounted) return;
      context.read<AppState>().setMobileRole('Student');
      context.read<AppState>().refresh();
      await _registerPush();
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MainShell()),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final variant = context.watch<AppVariantConfig>();
    final allowedRoles = variant.allowedRoles;
    final activeRole = variant.singleRole ? variant.fixedRole : _selectedRole;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFEEF2FF), AppColors.background],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 440),
                      child: Column(
                        children: [
                    FadeSlideIn(
                      child: const AppLogo(
                        width: 140,
                        padding: EdgeInsets.all(14),
                        borderRadius: 24,
                      ),
                    ),
                    const SizedBox(height: 20),
                    FadeSlideIn(
                      delay: const Duration(milliseconds: 60),
                      child: Text(
                        AppBranding.nameAr,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: AppColors.primary,
                            ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    FadeSlideIn(
                      delay: const Duration(milliseconds: 80),
                      child: Text(
                        variant.loginTitle,
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    FadeSlideIn(
                      delay: const Duration(milliseconds: 120),
                      child: Text(
                        variant.loginSubtitle,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    FadeSlideIn(
                      delay: const Duration(milliseconds: 160),
                      child: AppCard(
                        padding: const EdgeInsets.all(22),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              if (!variant.singleRole) ...[
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: allowedRoles.map((role) {
                                    final labels = {
                                      AppRole.student: 'طالب',
                                      AppRole.parent: 'ولي أمر',
                                      AppRole.teacher: 'معلم',
                                      AppRole.admin: 'إدارة',
                                      AppRole.driver: 'سائق',
                                    };
                                    final icons = {
                                      AppRole.student: Icons.person_outline,
                                      AppRole.parent: Icons.family_restroom_rounded,
                                      AppRole.teacher: Icons.school_outlined,
                                      AppRole.admin: Icons.admin_panel_settings_outlined,
                                      AppRole.driver: Icons.local_taxi_rounded,
                                    };
                                    final selected = _selectedRole == role;
                                    return FilterChip(
                                      selected: selected,
                                      label: Text(labels[role]!),
                                      avatar: Icon(icons[role], size: 18),
                                      onSelected: (_) => setState(() => _selectedRole = role),
                                    );
                                  }).toList(),
                                ),
                                const SizedBox(height: 8),
                              ],
                              Text(
                                activeRole == AppRole.admin
                                    ? 'اسم المستخدم من لوحة التحكم (جدول Users)'
                                    : activeRole == AppRole.driver
                                        ? 'رقم هاتف السائق'
                                        : activeRole == AppRole.parent
                                            ? 'اسم المستخدم'
                                            : activeRole == AppRole.teacher
                                                ? 'بريد المعلم'
                                                : 'البريد أو رقم الجلوس',
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 20),
                              TextFormField(
                                controller: _usernameController,
                                textDirection: TextDirection.ltr,
                                keyboardType: activeRole == AppRole.driver
                                    ? TextInputType.phone
                                    : TextInputType.text,
                                decoration: InputDecoration(
                                  labelText: switch (activeRole) {
                                    AppRole.admin => 'اسم المستخدم',
                                    AppRole.parent => 'اسم المستخدم',
                                    AppRole.driver => 'رقم هاتف السائق',
                                    AppRole.teacher => 'بريد المعلم',
                                    AppRole.student => 'البريد أو رقم الجلوس',
                                  },
                                  prefixIcon: Icon(
                                    switch (activeRole) {
                                      AppRole.parent => Icons.badge_outlined,
                                      AppRole.driver => Icons.phone_android_rounded,
                                      AppRole.teacher => Icons.email_outlined,
                                      AppRole.admin => Icons.admin_panel_settings_outlined,
                                      AppRole.student => Icons.alternate_email_rounded,
                                    },
                                  ),
                                ),
                                validator: (v) {
                                  if (v == null || v.trim().isEmpty) {
                                    return activeRole == AppRole.parent
                                        ? 'اسم المستخدم مطلوب'
                                        : 'مطلوب';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 14),
                              TextFormField(
                                controller: _passwordController,
                                obscureText: _obscurePassword,
                                decoration: InputDecoration(
                                  labelText: 'كلمة المرور',
                                  prefixIcon: const Icon(Icons.lock_outline_rounded),
                                  suffixIcon: IconButton(
                                    onPressed: () => setState(
                                      () => _obscurePassword = !_obscurePassword,
                                    ),
                                    icon: Icon(
                                      _obscurePassword
                                          ? Icons.visibility_outlined
                                          : Icons.visibility_off_outlined,
                                    ),
                                  ),
                                ),
                                validator: (v) =>
                                    v == null || v.isEmpty ? 'مطلوب' : null,
                              ),
                              const SizedBox(height: 8),
                              CheckboxListTile(
                                value: _rememberMe,
                                onChanged: (v) => setState(() => _rememberMe = v ?? false),
                                contentPadding: EdgeInsets.zero,
                                controlAffinity: ListTileControlAffinity.leading,
                                title: const Text('تذكرني وأبقني مسجلاً'),
                                subtitle: const Text(
                                  'يحفظ اسم المستخدم وكلمة المرور ويعيد الدخول تلقائياً',
                                  style: TextStyle(fontSize: 12),
                                ),
                              ),
                              const SizedBox(height: 12),
                              DecoratedBox(
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: AppColors.gradientPrimary,
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.primary.withValues(alpha: 0.28),
                                      blurRadius: 18,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: ElevatedButton(
                                  onPressed: _loading ? null : _submit,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    shadowColor: Colors.transparent,
                                    foregroundColor: Colors.white,
                                  ),
                                  child: _loading
                                      ? const SizedBox(
                                          width: 22,
                                          height: 22,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : const Text('تسجيل الدخول'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const LoginFooter(),
            ],
          ),
        ),
      ),
    );
  }
}
