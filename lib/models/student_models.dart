class StudentProfile {
  final int id;
  final int rollNo;
  final String name;
  final String grade;
  final String? stage;
  final String emailAddress;
  final int phoneNumber;
  final String? profilePhotoUrl;
  final bool resultsBlocked;

  const StudentProfile({
    required this.id,
    required this.rollNo,
    required this.name,
    required this.grade,
    this.stage,
    required this.emailAddress,
    required this.phoneNumber,
    this.profilePhotoUrl,
    required this.resultsBlocked,
  });

  factory StudentProfile.fromJson(Map<String, dynamic> json) {
    return StudentProfile(
      id: json['id'] as int,
      rollNo: json['rollNo'] as int,
      name: json['name'] as String? ?? '',
      grade: json['grade'] as String? ?? '',
      stage: json['stage'] as String?,
      emailAddress: json['emailAddress'] as String? ?? '',
      phoneNumber: json['phoneNumber'] as int? ?? 0,
      profilePhotoUrl: json['profilePhotoUrl'] as String?,
      resultsBlocked: json['resultsBlocked'] as bool? ?? false,
    );
  }
}

class LoginResponse {
  final String token;
  final DateTime expiresAt;
  final StudentProfile student;

  const LoginResponse({
    required this.token,
    required this.expiresAt,
    required this.student,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      token: json['token'] as String,
      expiresAt: DateTime.parse(json['expiresAt'] as String),
      student: StudentProfile.fromJson(json['student'] as Map<String, dynamic>),
    );
  }
}

class StudentResult {
  final String subject;
  final String academicYear;
  final String month;
  final double monthlyAssessmentMark;
  final int monthlyMaxMark;
  final bool hasMonthlyAssessment;
  final double firstTermExamMark;
  final int examMaxMark;
  final double totalMark;
  final int totalMaxMark;
  final bool isMonthlyOnly;
  final bool isMonthlyAbsent;
  final bool isFirstTermAbsent;
  final double percentage;
  final String gradeText;
  final String color;

  const StudentResult({
    required this.subject,
    required this.academicYear,
    required this.month,
    required this.monthlyAssessmentMark,
    required this.monthlyMaxMark,
    required this.hasMonthlyAssessment,
    required this.firstTermExamMark,
    required this.examMaxMark,
    required this.totalMark,
    required this.totalMaxMark,
    required this.isMonthlyOnly,
    required this.isMonthlyAbsent,
    required this.isFirstTermAbsent,
    required this.percentage,
    required this.gradeText,
    required this.color,
  });

  factory StudentResult.fromJson(Map<String, dynamic> json) {
    final totalMark = (json['totalMark'] as num?)?.toDouble() ?? 0;
    final totalMaxMark = json['totalMaxMark'] as int? ?? 100;
    final percentage = totalMaxMark > 0 ? (totalMark / totalMaxMark) * 100 : 0.0;

    return StudentResult(
      subject: json['subject'] as String? ?? '',
      academicYear: json['academicYear'] as String? ?? '',
      month: json['month'] as String? ?? '',
      monthlyAssessmentMark:
          (json['monthlyAssessmentMark'] as num?)?.toDouble() ?? 0,
      monthlyMaxMark: json['monthlyMaxMark'] as int? ?? 0,
      hasMonthlyAssessment: json['hasMonthlyAssessment'] as bool? ?? false,
      firstTermExamMark: (json['firstTermExamMark'] as num?)?.toDouble() ?? 0,
      examMaxMark: json['examMaxMark'] as int? ?? 0,
      totalMark: totalMark,
      totalMaxMark: totalMaxMark,
      isMonthlyOnly: json['isMonthlyOnly'] as bool? ?? false,
      isMonthlyAbsent: json['isMonthlyAbsent'] as bool? ?? false,
      isFirstTermAbsent: json['isFirstTermAbsent'] as bool? ?? false,
      percentage: (json['percentage'] as num?)?.toDouble() ?? percentage,
      gradeText: json['gradeText'] as String? ?? '',
      color: json['color'] as String? ?? '',
    );
  }
}

class StudentResultsResponse {
  final bool resultsBlocked;
  final List<StudentResult> results;

  const StudentResultsResponse({
    required this.resultsBlocked,
    required this.results,
  });

  factory StudentResultsResponse.fromJson(Map<String, dynamic> json) {
    final list = json['results'] as List<dynamic>? ?? [];
    return StudentResultsResponse(
      resultsBlocked: json['resultsBlocked'] as bool? ?? false,
      results: list
          .map((e) => StudentResult.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class PaymentAccount {
  final String bankName;
  final String accountNumber;
  final String? mobileNumber;

  const PaymentAccount({
    required this.bankName,
    required this.accountNumber,
    this.mobileNumber,
  });

  factory PaymentAccount.fromJson(Map<String, dynamic> json) {
    return PaymentAccount(
      bankName: json['bankName'] as String? ?? '',
      accountNumber: json['accountNumber'] as String? ?? '',
      mobileNumber: json['mobileNumber'] as String?,
    );
  }
}

class FeeReceipt {
  final int id;
  final String category;
  final double amount;
  final String originalFileName;
  final String? notes;
  final DateTime uploadedAt;
  final String status;

  const FeeReceipt({
    required this.id,
    required this.category,
    required this.amount,
    required this.originalFileName,
    this.notes,
    required this.uploadedAt,
    required this.status,
  });

  factory FeeReceipt.fromJson(Map<String, dynamic> json) {
    return FeeReceipt(
      id: json['id'] as int,
      category: json['category'] as String? ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      originalFileName: json['originalFileName'] as String? ?? '',
      notes: json['notes'] as String?,
      uploadedAt: DateTime.parse(json['uploadedAt'] as String),
      status: json['status'] as String? ?? '',
    );
  }
}

class FeeExcelPayment {
  final int id;
  final double paidAmount;
  final String paymentType;
  final String paymentMethod;
  final DateTime importedAt;

  const FeeExcelPayment({
    required this.id,
    required this.paidAmount,
    required this.paymentType,
    required this.paymentMethod,
    required this.importedAt,
  });

  factory FeeExcelPayment.fromJson(Map<String, dynamic> json) {
    return FeeExcelPayment(
      id: json['id'] as int? ?? 0,
      paidAmount: (json['paidAmount'] as num?)?.toDouble() ?? 0,
      paymentType: json['paymentType'] as String? ?? '',
      paymentMethod: json['paymentMethod'] as String? ?? '',
      importedAt: DateTime.parse(json['importedAt'] as String),
    );
  }
}

class StudentFeesResponse {
  final String? academicYearName;
  final double installment1Amount;
  final double installment2ExpectedAmount;
  final double booksFee;
  final double tuitionAndBooksTotal;
  final double otherFeesAmount;
  final bool otherFeesAvailable;
  final bool otherFeesOptedIn;
  final String transferNotice;
  final String? message;
  final List<PaymentAccount> paymentAccounts;
  final List<FeeReceipt> receipts;
  final List<FeeExcelPayment> excelPayments;
  final double excelPaymentsTotal;

  // بيانات المزامنة المالية (من ملف Excel)
  final double tuitionRequired;
  final double tuitionPaid;
  final double tuitionDiscount;
  final double tuitionRemaining;
  final double booksRequired;
  final double booksPaid;
  final double booksDiscount;
  final double booksRemaining;
  final double uniformRequired;
  final double uniformPaid;
  final double uniformDiscount;
  final double uniformRemaining;
  final double busRequired;
  final double busPaid;
  final double busDiscount;
  final double busRemaining;
  final double totalRemaining;
  final double currentArrears;
  final DateTime? lastSyncedAt;

  const StudentFeesResponse({
    this.academicYearName,
    required this.installment1Amount,
    required this.installment2ExpectedAmount,
    required this.booksFee,
    required this.tuitionAndBooksTotal,
    required this.otherFeesAmount,
    required this.otherFeesAvailable,
    required this.otherFeesOptedIn,
    required this.transferNotice,
    this.message,
    required this.paymentAccounts,
    required this.receipts,
    this.excelPayments = const [],
    this.excelPaymentsTotal = 0,
    this.tuitionRequired = 0,
    this.tuitionPaid = 0,
    this.tuitionDiscount = 0,
    this.tuitionRemaining = 0,
    this.booksRequired = 0,
    this.booksPaid = 0,
    this.booksDiscount = 0,
    this.booksRemaining = 0,
    this.uniformRequired = 0,
    this.uniformPaid = 0,
    this.uniformDiscount = 0,
    this.uniformRemaining = 0,
    this.busRequired = 0,
    this.busPaid = 0,
    this.busDiscount = 0,
    this.busRemaining = 0,
    this.totalRemaining = 0,
    this.currentArrears = 0,
    this.lastSyncedAt,
  });

  factory StudentFeesResponse.fromJson(Map<String, dynamic> json) {
    final accounts = json['paymentAccounts'] as List<dynamic>? ?? [];
    final receipts = json['receipts'] as List<dynamic>? ?? [];
    final excelPayments = json['excelPayments'] as List<dynamic>? ?? [];

    return StudentFeesResponse(
      academicYearName: json['academicYearName'] as String?,
      installment1Amount: (json['installment1Amount'] as num?)?.toDouble() ?? 0,
      installment2ExpectedAmount:
          (json['installment2ExpectedAmount'] as num?)?.toDouble() ?? 0,
      booksFee: (json['booksFee'] as num?)?.toDouble() ?? 0,
      tuitionAndBooksTotal:
          (json['tuitionAndBooksTotal'] as num?)?.toDouble() ?? 0,
      otherFeesAmount: (json['otherFeesAmount'] as num?)?.toDouble() ?? 0,
      otherFeesAvailable: json['otherFeesAvailable'] as bool? ?? false,
      otherFeesOptedIn: json['otherFeesOptedIn'] as bool? ?? false,
      transferNotice: json['transferNotice'] as String? ?? '',
      message: json['message'] as String?,
      paymentAccounts: accounts
          .map((e) => PaymentAccount.fromJson(e as Map<String, dynamic>))
          .toList(),
      receipts: receipts
          .map((e) => FeeReceipt.fromJson(e as Map<String, dynamic>))
          .toList(),
      excelPayments: excelPayments
          .map((e) => FeeExcelPayment.fromJson(e as Map<String, dynamic>))
          .toList(),
      excelPaymentsTotal: (json['excelPaymentsTotal'] as num?)?.toDouble() ?? 0,
      tuitionRequired: (json['tuitionRequired'] as num?)?.toDouble() ?? 0,
      tuitionPaid: (json['tuitionPaid'] as num?)?.toDouble() ?? 0,
      tuitionDiscount: (json['tuitionDiscount'] as num?)?.toDouble() ?? 0,
      tuitionRemaining: (json['tuitionRemaining'] as num?)?.toDouble() ?? 0,
      booksRequired: (json['booksRequired'] as num?)?.toDouble() ?? 0,
      booksPaid: (json['booksPaid'] as num?)?.toDouble() ?? 0,
      booksDiscount: (json['booksDiscount'] as num?)?.toDouble() ?? 0,
      booksRemaining: (json['booksRemaining'] as num?)?.toDouble() ?? 0,
      uniformRequired: (json['uniformRequired'] as num?)?.toDouble() ?? 0,
      uniformPaid: (json['uniformPaid'] as num?)?.toDouble() ?? 0,
      uniformDiscount: (json['uniformDiscount'] as num?)?.toDouble() ?? 0,
      uniformRemaining: (json['uniformRemaining'] as num?)?.toDouble() ?? 0,
      busRequired: (json['busRequired'] as num?)?.toDouble() ?? 0,
      busPaid: (json['busPaid'] as num?)?.toDouble() ?? 0,
      busDiscount: (json['busDiscount'] as num?)?.toDouble() ?? 0,
      busRemaining: (json['busRemaining'] as num?)?.toDouble() ?? 0,
      totalRemaining: (json['totalRemaining'] as num?)?.toDouble() ?? 0,
      currentArrears: (json['currentArrears'] as num?)?.toDouble() ?? 0,
      lastSyncedAt: json['lastSyncedAt'] != null
          ? DateTime.tryParse(json['lastSyncedAt'] as String)
          : null,
    );
  }
}

class StudentVideo {
  final int id;
  final String title;
  final String description;
  final String videoUrl;
  final bool isReel;
  final DateTime uploadedAt;

  const StudentVideo({
    required this.id,
    required this.title,
    required this.description,
    required this.videoUrl,
    required this.isReel,
    required this.uploadedAt,
  });

  factory StudentVideo.fromJson(Map<String, dynamic> json) {
    return StudentVideo(
      id: json['id'] as int,
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      videoUrl: json['videoUrl'] as String? ?? '',
      isReel: json['isReel'] as bool? ?? false,
      uploadedAt: DateTime.parse(json['uploadedAt'] as String),
    );
  }
}
