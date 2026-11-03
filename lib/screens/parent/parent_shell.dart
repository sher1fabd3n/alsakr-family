import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/unread_count_badge.dart';
import '../../features/communication/screens/communication_hub_screen.dart';
import '../../features/parent/screens/parent_child_hub_screen.dart';
import '../../features/parent/screens/parent_notifications_screen.dart';
import '../../features/parent/state/parent_child_context.dart';
import '../../features/parent/state/unread_badge_store.dart';
import '../../app_state.dart';
import '../../features/parent/widgets/child_switcher.dart';
import '../../services/push_notification_service.dart';
import '../../features/transportation/services/transportation_service.dart';
import 'parent_profile_screen.dart';

class ParentShell extends StatefulWidget {
  const ParentShell({super.key});

  @override
  State<ParentShell> createState() => _ParentShellState();
}

class _ParentShellState extends State<ParentShell> with WidgetsBindingObserver {
  int _index = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = context.read<ParentChildContext>();
      ctx.bootstrap(force: ctx.children.isEmpty || ctx.activeChild == null || ctx.error != null);
      context.read<UnreadBadgeStore>().refresh();
      context.read<PushNotificationService>().consumePending();
      context.read<PushNotificationService>().registerAfterLogin(
            context.read<TransportationService>(),
          );
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      context.read<UnreadBadgeStore>().refresh();
      context.read<PushNotificationService>().registerAfterLogin(
            context.read<TransportationService>(),
          );
    }
  }

  void _onDestinationSelected(int index) {
    setState(() => _index = index);
    context.read<UnreadBadgeStore>().refresh();
  }

  @override
  Widget build(BuildContext context) {
    final childCtx = context.watch<ParentChildContext>();
    final badges = context.watch<UnreadBadgeStore>();
    final activeId = childCtx.activeStudentId;
    final showCarousel = childCtx.children.isNotEmpty || childCtx.isLoading;

    final hubKey = ValueKey<int?>(activeId);

    final perms = context.watch<AppState>();
    final showNotifications = perms.parentCanNotifications;
    final showChat = perms.parentCanChat || perms.parentCanTickets;
    final pages = [
      ParentChildHubScreen(key: hubKey, embedded: true),
      if (showNotifications) ParentNotificationsScreen(active: _index == 1),
      if (showChat) const CommunicationHubScreen(role: 'Parent'),
      const ParentProfileScreen(),
    ];

    if (_index >= pages.length) {
      _index = 0;
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          if (showCarousel)
            DecoratedBox(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                  colors: AppColors.gradientPrimary,
                ),
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'مدرسة الصقر للغات',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.4,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        childCtx.childCount > 1
                            ? 'اسحب للتبديل بين ${childCtx.childCount} أبناء'
                            : 'الابن المرتبط',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.88),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const ChildSwitcher(showPageIndicator: true),
                    ],
                  ),
                ),
              ),
            ),
          Expanded(child: IndexedStack(index: _index, children: pages)),
        ],
      ),
      bottomNavigationBar: Material(
        elevation: 12,
        color: Theme.of(context).colorScheme.surface,
        child: SafeArea(
          top: false,
          child: NavigationBar(
            height: 68,
            selectedIndex: _index,
            onDestinationSelected: _onDestinationSelected,
            destinations: [
              const NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home_rounded),
                label: 'الرئيسية',
              ),
              if (showNotifications)
                NavigationDestination(
                  icon: UnreadCountBadge(
                    count: badges.notificationCount,
                    child: const Icon(Icons.notifications_outlined),
                  ),
                  selectedIcon: UnreadCountBadge(
                    count: badges.notificationCount,
                    child: const Icon(Icons.notifications_rounded),
                  ),
                  label: 'الإشعارات',
                ),
              if (showChat)
                NavigationDestination(
                  icon: UnreadCountBadge(
                    count: badges.chatCount,
                    child: const Icon(Icons.forum_outlined),
                  ),
                  selectedIcon: UnreadCountBadge(
                    count: badges.chatCount,
                    child: const Icon(Icons.forum_rounded),
                  ),
                  label: 'التواصل',
                ),
              const NavigationDestination(
                icon: Icon(Icons.person_outline),
                selectedIcon: Icon(Icons.person_rounded),
                label: 'حسابي',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
