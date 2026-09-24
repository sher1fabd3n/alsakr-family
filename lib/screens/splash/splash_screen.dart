import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app_state.dart';
import '../../config/app_variant.dart';
import '../../core/constants/app_branding.dart';
import '../../core/widgets/app_logo.dart';
import '../../features/parent/state/parent_child_context.dart';
import '../../features/parent/state/unread_badge_store.dart';
import '../../features/transportation/services/transportation_service.dart';
import '../../services/api_client.dart';
import '../../services/app_update_service.dart';
import '../../services/push_notification_service.dart';
import '../../services/remembered_credentials.dart';
import '../../services/student_services.dart';
import '../../features/admin/screens/admin_shell.dart';
import '../../features/driver/screens/driver_shell.dart';
import '../auth/login_screen.dart';
import '../parent/parent_first_login_screen.dart';
import '../parent/parent_shell.dart';
import '../shell/main_shell.dart';
import '../update/force_update_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _scale = Tween<double>(begin: 0.8, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _controller.forward();
    _navigateNext();
  }

  Future<void> _navigateNext() async {
    final variant = context.read<AppVariantConfig>();
    final appState = context.read<AppState>();
    final auth = context.read<AuthService>();

    while (appState.bootstrapping) {
      await Future<void>.delayed(const Duration(milliseconds: 120));
    }

    if (!mounted) return;
    try {
      final update = await AppUpdateService(context.read<ApiClient>()).check(app: 'family');
      if (!mounted) return;
      if (update != null && update.updateRequired) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => ForceUpdateScreen(info: update)),
        );
        return;
      }
    } catch (_) {}

    if (appState.isLoggedIn) {
      final mobileRole = await auth.readMobileRole();
      final hasStudentProfile = auth.currentStudent != null;
      final hasParentProfile = auth.currentParent != null;
      if (!variant.allowsSession(
        mobileRole: mobileRole,
        hasStudentProfile: hasStudentProfile || hasParentProfile,
      )) {
        await auth.logout();
        appState.clearSession();
      }
    }

    if (!mounted) return;
    if (!appState.isLoggedIn) {
      await RememberedLogin.tryRestore(context);
    }

    await Future<void>.delayed(const Duration(milliseconds: 1400));
    if (!mounted) return;

    if (appState.isLoggedIn) {
      try {
        await context.read<PushNotificationService>().registerAfterLogin(
              context.read<TransportationService>(),
            );
      } catch (_) {}
    }

    if (!mounted) return;

    if (appState.isLoggedIn && appState.isParent) {
      final parent = auth.currentParent;
      if (parent != null) {
        appState.setParentPermissions(parent.permissions);
      }
      if (parent != null && !parent.needsFirstLoginSetup) {
        final childCtx = context.read<ParentChildContext>();
        final badges = context.read<UnreadBadgeStore>();
        try {
          await childCtx.bootstrap();
        } catch (_) {}
        try {
          await badges.refresh();
        } catch (_) {}
      }
    }

    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 500),
        pageBuilder: (context, animation, secondaryAnimation) {
          if (!appState.isLoggedIn) return const LoginScreen();
          if (appState.isAdmin) return const AdminShell();
          if (appState.isDriver) return const DriverShell();
          if (appState.isParent) {
            final parent = auth.currentParent;
            if (parent != null && parent.needsFirstLoginSetup) {
              return const ParentFirstLoginScreen();
            }
            return const ParentShell();
          }
          return const MainShell();
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final variant = context.watch<AppVariantConfig>();

    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [
              Color(0xFF4F46E5),
              Color(0xFF7C3AED),
              Color(0xFF06B6D4),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const Spacer(),
              ScaleTransition(
                scale: _scale,
                child: FadeTransition(
                  opacity: _fade,
                  child: Column(
                    children: [
                      AppLogo(
                        width: 160,
                        padding: const EdgeInsets.all(16),
                        borderRadius: 28,
                      ),
                      const SizedBox(height: 24),
                      Text(
                        variant.appTitle,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        AppBranding.tagline,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: Colors.white.withValues(alpha: 0.9),
                            ),
                      ),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              const Padding(
                padding: EdgeInsets.only(bottom: 36),
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
