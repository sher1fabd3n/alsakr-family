import '../../../services/api_client.dart';
import '../../transportation/models/transportation_models.dart';
import '../models/driver_models.dart';

class DriverService {
  DriverService(this._apiClient);

  final ApiClient _apiClient;

  Future<DriverLoginResult> login(String phone, String password) async {
    final response = await _apiClient.dio.post(
      '/api/transportation/driver/login',
      data: {'phone': phone, 'password': password},
    );
    final data = response.data as Map<String, dynamic>;
    await _apiClient.saveToken(data['token'] as String);
    await _apiClient.writeSecure('mobile_auth_role', 'Driver');
    return DriverLoginResult(
      token: data['token'] as String,
      profile: DriverProfile.fromJson(data['profile'] as Map<String, dynamic>),
    );
  }

  Future<DriverDashboard> getDashboard() async {
    final response = await _apiClient.dio.get('/api/transportation/driver/dashboard');
    return DriverDashboard.fromJson(response.data as Map<String, dynamic>);
  }

  Future<int> startTrip({required String tripType, List<int>? studentIds}) async {
    final response = await _apiClient.dio.post(
      '/api/transportation/driver/trips/start',
      data: {
        'tripType': _tripTypeValue(tripType),
        if (studentIds != null) 'studentIds': studentIds,
      },
    );
    return (response.data as Map<String, dynamic>)['tripId'] as int;
  }

  Future<void> pauseTrip(int tripId) async {
    await _apiClient.dio.post('/api/transportation/driver/trips/$tripId/pause');
  }

  Future<void> resumeTrip(int tripId) async {
    await _apiClient.dio.post('/api/transportation/driver/trips/$tripId/resume');
  }

  Future<void> completeTrip(int tripId) async {
    await _apiClient.dio.post('/api/transportation/driver/trips/$tripId/complete');
  }

  Future<void> updateLocation(
    int tripId, {
    required double latitude,
    required double longitude,
    double? speedKmh,
    double? heading,
    double? accuracyMeters,
  }) async {
    await _apiClient.dio.post(
      '/api/transportation/driver/trips/$tripId/location',
      data: {
        'latitude': latitude,
        'longitude': longitude,
        'speedKmh': speedKmh,
        'heading': heading,
        'accuracyMeters': accuracyMeters,
      },
    );
  }

  Future<void> updateStudentStatus(
    int tripId,
    int studentId,
    String status, {
    double? latitude,
    double? longitude,
  }) async {
    await _apiClient.dio.post(
      '/api/transportation/driver/trips/$tripId/students/status',
      data: {
        'studentId': studentId,
        'status': _studentStatusValue(status),
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
      },
    );
  }

  Future<void> triggerEmergency({
    int? tripId,
    double? latitude,
    double? longitude,
    String? message,
  }) async {
    await _apiClient.dio.post(
      '/api/transportation/driver/emergency',
      data: {
        if (tripId != null) 'tripId': tripId,
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
        if (message != null) 'message': message,
      },
    );
  }

  Future<List<DriverAttendanceStudent>> getTripAttendance(int tripId) async {
    final response = await _apiClient.dio.get('/api/transportation/driver/trips/$tripId/attendance');
    final list = response.data as List<dynamic>;
    return list.map((e) => DriverAttendanceStudent.fromJson(e as Map<String, dynamic>)).toList();
  }

  int _tripTypeValue(String type) {
    switch (type) {
      case 'Afternoon':
        return 2;
      case 'Custom':
        return 3;
      case 'Individual':
        return 4;
      default:
        return 1;
    }
  }

  int _studentStatusValue(String status) {
    switch (status) {
      case 'Approaching':
        return 1;
      case 'Arrived':
        return 2;
      case 'Boarded':
        return 3;
      case 'DroppedAtSchool':
        return 4;
      case 'OnWayHome':
        return 5;
      case 'ArrivedHome':
        return 6;
      case 'Absent':
        return 7;
      case 'Skipped':
        return 8;
      default:
        return 0;
    }
  }
}

class DriverLoginResult {
  final String token;
  final DriverProfile profile;

  DriverLoginResult({required this.token, required this.profile});
}
