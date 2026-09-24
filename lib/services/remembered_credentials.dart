import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_state.dart';
import '../config/app_variant.dart';
import '../features/admin/services/admin_service.dart';
import '../features/driver/services/driver_service.dart';
import 'api_client.dart';
import 'student_services.dart';

class SavedLogin {
  const SavedLogin({
    required this.username,
    required this.password,
    required this.role,
  });

  final String username;
  final String password;
  final String role;
}

class RememberedCredentials {
  RememberedCredentials(this._api);

  static const _rememberKey = 'remember_me';
  static const _userKey = 'remember_username';
  static const _passKey = 'remember_password';
  static const _roleKey = 'remember_role';

  final ApiClient _api;

  Future<void> save({
    required String username,
    required String password,
    required String role,
  }) async {
    await _api.writeSecure(_rememberKey, '1');
    await _api.writeSecure(_userKey, username);
    await _api.writeSecure(_passKey, password);
    await _api.writeSecure(_roleKey, role);
  }

  Future<void> updatePassword(String password) async {
    final saved = await read();
    if (saved == null) return;
    await _api.writeSecure(_passKey, password);
  }

  Future<SavedLogin?> read() async {
    final enabled = await _api.readSecure(_rememberKey);
    if (enabled != '1') return null;
    final username = await _api.readSecure(_userKey);
    final password = await _api.readSecure(_passKey);
    final role = await _api.readSecure(_roleKey);
    if (username == null ||
        username.isEmpty ||
        password == null ||
        password.isEmpty) {
      return null;
    }
    return SavedLogin(
      username: username,
      password: password,
      role: role ?? '',
    );
  }

  Future<void> clear() async {
    await _api.deleteSecure(_rememberKey);
    await _api.deleteSecure(_userKey);
    await _api.deleteSecure(_passKey);
    await _api.deleteSecure(_roleKey);
  }

  static AppRole? parseRole(String? value) {
    return switch (value) {
      'student' => AppRole.student,
      'parent' => AppRole.parent,
      'teacher' => AppRole.teacher,
      'admin' => AppRole.admin,
      'driver' => AppRole.driver,
      _ => null,
    };
  }
}

class RememberedLogin {
  static Future<bool> tryRestore(BuildContext context) async {
    final api = context.read<ApiClient>();
    final saved = await RememberedCredentials(api).read();
    if (saved == null || !context.mounted) return false;

    final variant = context.read<AppVariantConfig>();
    final role = RememberedCredentials.parseRole(saved.role) ?? variant.defaultRole;
    if (!variant.allowedRoles.contains(role)) return false;

    final appState = context.read<AppState>();
    appState.setRole(role);

    try {
      switch (role) {
        case AppRole.parent:
          final parentLogin = await context.read<AuthService>().loginParent(saved.username, saved.password);
          appState.setMobileRole('Parent');
          appState.setParentPermissions(parentLogin.profile.permissions);
          break;
        case AppRole.teacher:
          await context.read<AuthService>().loginTeacher(saved.username, saved.password);
          appState.setMobileRole('Teacher');
          break;
        case AppRole.admin:
          await context.read<AdminService>().login(saved.username, saved.password);
          appState.setMobileRole('Admin');
          break;
        case AppRole.driver:
          await context.read<DriverService>().login(saved.username, saved.password);
          appState.setMobileRole('Driver');
          break;
        case AppRole.student:
          await context.read<AuthService>().loginStudent(saved.username, saved.password);
          appState.setMobileRole('Student');
          break;
      }
      return true;
    } catch (_) {
      return false;
    }
  }
}
