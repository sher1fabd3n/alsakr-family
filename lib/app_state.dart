import 'package:flutter/foundation.dart';

import 'services/student_services.dart';

enum AppRole { student, parent, teacher, admin, driver }

class AppState extends ChangeNotifier {
  AppState(this._authService);

  final AuthService _authService;
  bool _bootstrapping = true;
  AppRole _role = AppRole.student;
  String? _mobileRole;
  final Map<String, bool> _parentPermissions = {};

  bool get bootstrapping => _bootstrapping;
  bool get isLoggedIn =>
      _authService.currentStudent != null ||
      _authService.currentParent != null ||
      _mobileRole != null;
  AppRole get role => _role;
  bool get isAdmin => _mobileRole == 'Admin';
  bool get isDriver => _mobileRole == 'Driver';
  bool get isParent => _mobileRole == 'Parent';
  String get communicationRole => _mobileRole ?? 'Student';

  bool parentCan(String key) => _parentPermissions[key] ?? true;
  bool get parentCanGrades => parentCan('grades');
  bool get parentCanReports => parentCan('reports');
  bool get parentCanAttendance => parentCan('attendance');
  bool get parentCanFees => parentCan('fees');
  bool get parentCanTransportation => parentCan('transportation');
  bool get parentCanEducation => parentCan('education');
  bool get parentCanChat => parentCan('chat');
  bool get parentCanTickets => parentCan('tickets');
  bool get parentCanNotifications => parentCan('notifications');

  Future<void> bootstrap() async {
    await _authService.restoreSession();
    _mobileRole = await _authService.readMobileRole();
    final parent = _authService.currentParent;
    if (parent != null) {
      setParentPermissions(parent.permissions, notify: false);
    }
    _bootstrapping = false;
    notifyListeners();
  }

  void setRole(AppRole role) {
    _role = role;
    notifyListeners();
  }

  void setMobileRole(String role) {
    _mobileRole = role;
    notifyListeners();
  }

  void setParentPermissions(Map<String, bool> map, {bool notify = true}) {
    _parentPermissions
      ..clear()
      ..addAll(map);
    if (notify) notifyListeners();
  }

  void clearSession() {
    _mobileRole = null;
    _parentPermissions.clear();
    notifyListeners();
  }

  void refresh() => notifyListeners();
}
