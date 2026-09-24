import 'package:flutter/foundation.dart';

import '../../../services/notification_router.dart';
import '../../../services/push_notification_service.dart';
import '../services/parent_family_service.dart';

class UnreadBadgeStore extends ChangeNotifier {
  UnreadBadgeStore(this._familyService, this._push) {
    _push.onIncomingMessage = _onIncoming;
    _push.onOpenedFromNotification = _onOpened;
  }

  final ParentFamilyService _familyService;
  final PushNotificationService _push;

  int notificationCount = 0;
  int chatCount = 0;
  bool _refreshing = false;

  int get total => notificationCount + chatCount;

  Future<void> refresh() async {
    if (_refreshing) return;
    _refreshing = true;
    try {
      final summary = await _familyService.getUnreadSummary();
      notificationCount = summary.notifications;
      chatCount = summary.chats;
      notifyListeners();
      await _push.syncLauncherBadge(total);
    } catch (_) {
    } finally {
      _refreshing = false;
    }
  }

  Future<void> markNotificationsOpened() async {
    notificationCount = 0;
    notifyListeners();
    await _push.syncLauncherBadge(total, clearTray: total == 0);
    try {
      final summary = await _familyService.markAllNotificationsRead();
      notificationCount = summary.notifications;
      chatCount = summary.chats;
      notifyListeners();
      await _push.syncLauncherBadge(total, clearTray: total == 0);
    } catch (_) {
      await refresh();
    }
  }

  Future<void> reset() async {
    notificationCount = 0;
    chatCount = 0;
    notifyListeners();
    await _push.syncLauncherBadge(0, clearTray: true);
  }

  Future<void> _onOpened(Map<String, String> data) async {
    await refresh();
    await NotificationRouter.open(data);
  }

  void _onIncoming(String type) {
    if (type == 'chat') {
      chatCount += 1;
    } else {
      notificationCount += 1;
    }
    notifyListeners();
    _push.syncLauncherBadge(total);
    refresh();
  }

  @override
  void dispose() {
    if (_push.onIncomingMessage == _onIncoming) {
      _push.onIncomingMessage = null;
    }
    if (_push.onOpenedFromNotification == _onOpened) {
      _push.onOpenedFromNotification = null;
    }
    super.dispose();
  }
}
