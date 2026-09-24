import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app_state.dart';
import '../../core/theme/app_colors.dart';
import '../../features/communication/screens/communication_hub_screen.dart';
import '../attendance/attendance_screen.dart';
import '../dashboard/dashboard_screen.dart';
import '../grades/grades_screen.dart';
import '../homework/homework_screen.dart';
import '../profile/profile_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final role = context.watch<AppState>().communicationRole;
    final isStudent = role == 'Student';

    final pages = [
      if (isStudent) const DashboardScreen(),
      if (isStudent) const GradesScreen(),
      if (isStudent) const HomeworkScreen(),
      CommunicationHubScreen(role: role),
      const ProfileScreen(),
    ];

    final destinations = [
      if (isStudent)
        const NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home_rounded),
          label: 'الرئيسية',
        ),
      if (isStudent)
        const NavigationDestination(
          icon: Icon(Icons.bar_chart_outlined),
          selectedIcon: Icon(Icons.bar_chart_rounded),
          label: 'الدرجات',
        ),
      if (isStudent)
        const NavigationDestination(
          icon: Icon(Icons.assignment_outlined),
          selectedIcon: Icon(Icons.assignment_rounded),
          label: 'الواجبات',
        ),
      const NavigationDestination(
        icon: Icon(Icons.forum_outlined),
        selectedIcon: Icon(Icons.forum_rounded),
        label: 'التواصل',
      ),
      const NavigationDestination(
        icon: Icon(Icons.person_outline),
        selectedIcon: Icon(Icons.person_rounded),
        label: 'حسابي',
      ),
    ];

    if (_index >= pages.length) {
      _index = 0;
    }

    return Scaffold(
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.08),
              blurRadius: 24,
              offset: const Offset(0, -6),
            ),
          ],
        ),
        child: SafeArea(
          child: NavigationBar(
            selectedIndex: _index,
            onDestinationSelected: (value) => setState(() => _index = value),
            destinations: destinations,
          ),
        ),
      ),
      floatingActionButton: isStudent && _index == 0
          ? FloatingActionButton.extended(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const AttendanceScreen()),
                );
              },
              icon: const Icon(Icons.event_available_rounded),
              label: const Text('الحضور'),
            )
          : null,
    );
  }
}
