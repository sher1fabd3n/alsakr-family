import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app_state.dart';
import '../../../core/theme/app_colors.dart';
import '../../../screens/auth/login_screen.dart';
import '../../../services/student_services.dart';
import 'admin_announcements_screen.dart';
import 'admin_conversations_screen.dart';
import 'admin_dashboard_screen.dart';

class AdminShell extends StatefulWidget {
  const AdminShell({super.key});

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int _index = 0;

  static const _pages = [
    AdminDashboardScreen(),
    AdminConversationsScreen(),
    AdminAnnouncementsScreen(),
    _AdminProfileTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (v) => setState(() => _index = v),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard_rounded),
            label: 'الرئيسية',
          ),
          NavigationDestination(
            icon: Icon(Icons.forum_outlined),
            selectedIcon: Icon(Icons.forum_rounded),
            label: 'المحادثات',
          ),
          NavigationDestination(
            icon: Icon(Icons.campaign_outlined),
            selectedIcon: Icon(Icons.campaign_rounded),
            label: 'الإعلانات',
          ),
          NavigationDestination(
            icon: Icon(Icons.admin_panel_settings_outlined),
            selectedIcon: Icon(Icons.admin_panel_settings_rounded),
            label: 'الحساب',
          ),
        ],
      ),
    );
  }
}

class _AdminProfileTab extends StatelessWidget {
  const _AdminProfileTab();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Icon(Icons.admin_panel_settings_rounded, size: 72, color: AppColors.primary),
              const SizedBox(height: 16),
              Text(
                'حساب الإدارة',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 8),
              const Text(
                'مراقبة التواصل المدرسي',
                style: TextStyle(color: AppColors.textSecondary),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    await context.read<AuthService>().logout();
                    if (!context.mounted) return;
                    context.read<AppState>().clearSession();
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                      (_) => false,
                    );
                  },
                  icon: const Icon(Icons.logout_rounded),
                  label: const Text('تسجيل الخروج'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
