import '../../transportation/models/transportation_models.dart';

class DriverProfile {
  final int id;
  final String fullName;
  final String phone;
  final int? busId;
  final String? busNumber;

  const DriverProfile({
    required this.id,
    required this.fullName,
    required this.phone,
    this.busId,
    this.busNumber,
  });

  factory DriverProfile.fromJson(Map<String, dynamic> json) => DriverProfile(
        id: json['id'] as int,
        fullName: json['fullName'] as String? ?? '',
        phone: json['phone'] as String? ?? '',
        busId: json['busId'] as int?,
        busNumber: json['busNumber'] as String?,
      );
}

class DriverDashboard {
  final bool hasBus;
  final int? busId;
  final String? busNumber;
  final String? routeName;
  final int? routeId;
  final String? supervisorName;
  final String? supervisorPhone;
  final List<DriverStudent> students;
  final DriverActiveTrip? activeTrip;
  final BusOccupancy? occupancy;
  final List<DriverAttendanceStudent> attendance;

  const DriverDashboard({
    required this.hasBus,
    this.busId,
    this.busNumber,
    this.routeName,
    this.routeId,
    this.supervisorName,
    this.supervisorPhone,
    this.students = const [],
    this.activeTrip,
    this.occupancy,
    this.attendance = const [],
  });

  factory DriverDashboard.fromJson(Map<String, dynamic> json) => DriverDashboard(
        hasBus: json['hasBus'] as bool? ?? false,
        busId: json['id'] as int?,
        busNumber: json['busNumber'] as String?,
        routeName: json['routeName'] as String?,
        routeId: json['routeId'] as int?,
        supervisorName: json['supervisorName'] as String?,
        supervisorPhone: json['supervisorPhone'] as String?,
        students: (json['students'] as List<dynamic>?)
                ?.map((e) => DriverStudent.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
        activeTrip: json['activeTrip'] != null
            ? DriverActiveTrip.fromJson(json['activeTrip'] as Map<String, dynamic>)
            : null,
        occupancy: json['occupancy'] != null
            ? BusOccupancy.fromJson(json['occupancy'] as Map<String, dynamic>)
            : null,
        attendance: (json['attendance'] as List<dynamic>?)
                ?.map((e) => DriverAttendanceStudent.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
      );
}

class DriverStudent {
  final int studentId;
  final String name;
  final String grade;
  final int rollNo;
  final String? stopName;

  const DriverStudent({
    required this.studentId,
    required this.name,
    required this.grade,
    required this.rollNo,
    this.stopName,
  });

  factory DriverStudent.fromJson(Map<String, dynamic> json) => DriverStudent(
        studentId: json['studentId'] as int,
        name: json['name'] as String? ?? '',
        grade: json['grade'] as String? ?? '',
        rollNo: json['rollNo'] as int? ?? 0,
        stopName: json['stopName'] as String?,
      );
}

class DriverActiveTrip {
  final int id;
  final String status;
  final String tripType;

  const DriverActiveTrip({
    required this.id,
    required this.status,
    required this.tripType,
  });

  factory DriverActiveTrip.fromJson(Map<String, dynamic> json) => DriverActiveTrip(
        id: json['id'] as int,
        status: json['status'] as String? ?? '',
        tripType: json['tripType'] as String? ?? '',
      );
}
