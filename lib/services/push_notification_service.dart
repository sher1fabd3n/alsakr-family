import 'dart:convert';
import 'dart:io';

import 'package:app_badge_plus/app_badge_plus.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../features/transportation/services/transportation_service.dart';
import 'api_client.dart';

const _schoolChannelId = 'school_lock_alerts';
const _schoolChannelName = 'تنبيهات المدرسة';

AndroidNotificationChannel get _lockChannel => const AndroidNotificationChannel(
      _schoolChannelId,
      _schoolChannelName,
      description: 'إشعارات التقارير والنتائج والرسائل على شاشة القفل',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
      showBadge: true,
    );

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  // إذا وصلت رسالة Notification من FCM فالنظام يعرضها بنفسه والتطبيق مغلق أو في الخلفية.
  if (message.notification != null) return;
  await showLockScreenNotification(message);
}

Future<void> showLockScreenNotification(RemoteMessage message) async {
  final type = message.data['type']?.toString() ?? 'report';
  final title = message.notification?.title ??
      message.data['title'] ??
      defaultTitleForPushType(type);
  final body = message.notification?.body ?? message.data['body'] ?? '';
  if (title.toString().trim().isEmpty && body.toString().trim().isEmpty) {
    return;
  }

  final plugin = FlutterLocalNotificationsPlugin();
  await plugin.initialize(
    const InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    ),
  );
  final android = plugin.resolvePlatformSpecificImplementation<
      AndroidFlutterLocalNotificationsPlugin>();
  await android?.createNotificationChannel(_lockChannel);

  await plugin.show(
    message.hashCode.abs(),
    title.toString(),
    body.toString(),
    NotificationDetails(
      android: AndroidNotificationDetails(
        _schoolChannelId,
        _schoolChannelName,
        channelDescription: _lockChannel.description,
        importance: Importance.max,
        priority: Priority.max,
        visibility: NotificationVisibility.public,
        playSound: true,
        enableVibration: true,
        icon: '@drawable/ic_stat_school',
        category: AndroidNotificationCategory.message,
        autoCancel: true,
        channelShowBadge: true,
        ticker: title.toString(),
      ),
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        interruptionLevel: InterruptionLevel.timeSensitive,
      ),
    ),
    payload: jsonEncode({
      ...message.data.map((k, v) => MapEntry(k, v.toString())),
      'type': type,
    }),
  );
}

String defaultTitleForPushType(String type) {
  switch (type) {
    case 'chat':
      return 'رسالة جديدة';
    case 'report':
      return 'تقرير جديد';
    case 'result':
      return 'نتيجة امتحان';
    case 'ticket':
      return 'رد على الشكوى';
    case 'announcement':
      return 'إعلان مدرسي';
    case 'emergency':
      return 'إعلان عاجل';
    case 'attendance':
      return 'تنبيه حضور';
    default:
      return 'تنبيه المدرسة';
  }
}

class PushNotificationService {
  PushNotificationService(ApiClient _);

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  int _badgeCount = 0;

  void Function(String type)? onIncomingMessage;
  void Function(Map<String, String> data)? onOpenedFromNotification;
  Map<String, String>? pendingOpen;

  Future<void> initialize() async {
    if (_initialized) return;
    try {
      await Firebase.initializeApp();
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      await _setupLocalNotifications();

      final messaging = FirebaseMessaging.instance;
      await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        announcement: false,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
      );
      await messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      FirebaseMessaging.onMessage.listen(_showForegroundNotification);
      FirebaseMessaging.onMessageOpenedApp.listen((message) {
        _open(_dataFrom(message));
      });
      final initial = await FirebaseMessaging.instance.getInitialMessage();
      if (initial != null) {
        pendingOpen = _dataFrom(initial);
      }

      _initialized = true;
    } catch (_) {
      // Firebase not configured — app still works without push.
    }
  }

  Future<void> registerAfterLogin(
    TransportationService transportationService,
  ) async {
    if (!_initialized) {
      await initialize();
    }
    if (!_initialized) return;
    for (var attempt = 0; attempt < 3; attempt++) {
      try {
        final token = await FirebaseMessaging.instance.getToken();
        if (token != null) {
          await transportationService.registerPushToken(
            token,
            platform: Platform.isIOS ? 'ios' : 'android',
          );
          break;
        }
      } catch (_) {
        await Future<void>.delayed(Duration(milliseconds: 400 * (attempt + 1)));
      }
    }
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
      try {
        await transportationService.registerPushToken(
          newToken,
          platform: Platform.isIOS ? 'ios' : 'android',
        );
      } catch (_) {}
    });
  }

  Future<void> _setupLocalNotifications() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();
    const initSettings = InitializationSettings(
      android: androidInit,
      iOS: iosInit,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (response) {
        _open(_decodePayload(response.payload));
      },
    );

    final androidPlugin = _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.requestNotificationsPermission();
    await androidPlugin?.createNotificationChannel(_lockChannel);
  }

  Future<void> _showForegroundNotification(RemoteMessage message) async {
    await showLockScreenNotification(message);
    final type = message.data['type']?.toString() ?? 'report';
    onIncomingMessage?.call(type);
    _badgeCount += 1;
    await syncLauncherBadge(_badgeCount);
  }

  Map<String, String> _dataFrom(RemoteMessage message) {
    return message.data.map((k, v) => MapEntry(k, v.toString()));
  }

  Map<String, String> _decodePayload(String? payload) {
    if (payload == null || payload.isEmpty) return {};
    try {
      final decoded = jsonDecode(payload);
      if (decoded is Map) {
        return decoded.map((k, v) => MapEntry(k.toString(), v.toString()));
      }
    } catch (_) {}
    return {'type': payload};
  }

  void _open(Map<String, String> data) {
    if (data.isEmpty) return;
    if (onOpenedFromNotification != null) {
      onOpenedFromNotification!(data);
    } else {
      pendingOpen = data;
    }
  }

  void consumePending() {
    final data = pendingOpen;
    pendingOpen = null;
    if (data != null) {
      onOpenedFromNotification?.call(data);
    }
  }

  Future<void> syncLauncherBadge(int count, {bool clearTray = false}) async {
    _badgeCount = count < 0 ? 0 : count;
    if (clearTray || _badgeCount == 0) {
      try {
        await _localNotifications.cancelAll();
      } catch (_) {}
    }
    try {
      await AppBadgePlus.updateBadge(_badgeCount);
    } catch (_) {}
  }

}
