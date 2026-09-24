import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app_state.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/student_avatar.dart';
import '../../features/admin/models/parent_account_models.dart';
import '../../features/parent/state/parent_child_context.dart';
import '../../features/parent/state/unread_badge_store.dart';
import '../../features/parent/widgets/child_photo_actions.dart';
import '../../services/student_services.dart';
import '../auth/login_screen.dart';
import 'parent_change_password_screen.dart';

const _supportPhone = '01029779141';

class ParentProfileScreen extends StatelessWidget {
  const ParentProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<AuthService>().currentParent;

    if (profile == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const SizedBox(height: 12),
            CircleAvatar(
              radius: 40,
              backgroundColor: AppColors.primary.withValues(alpha: 0.12),
              child: Icon(
                profile.parentType == ParentType.father ? Icons.man_rounded : Icons.woman_rounded,
                size: 40,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              profile.fullName.isNotEmpty ? profile.fullName : 'ولي أمر',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            Text(
              profile.nationalId,
              textAlign: TextAlign.center,
              textDirection: TextDirection.ltr,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 8),
            Center(child: Chip(label: Text(profile.status.labelAr))),
            const SizedBox(height: 24),
            _ProfileTile(icon: Icons.phone_rounded, label: 'الهاتف', value: profile.phone ?? '—'),
            _ProfileTile(icon: Icons.email_outlined, label: 'البريد', value: profile.email ?? '—'),
            _ProfileTile(
              icon: Icons.family_restroom_rounded,
              label: 'الأبناء المرتبطون',
              value: '${profile.linkedStudents.length}',
            ),
            const SizedBox(height: 16),
            const Text(
              'صور الأبناء',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              'اضغط على صورة الابن لتغييرها',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
            const SizedBox(height: 12),
            ...context.watch<ParentChildContext>().children.map(
              (child) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: StudentAvatar(
                    studentId: child.studentId,
                    name: child.name,
                    photoUrl: child.profilePhotoUrl,
                    radius: 28,
                    onEditPhoto: () => ChildPhotoActions.pickAndUpload(context, child.studentId),
                  ),
                  title: Text(child.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: Text(child.grade),
                ),
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ParentChangePasswordScreen()),
                ),
                icon: const Icon(Icons.lock_reset_rounded),
                label: const Text('تغيير كلمة المرور'),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _logout(context),
                icon: const Icon(Icons.logout_rounded),
                label: const Text('تسجيل الخروج'),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.danger,
                  side: const BorderSide(color: AppColors.danger),
                ),
                onPressed: () => _showDeleteAccountDialog(context),
                icon: const Icon(Icons.person_off_outlined),
                label: const Text('إزالة المستخدم'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _logout(BuildContext context) async {
    final childCtx = context.read<ParentChildContext>();
    final badges = context.read<UnreadBadgeStore>();
    final auth = context.read<AuthService>();
    final appState = context.read<AppState>();
    childCtx.clear();
    await badges.reset();
    await auth.logout();
    if (!context.mounted) return;
    appState.clearSession();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  Future<void> _showDeleteAccountDialog(BuildContext context) async {
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('إزالة المستخدم'),
        content: const Text(
          'لإزالة حسابك من التطبيق، يرجى التواصل مع الدعم الفني.\n\n'
          'الهاتف: $_supportPhone',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إغلاق'),
          ),
          FilledButton.icon(
            onPressed: () async {
              Navigator.pop(ctx);
              final uri = Uri(scheme: 'tel', path: _supportPhone);
              await launchUrl(uri);
            },
            icon: const Icon(Icons.call_rounded),
            label: const Text('اتصال بالدعم'),
          ),
        ],
      ),
    );
  }
}

class _ProfileTile extends StatelessWidget {
  const _ProfileTile({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary),
      title: Text(label),
      trailing: Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
    );
  }
}
