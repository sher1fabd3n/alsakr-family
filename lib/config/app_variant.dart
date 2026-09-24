import '../app_state.dart';

/// يحدد أي تطبيق مُثبَّت (طالب/ولي أمر، معلم، سائق، أدمن).
class AppVariantConfig {
  const AppVariantConfig({
    required this.id,
    required this.appTitle,
    required this.loginTitle,
    required this.loginSubtitle,
    required this.allowedRoles,
    required this.defaultRole,
  });

  final String id;
  final String appTitle;
  final String loginTitle;
  final String loginSubtitle;
  final List<AppRole> allowedRoles;
  final AppRole defaultRole;

  bool get singleRole => allowedRoles.length == 1;
  AppRole get fixedRole => allowedRoles.single;

  bool allowsSession({String? mobileRole, bool hasStudentProfile = false}) {
    final role = mobileRoleToAppRole(mobileRole, hasStudentProfile: hasStudentProfile);
    return role != null && allowedRoles.contains(role);
  }
}

AppRole? mobileRoleToAppRole(String? mobileRole, {bool hasStudentProfile = false}) {
  if (mobileRole == null || mobileRole.isEmpty) {
    return hasStudentProfile ? AppRole.student : null;
  }
  return switch (mobileRole) {
    'Student' => AppRole.student,
    'Parent' => AppRole.parent,
    'Teacher' => AppRole.teacher,
    'Admin' => AppRole.admin,
    'Driver' => AppRole.driver,
    _ => null,
  };
}

abstract final class AppVariants {
  static const family = AppVariantConfig(
    id: 'family',
    appTitle: 'الصقر - ولي الأمر',
    loginTitle: 'مرحباً بعودتك',
    loginSubtitle: 'سجّل الدخول باسم المستخدم',
    allowedRoles: [AppRole.parent],
    defaultRole: AppRole.parent,
  );

  static const teacher = AppVariantConfig(
    id: 'teacher',
    appTitle: 'الصقر - المعلم',
    loginTitle: 'تطبيق المعلم',
    loginSubtitle: 'سجّل الدخول بحساب المعلم',
    allowedRoles: [AppRole.teacher],
    defaultRole: AppRole.teacher,
  );

  static const driver = AppVariantConfig(
    id: 'driver',
    appTitle: 'الصقر - السائق',
    loginTitle: 'تطبيق السائق',
    loginSubtitle: 'سجّل الدخول برقم هاتف السائق',
    allowedRoles: [AppRole.driver],
    defaultRole: AppRole.driver,
  );

  static const admin = AppVariantConfig(
    id: 'admin',
    appTitle: 'الصقر - الإدارة',
    loginTitle: 'تطبيق الإدارة',
    loginSubtitle: 'سجّل الدخول بحساب الأدمن',
    allowedRoles: [AppRole.admin],
    defaultRole: AppRole.admin,
  );
}
