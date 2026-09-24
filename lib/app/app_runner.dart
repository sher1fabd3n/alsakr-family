import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import '../app_state.dart';
import '../config/app_variant.dart';
import '../core/theme/app_theme.dart';
import '../features/education/services/education_content_service.dart';
import '../features/admin/services/admin_service.dart';
import '../features/admin/services/parent_account_service.dart';
import '../features/communication/services/communication_service.dart';
import '../features/driver/services/driver_service.dart';
import '../features/transportation/services/transportation_service.dart';
import '../features/parent/services/parent_family_service.dart';
import '../features/parent/state/parent_child_context.dart';
import '../features/parent/state/unread_badge_store.dart';
import '../features/tickets/services/ticket_service.dart';
import '../screens/splash/splash_screen.dart';
import '../services/api_client.dart';
import '../services/notification_router.dart';
import '../services/push_notification_service.dart';
import '../services/student_services.dart';

class _SchoolHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    final client = super.createHttpClient(context);
    client.badCertificateCallback =
        (cert, host, port) => ApiClient.isTrustedSchoolHost(host, cert);
    return client;
  }
}

Future<void> runAlsakrApp(AppVariantConfig variant) async {
  WidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = _SchoolHttpOverrides();

  final apiClient = ApiClient();
  final authService = AuthService(apiClient);
  final studentService = StudentService(apiClient);
  final communicationService = CommunicationService(apiClient);
  final adminService = AdminService(apiClient);
  final parentAccountService = ParentAccountService(apiClient);
  final parentFamilyService = ParentFamilyService(apiClient);
  final parentTicketService = ParentTicketService(apiClient);
  final adminTicketService = AdminTicketService(apiClient);
  final transportationService = TransportationService(apiClient);
  final driverService = DriverService(apiClient);
  final educationContentService = EducationContentService(apiClient);
  final pushService = PushNotificationService(apiClient);

  await pushService.initialize();

  runApp(
    MultiProvider(
      providers: [
        Provider<AppVariantConfig>.value(value: variant),
        Provider<ApiClient>.value(value: apiClient),
        ChangeNotifierProvider<AppState>(
          create: (_) => AppState(authService)..bootstrap(),
        ),
        Provider<AuthService>.value(value: authService),
        Provider<StudentService>.value(value: studentService),
        Provider<CommunicationService>.value(value: communicationService),
        Provider<AdminService>.value(value: adminService),
        Provider<ParentAccountService>.value(value: parentAccountService),
        Provider<ParentFamilyService>.value(value: parentFamilyService),
        Provider<ParentTicketService>.value(value: parentTicketService),
        Provider<AdminTicketService>.value(value: adminTicketService),
        ChangeNotifierProvider<ParentChildContext>(
          create: (ctx) => ParentChildContext(parentFamilyService, apiClient),
        ),
        ChangeNotifierProvider<UnreadBadgeStore>(
          create: (_) => UnreadBadgeStore(parentFamilyService, pushService),
        ),
        Provider<TransportationService>.value(value: transportationService),
        Provider<DriverService>.value(value: driverService),
        Provider<EducationContentService>.value(value: educationContentService),
        Provider<PushNotificationService>.value(value: pushService),
      ],
      child: AlsakrApp(variant: variant),
    ),
  );
}

class AlsakrApp extends StatelessWidget {
  const AlsakrApp({super.key, required this.variant});

  final AppVariantConfig variant;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: variant.appTitle,
      debugShowCheckedModeBanner: false,
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      builder: (context, child) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: child ?? const SizedBox.shrink(),
        );
      },
      navigatorKey: NotificationRouter.navigatorKey,
      home: const SplashScreen(),
    );
  }
}
