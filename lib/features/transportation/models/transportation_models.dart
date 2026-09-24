class TransportDashboard {
  final String transportationType;
  final bool hasActiveTrip;
  final int? activeTripId;
  final bool hasCard;
  final int unreadNotifications;
  final String? routeName;
  final String? busNumber;

  const TransportDashboard({
    required this.transportationType,
    required this.hasActiveTrip,
    this.activeTripId,
    required this.hasCard,
    required this.unreadNotifications,
    this.routeName,
    this.busNumber,
  });

  factory TransportDashboard.fromJson(Map<String, dynamic> json) => TransportDashboard(
        transportationType: json['transportationType'] as String? ?? 'None',
        hasActiveTrip: json['hasActiveTrip'] as bool? ?? false,
        activeTripId: json['activeTripId'] as int?,
        hasCard: json['hasCard'] as bool? ?? false,
        unreadNotifications: json['unreadNotifications'] as int? ?? 0,
        routeName: json['routeName'] as String?,
        busNumber: json['busNumber'] as String?,
      );

  bool get isSchoolBus => transportationType == 'SchoolBus';
  bool get isPrivate => transportationType == 'Private';
}

class TransportationCardData {
  final String transportationType;
  final String transportationTypeAr;
  final String schoolName;
  final String? schoolLogoUrl;
  final String studentName;
  final int studentCode;
  final String grade;
  final String stageDisplayAr;
  final String? address;
  final String? fatherPhone;
  final String? motherPhone;
  final String transportLine;
  final String? studentPhotoUrl;
  final String status;
  final String? cardNumber;
  final DateTime? issuedAt;
  final DateTime? expiresAt;
  final String? emergencyContact;
  final SchoolBusCardDetails? schoolBus;
  final PrivateCardDetails? private;

  const TransportationCardData({
    required this.transportationType,
    required this.transportationTypeAr,
    required this.schoolName,
    this.schoolLogoUrl,
    required this.studentName,
    required this.studentCode,
    required this.grade,
    this.stageDisplayAr = '',
    this.address,
    this.fatherPhone,
    this.motherPhone,
    this.transportLine = '',
    this.studentPhotoUrl,
    required this.status,
    this.cardNumber,
    this.issuedAt,
    this.expiresAt,
    this.emergencyContact,
    this.schoolBus,
    this.private,
  });

  factory TransportationCardData.fromJson(Map<String, dynamic> json) => TransportationCardData(
        transportationType: json['transportationType'] as String? ?? '',
        transportationTypeAr: json['transportationTypeAr'] as String? ?? '',
        schoolName: json['schoolName'] as String? ?? '',
        schoolLogoUrl: json['schoolLogoUrl'] as String?,
        studentName: json['studentName'] as String? ?? '',
        studentCode: json['studentCode'] as int? ?? 0,
        grade: json['grade'] as String? ?? '',
        stageDisplayAr: json['stageDisplayAr'] as String? ?? '',
        address: json['address'] as String?,
        fatherPhone: json['fatherPhone'] as String?,
        motherPhone: json['motherPhone'] as String?,
        transportLine: json['transportLine'] as String? ?? '',
        studentPhotoUrl: json['studentPhotoUrl'] as String?,
        status: json['status'] as String? ?? '',
        cardNumber: json['cardNumber'] as String?,
        issuedAt: json['issuedAt'] != null ? DateTime.parse(json['issuedAt'] as String) : null,
        expiresAt: json['expiresAt'] != null ? DateTime.parse(json['expiresAt'] as String) : null,
        emergencyContact: json['emergencyContact'] as String?,
        schoolBus: json['schoolBus'] != null
            ? SchoolBusCardDetails.fromJson(json['schoolBus'] as Map<String, dynamic>)
            : null,
        private: json['private'] != null
            ? PrivateCardDetails.fromJson(json['private'] as Map<String, dynamic>)
            : null,
      );

  bool get isSchoolBus => transportationType == 'SchoolBus';
}

class SchoolBusCardDetails {
  final String routeName;
  final String busNumber;
  final String driverName;
  final String driverPhone;
  final String supervisorName;
  final String supervisorPhone;

  const SchoolBusCardDetails({
    required this.routeName,
    required this.busNumber,
    required this.driverName,
    required this.driverPhone,
    required this.supervisorName,
    required this.supervisorPhone,
  });

  factory SchoolBusCardDetails.fromJson(Map<String, dynamic> json) => SchoolBusCardDetails(
        routeName: json['routeName'] as String? ?? '',
        busNumber: json['busNumber'] as String? ?? '',
        driverName: json['driverName'] as String? ?? '',
        driverPhone: json['driverPhone'] as String? ?? '',
        supervisorName: json['supervisorName'] as String? ?? '',
        supervisorPhone: json['supervisorPhone'] as String? ?? '',
      );
}

class PrivateCardDetails {
  final String driverFullName;
  final String driverPhone;
  final String nationalIdNumber;
  final String? nationalIdFrontUrl;
  final String? nationalIdBackUrl;
  final String? driverPhotoUrl;
  final String vehicleType;
  final String? vehicleModel;
  final String? vehicleColor;
  final String vehiclePlateNumber;
  final String relationshipToStudent;
  final String? notes;

  const PrivateCardDetails({
    required this.driverFullName,
    required this.driverPhone,
    required this.nationalIdNumber,
    this.nationalIdFrontUrl,
    this.nationalIdBackUrl,
    this.driverPhotoUrl,
    required this.vehicleType,
    this.vehicleModel,
    this.vehicleColor,
    required this.vehiclePlateNumber,
    required this.relationshipToStudent,
    this.notes,
  });

  factory PrivateCardDetails.fromJson(Map<String, dynamic> json) => PrivateCardDetails(
        driverFullName: json['driverFullName'] as String? ?? '',
        driverPhone: json['driverPhone'] as String? ?? '',
        nationalIdNumber: json['nationalIdNumber'] as String? ?? '',
        nationalIdFrontUrl: json['nationalIdFrontUrl'] as String?,
        nationalIdBackUrl: json['nationalIdBackUrl'] as String?,
        driverPhotoUrl: json['driverPhotoUrl'] as String?,
        vehicleType: json['vehicleType'] as String? ?? '',
        vehicleModel: json['vehicleModel'] as String?,
        vehicleColor: json['vehicleColor'] as String?,
        vehiclePlateNumber: json['vehiclePlateNumber'] as String? ?? '',
        relationshipToStudent: json['relationshipToStudent'] as String? ?? '',
        notes: json['notes'] as String?,
      );
}

class LiveTrackingData {
  final int tripId;
  final String tripStatus;
  final String tripType;
  final double? busLatitude;
  final double? busLongitude;
  final double? busSpeedKmh;
  final double? busHeading;
  final DateTime? lastLocationAt;
  final String routeName;
  final String busNumber;
  final String driverName;
  final String driverPhone;
  final String? supervisorName;
  final String? supervisorPhone;
  final double? studentPickupLatitude;
  final double? studentPickupLongitude;
  final double? distanceRemainingKm;
  final int? etaMinutes;
  final String studentTripStatus;
  final List<RouteStopData> stops;

  const LiveTrackingData({
    required this.tripId,
    required this.tripStatus,
    required this.tripType,
    this.busLatitude,
    this.busLongitude,
    this.busSpeedKmh,
    this.busHeading,
    this.lastLocationAt,
    required this.routeName,
    required this.busNumber,
    required this.driverName,
    required this.driverPhone,
    this.supervisorName,
    this.supervisorPhone,
    this.studentPickupLatitude,
    this.studentPickupLongitude,
    this.distanceRemainingKm,
    this.etaMinutes,
    required this.studentTripStatus,
    this.stops = const [],
  });

  factory LiveTrackingData.fromJson(Map<String, dynamic> json) => LiveTrackingData(
        tripId: json['tripId'] as int,
        tripStatus: json['tripStatus'] as String? ?? '',
        tripType: json['tripType'] as String? ?? '',
        busLatitude: (json['busLatitude'] as num?)?.toDouble(),
        busLongitude: (json['busLongitude'] as num?)?.toDouble(),
        busSpeedKmh: (json['busSpeedKmh'] as num?)?.toDouble(),
        busHeading: (json['busHeading'] as num?)?.toDouble(),
        lastLocationAt: json['lastLocationAt'] != null
            ? DateTime.parse(json['lastLocationAt'] as String)
            : null,
        routeName: json['routeName'] as String? ?? '',
        busNumber: json['busNumber'] as String? ?? '',
        driverName: json['driverName'] as String? ?? '',
        driverPhone: json['driverPhone'] as String? ?? '',
        supervisorName: json['supervisorName'] as String?,
        supervisorPhone: json['supervisorPhone'] as String?,
        studentPickupLatitude: (json['studentPickupLatitude'] as num?)?.toDouble(),
        studentPickupLongitude: (json['studentPickupLongitude'] as num?)?.toDouble(),
        distanceRemainingKm: (json['distanceRemainingKm'] as num?)?.toDouble(),
        etaMinutes: json['etaMinutes'] as int?,
        studentTripStatus: json['studentTripStatus'] as String? ?? '',
        stops: (json['stops'] as List<dynamic>?)
                ?.map((e) => RouteStopData.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
      );
}

class RouteStopData {
  final int id;
  final String name;
  final double latitude;
  final double longitude;
  final int stopOrder;

  const RouteStopData({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.stopOrder,
  });

  factory RouteStopData.fromJson(Map<String, dynamic> json) => RouteStopData(
        id: json['id'] as int,
        name: json['name'] as String? ?? '',
        latitude: (json['latitude'] as num).toDouble(),
        longitude: (json['longitude'] as num).toDouble(),
        stopOrder: json['stopOrder'] as int? ?? 0,
      );
}

class TransportNotificationItem {
  final int id;
  final String title;
  final String body;
  final String notificationType;
  final bool isRead;
  final DateTime createdAt;

  const TransportNotificationItem({
    required this.id,
    required this.title,
    required this.body,
    required this.notificationType,
    required this.isRead,
    required this.createdAt,
  });

  factory TransportNotificationItem.fromJson(Map<String, dynamic> json) => TransportNotificationItem(
        id: (json['id'] as num).toInt(),
        title: json['title'] as String? ?? '',
        body: json['body'] as String? ?? '',
        notificationType: json['notificationType'] as String? ?? '',
        isRead: json['isRead'] as bool? ?? false,
        createdAt: _parseDateTime(json['createdAt']) ?? DateTime.now(),
      );
}

DateTime? _parseDateTime(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  if (value is int) {
    // Support seconds or milliseconds since epoch.
    final ms = value < 100000000000 ? value * 1000 : value;
    final dt = DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true);
    return dt.year >= 2000 ? dt : null;
  }
  if (value is String && value.isNotEmpty) {
    final dt = DateTime.tryParse(value);
    if (dt == null || dt.year < 2000) return null;
    return dt;
  }
  return null;
}

class ParentChildTransport {
  final int studentId;
  final String name;
  final String grade;
  final int rollNo;
  final String transportationType;
  final String transportationTypeAr;
  final bool isSchoolBus;
  final bool isPrivate;

  const ParentChildTransport({
    required this.studentId,
    required this.name,
    required this.grade,
    required this.rollNo,
    required this.transportationType,
    required this.transportationTypeAr,
    required this.isSchoolBus,
    required this.isPrivate,
  });

  factory ParentChildTransport.fromJson(Map<String, dynamic> json) => ParentChildTransport(
        studentId: json['studentId'] as int,
        name: json['name'] as String? ?? '',
        grade: json['grade'] as String? ?? '',
        rollNo: json['rollNo'] as int? ?? 0,
        transportationType: json['transportationType'] as String? ?? 'None',
        transportationTypeAr: json['transportationTypeAr'] as String? ?? 'غير محدد',
        isSchoolBus: json['isSchoolBus'] as bool? ?? false,
        isPrivate: json['isPrivate'] as bool? ?? false,
      );
}

class BusOccupancy {
  final int totalAssigned;
  final int onBus;
  final int notYetPickedUp;
  final int delivered;
  final int missing;
  final int busCapacity;

  const BusOccupancy({
    required this.totalAssigned,
    required this.onBus,
    required this.notYetPickedUp,
    required this.delivered,
    required this.missing,
    required this.busCapacity,
  });

  factory BusOccupancy.fromJson(Map<String, dynamic> json) => BusOccupancy(
        totalAssigned: (json['totalAssigned'] as num?)?.toInt() ?? 0,
        onBus: (json['onBus'] as num?)?.toInt() ?? 0,
        notYetPickedUp: (json['notYetPickedUp'] as num?)?.toInt() ?? 0,
        delivered: (json['delivered'] as num?)?.toInt() ?? 0,
        missing: (json['missing'] as num?)?.toInt() ?? 0,
        busCapacity: (json['busCapacity'] as num?)?.toInt() ?? 0,
      );
}

class DriverAttendanceStudent {
  final int studentId;
  final String name;
  final String grade;
  final String? stopName;
  final String tripStatus;
  final DateTime? boardedAt;
  final DateTime? droppedAt;

  const DriverAttendanceStudent({
    required this.studentId,
    required this.name,
    required this.grade,
    this.stopName,
    required this.tripStatus,
    this.boardedAt,
    this.droppedAt,
  });

  factory DriverAttendanceStudent.fromJson(Map<String, dynamic> json) => DriverAttendanceStudent(
        studentId: json['studentId'] as int,
        name: json['name'] as String? ?? '',
        grade: json['grade'] as String? ?? '',
        stopName: json['stopName'] as String?,
        tripStatus: json['tripStatus'] as String? ?? 'Pending',
        boardedAt: json['boardedAt'] != null ? DateTime.parse(json['boardedAt'] as String) : null,
        droppedAt: json['droppedAt'] != null ? DateTime.parse(json['droppedAt'] as String) : null,
      );

  bool get isBoarded => tripStatus == 'Boarded' || tripStatus == 'OnWayHome';
  bool get isDelivered => tripStatus == 'DroppedAtSchool' || tripStatus == 'ArrivedHome';
  bool get isMissing => tripStatus == 'Absent' || tripStatus == 'Skipped';
}

class ParentTripHistoryItem {
  final int tripId;
  final String tripType;
  final String routeName;
  final String busNumber;
  final String driverName;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final String studentStatus;
  final DateTime? boardedAt;
  final DateTime? droppedAtSchoolAt;
  final DateTime? arrivedHomeAt;

  const ParentTripHistoryItem({
    required this.tripId,
    required this.tripType,
    required this.routeName,
    required this.busNumber,
    required this.driverName,
    this.startedAt,
    this.completedAt,
    required this.studentStatus,
    this.boardedAt,
    this.droppedAtSchoolAt,
    this.arrivedHomeAt,
  });

  factory ParentTripHistoryItem.fromJson(Map<String, dynamic> json) => ParentTripHistoryItem(
        tripId: json['tripId'] as int,
        tripType: json['tripType'] as String? ?? '',
        routeName: json['routeName'] as String? ?? '',
        busNumber: json['busNumber'] as String? ?? '',
        driverName: json['driverName'] as String? ?? '',
        startedAt: json['startedAt'] != null ? DateTime.parse(json['startedAt'] as String) : null,
        completedAt: json['completedAt'] != null ? DateTime.parse(json['completedAt'] as String) : null,
        studentStatus: json['studentStatus'] as String? ?? '',
        boardedAt: json['boardedAt'] != null ? DateTime.parse(json['boardedAt'] as String) : null,
        droppedAtSchoolAt: json['droppedAtSchoolAt'] != null ? DateTime.parse(json['droppedAtSchoolAt'] as String) : null,
        arrivedHomeAt: json['arrivedHomeAt'] != null ? DateTime.parse(json['arrivedHomeAt'] as String) : null,
      );
}
