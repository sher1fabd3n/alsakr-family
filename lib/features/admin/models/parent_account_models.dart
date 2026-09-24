enum ParentAccountStatus {
  active,
  inactive,
  pendingValidation,
  invalidNationalId;

  static ParentAccountStatus fromString(String? value) => switch (value?.toLowerCase()) {
        'active' => ParentAccountStatus.active,
        'inactive' => ParentAccountStatus.inactive,
        'pendingvalidation' || 'pending_validation' => ParentAccountStatus.pendingValidation,
        'invalidnationalid' || 'invalid_national_id' => ParentAccountStatus.invalidNationalId,
        _ => ParentAccountStatus.pendingValidation,
      };

  String get apiValue => switch (this) {
        ParentAccountStatus.active => 'Active',
        ParentAccountStatus.inactive => 'Inactive',
        ParentAccountStatus.pendingValidation => 'PendingValidation',
        ParentAccountStatus.invalidNationalId => 'InvalidNationalId',
      };

  String get labelAr => switch (this) {
        ParentAccountStatus.active => 'نشط',
        ParentAccountStatus.inactive => 'غير نشط',
        ParentAccountStatus.pendingValidation => 'بانتظار التحقق',
        ParentAccountStatus.invalidNationalId => 'رقم قومي غير صالح',
      };
}

enum ParentType {
  father,
  mother;

  static ParentType fromString(String? value) => switch (value?.toLowerCase()) {
        'mother' => ParentType.mother,
        _ => ParentType.father,
      };

  String get apiValue => switch (this) {
        ParentType.father => 'Father',
        ParentType.mother => 'Mother',
      };

  String get labelAr => switch (this) {
        ParentType.father => 'أب',
        ParentType.mother => 'أم',
      };
}

enum ParentAuditAction {
  accountCreation,
  passwordReset,
  nationalIdChange,
  studentLinking,
  studentUnlinking,
  accountActivation,
  accountDeactivation,
  accountRegeneration,
  unknown;

  static ParentAuditAction fromString(String? value) => switch (value?.toLowerCase()) {
        'accountcreation' || 'account_creation' => ParentAuditAction.accountCreation,
        'passwordreset' || 'password_reset' => ParentAuditAction.passwordReset,
        'nationalidchange' || 'national_id_change' => ParentAuditAction.nationalIdChange,
        'studentlinking' || 'student_linking' => ParentAuditAction.studentLinking,
        'studentunlinking' || 'student_unlinking' => ParentAuditAction.studentUnlinking,
        'accountactivation' || 'account_activation' => ParentAuditAction.accountActivation,
        'accountdeactivation' || 'account_deactivation' => ParentAuditAction.accountDeactivation,
        'accountregeneration' || 'account_regeneration' => ParentAuditAction.accountRegeneration,
        _ => ParentAuditAction.unknown,
      };

  String get labelAr => switch (this) {
        ParentAuditAction.accountCreation => 'إنشاء حساب',
        ParentAuditAction.passwordReset => 'إعادة تعيين كلمة المرور',
        ParentAuditAction.nationalIdChange => 'تغيير الرقم القومي',
        ParentAuditAction.studentLinking => 'ربط طالب',
        ParentAuditAction.studentUnlinking => 'إلغاء ربط طالب',
        ParentAuditAction.accountActivation => 'تفعيل الحساب',
        ParentAuditAction.accountDeactivation => 'إلغاء تفعيل الحساب',
        ParentAuditAction.accountRegeneration => 'إعادة إنشاء الحساب',
        ParentAuditAction.unknown => 'عملية',
      };
}

class LinkedStudentSummary {
  final int studentId;
  final int rollNo;
  final String name;
  final String grade;

  const LinkedStudentSummary({
    required this.studentId,
    required this.rollNo,
    required this.name,
    required this.grade,
  });

  factory LinkedStudentSummary.fromJson(Map<String, dynamic> json) => LinkedStudentSummary(
        studentId: _asInt(json['studentId'] ?? json['id']),
        rollNo: _asInt(json['rollNo']),
        name: json['name'] as String? ?? json['studentName'] as String? ?? '',
        grade: json['grade'] as String? ?? '',
      );
}

class ParentAccountSummary {
  final int id;
  final String nationalId;
  final String fullName;
  final String? phone;
  final String? email;
  final ParentType parentType;
  final ParentAccountStatus status;
  final int linkedStudentsCount;
  final DateTime? createdAt;

  const ParentAccountSummary({
    required this.id,
    required this.nationalId,
    required this.fullName,
    this.phone,
    this.email,
    required this.parentType,
    required this.status,
    required this.linkedStudentsCount,
    this.createdAt,
  });

  factory ParentAccountSummary.fromJson(Map<String, dynamic> json) => ParentAccountSummary(
        id: json['id'] as int,
        nationalId: json['nationalId'] as String? ?? json['username'] as String? ?? '',
        fullName: json['fullName'] as String? ?? json['name'] as String? ?? '',
        phone: json['phone'] as String?,
        email: json['email'] as String?,
        parentType: ParentType.fromString(json['parentType'] as String?),
        status: ParentAccountStatus.fromString(json['status'] as String?),
        linkedStudentsCount: json['linkedStudentsCount'] as int? ?? 0,
        createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'] as String) : null,
      );
}

class ParentAccountDetail extends ParentAccountSummary {
  final List<LinkedStudentSummary> linkedStudents;
  final bool requiresPasswordChange;
  final DateTime? lastLoginAt;
  final bool isActive;
  final Map<String, bool> permissions;

  const ParentAccountDetail({
    required super.id,
    required super.nationalId,
    required super.fullName,
    super.phone,
    super.email,
    required super.parentType,
    required super.status,
    required super.linkedStudentsCount,
    super.createdAt,
    this.linkedStudents = const [],
    this.requiresPasswordChange = false,
    this.lastLoginAt,
    this.isActive = true,
    this.permissions = const {},
  });

  factory ParentAccountDetail.fromJson(Map<String, dynamic> json) {
    final students = (json['linkedStudents'] as List<dynamic>?)
            ?.map((e) => LinkedStudentSummary.fromJson(e as Map<String, dynamic>))
            .toList() ??
        const <LinkedStudentSummary>[];
    return ParentAccountDetail(
      id: json['id'] as int,
      nationalId: json['nationalId'] as String? ?? json['username'] as String? ?? '',
      fullName: json['fullName'] as String? ?? json['name'] as String? ?? '',
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      parentType: ParentType.fromString(json['parentType'] as String?),
      status: ParentAccountStatus.fromString(json['status'] as String?),
      linkedStudentsCount: json['linkedStudentsCount'] as int? ?? students.length,
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'] as String) : null,
      linkedStudents: students,
      requiresPasswordChange: json['requiresPasswordChange'] as bool? ?? false,
      lastLoginAt: json['lastLoginAt'] != null ? DateTime.tryParse(json['lastLoginAt'] as String) : null,
      isActive: json['isActive'] as bool? ?? true,
      permissions: parsePermissionMap(json['permissions']),
    );
  }
}

class InvalidParentIdRecord {
  final int id;
  final int studentId;
  final int rollNo;
  final String studentName;
  final String grade;
  final ParentType parentType;
  final String? invalidId;
  final String validationMessage;
  final DateTime? flaggedAt;

  const InvalidParentIdRecord({
    required this.id,
    required this.studentId,
    required this.rollNo,
    required this.studentName,
    required this.grade,
    required this.parentType,
    this.invalidId,
    required this.validationMessage,
    this.flaggedAt,
  });

  factory InvalidParentIdRecord.fromJson(Map<String, dynamic> json) => InvalidParentIdRecord(
        id: json['id'] as int,
        studentId: json['studentId'] as int,
        rollNo: json['rollNo'] as int? ?? 0,
        studentName: json['studentName'] as String? ?? '',
        grade: json['grade'] as String? ?? '',
        parentType: ParentType.fromString(json['parentType'] as String?),
        invalidId: json['invalidId'] as String? ?? json['fatherId'] as String? ?? json['motherId'] as String?,
        validationMessage: json['validationMessage'] as String? ?? 'رقم قومي غير صالح',
        flaggedAt: json['flaggedAt'] != null ? DateTime.tryParse(json['flaggedAt'] as String) : null,
      );
}

class ParentAuditLogEntry {
  final int id;
  final ParentAuditAction action;
  final String performedBy;
  final DateTime performedAt;
  final String? oldValue;
  final String? newValue;
  final String? parentNationalId;
  final String? notes;

  const ParentAuditLogEntry({
    required this.id,
    required this.action,
    required this.performedBy,
    required this.performedAt,
    this.oldValue,
    this.newValue,
    this.parentNationalId,
    this.notes,
  });

  factory ParentAuditLogEntry.fromJson(Map<String, dynamic> json) => ParentAuditLogEntry(
        id: json['id'] as int,
        action: ParentAuditAction.fromString(json['action'] as String?),
        performedBy: json['performedBy'] as String? ?? json['userName'] as String? ?? '',
        performedAt: DateTime.tryParse(json['performedAt'] as String? ?? '') ?? DateTime.now(),
        oldValue: json['oldValue'] as String?,
        newValue: json['newValue'] as String?,
        parentNationalId: json['parentNationalId'] as String? ?? json['nationalId'] as String?,
        notes: json['notes'] as String?,
      );
}

class ParentProfile {
  final int id;
  final String nationalId;
  final String fullName;
  final String? phone;
  final String? email;
  final ParentType parentType;
  final ParentAccountStatus status;
  final bool requiresPasswordChange;
  final bool requiresPhoneConfirmation;
  final bool requiresEmailConfirmation;
  final List<LinkedStudentSummary> linkedStudents;
  final Map<String, bool> permissions;

  const ParentProfile({
    required this.id,
    required this.nationalId,
    required this.fullName,
    this.phone,
    this.email,
    required this.parentType,
    required this.status,
    this.requiresPasswordChange = false,
    this.requiresPhoneConfirmation = false,
    this.requiresEmailConfirmation = false,
    this.linkedStudents = const [],
    this.permissions = const {},
  });

  bool hasFeature(String key) => permissions[key] ?? true;

  /// إعداد أول دخول — تأكيد الهاتف/البريد فقط. تغيير كلمة المرور اختياري.
  bool get needsFirstLoginSetup =>
      requiresPhoneConfirmation || requiresEmailConfirmation;

  bool get canLogin => status == ParentAccountStatus.active;

  factory ParentProfile.fromJson(Map<String, dynamic> json) {
    final rawStudents = json['linkedStudents'] ?? json['LinkedStudents'] ?? json['children'];
    final students = (rawStudents as List<dynamic>?)
            ?.map((e) => LinkedStudentSummary.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList() ??
        const <LinkedStudentSummary>[];
    return ParentProfile(
      id: _asInt(json['id'] ?? json['Id']),
      nationalId: json['nationalId'] as String? ??
          json['NationalId'] as String? ??
          json['username'] as String? ??
          '',
      fullName: json['fullName'] as String? ?? json['FullName'] as String? ?? '',
      phone: json['phone'] as String? ?? json['Phone'] as String?,
      email: json['email'] as String? ?? json['Email'] as String?,
      parentType: ParentType.fromString(
        (json['parentType'] ?? json['ParentType'])?.toString(),
      ),
      status: ParentAccountStatus.fromString(
        (json['status'] ?? json['Status'])?.toString(),
      ),
      requiresPasswordChange: json['requiresPasswordChange'] as bool? ?? false,
      requiresPhoneConfirmation: json['requiresPhoneConfirmation'] as bool? ?? false,
      requiresEmailConfirmation: json['requiresEmailConfirmation'] as bool? ?? false,
      linkedStudents: students,
      permissions: parsePermissionMap(json['permissions'] ?? json['Permissions']),
    );
  }
}

Map<String, bool> parsePermissionMap(dynamic raw) {
  if (raw is! Map) return const {};
  return {
    for (final entry in raw.entries) entry.key.toString(): entry.value == true,
  };
}

int _asInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}

class ParentLoginResponse {
  final String token;
  final DateTime? expiresAt;
  final ParentProfile profile;

  const ParentLoginResponse({
    required this.token,
    this.expiresAt,
    required this.profile,
  });

  factory ParentLoginResponse.fromJson(Map<String, dynamic> json) {
    final profileRaw = json['profile'] ?? json['Profile'] ?? json;
    final profileJson = Map<String, dynamic>.from(profileRaw as Map);
    final token = json['token'] ?? json['Token'];
    if (token is! String || token.isEmpty) {
      throw const FormatException('رد تسجيل الدخول لا يحتوي على توكن.');
    }
    return ParentLoginResponse(
      token: token,
      expiresAt: json['expiresAt'] != null || json['ExpiresAt'] != null
          ? DateTime.tryParse((json['expiresAt'] ?? json['ExpiresAt']).toString())
          : null,
      profile: ParentProfile.fromJson(profileJson),
    );
  }
}
