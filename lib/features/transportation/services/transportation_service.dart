import 'package:dio/dio.dart';

import '../../../config/api_config.dart';
import '../../../services/api_client.dart';
import '../models/transportation_models.dart';

class NoActiveTripException implements Exception {
  const NoActiveTripException();

  @override
  String toString() => 'لا توجد رحلة نشطة حالياً لهذا الطالب.';
}

class TransportationService {
  TransportationService(this._apiClient);

  final ApiClient _apiClient;

  String trackingHubUrl(String token) =>
      '${ApiConfig.baseUrl}/hubs/bus-tracking?access_token=$token';

  Future<TransportDashboard> getDashboard({int? studentId}) async {
    final response = await _apiClient.dio.get(
      '/api/transportation/dashboard',
      queryParameters: {if (studentId != null) 'studentId': studentId},
    );
    return TransportDashboard.fromJson(response.data as Map<String, dynamic>);
  }

  Future<TransportationCardData> getCard({int? studentId}) async {
    final response = await _apiClient.dio.get(
      '/api/transportation/card',
      queryParameters: {if (studentId != null) 'studentId': studentId},
    );
    return TransportationCardData.fromJson(response.data as Map<String, dynamic>);
  }

  Future<LiveTrackingData> getLiveTracking({int? studentId}) async {
    try {
      final response = await _apiClient.dio.get(
        '/api/transportation/tracking/live',
        queryParameters: {if (studentId != null) 'studentId': studentId},
      );
      return LiveTrackingData.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        throw const NoActiveTripException();
      }
      throw Exception(_apiClient.extractErrorMessage(e));
    }
  }

  Future<List<TransportNotificationItem>> getNotifications({int? studentId}) async {
    final response = await _apiClient.dio.get(
      '/api/transportation/notifications',
      queryParameters: {if (studentId != null) 'studentId': studentId},
    );
    final list = response.data as List<dynamic>;
    return list
        .map((e) => TransportNotificationItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> markNotificationRead(int id) async {
    await _apiClient.dio.post('/api/transportation/notifications/$id/read');
  }

  Future<void> savePrivateDriver({
    required int studentId,
    required String driverFullName,
    required String driverPhone,
    required String nationalIdNumber,
    required String vehicleType,
    String? vehicleModel,
    String? vehicleColor,
    required String vehiclePlateNumber,
    required String relationshipToStudent,
    String? notes,
  }) async {
    try {
      await _apiClient.dio.post(
        '/api/transportation/private-driver',
        data: {
          'studentId': studentId,
          'driverFullName': driverFullName,
          'driverPhone': driverPhone,
          'nationalIdNumber': nationalIdNumber,
          'vehicleType': vehicleType,
          'vehicleModel': vehicleModel,
          'vehicleColor': vehicleColor,
          'vehiclePlateNumber': vehiclePlateNumber,
          'relationshipToStudent': relationshipToStudent,
          'notes': notes,
        },
      );
    } on DioException catch (e) {
      throw Exception(_apiClient.extractErrorMessage(e));
    }
  }

  Future<List<ParentChildTransport>> getParentChildren() async {
    final response = await _apiClient.dio.get('/api/transportation/parent/children');
    final list = response.data as List<dynamic>;
    return list
        .map((e) => ParentChildTransport.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> registerPushToken(String token, {String platform = 'android'}) async {
    await _apiClient.dio.post(
      '/api/transportation/push-token',
      data: {'token': token, 'platform': platform},
    );
  }

  Future<void> uploadPrivateDriverImages({
    required int studentId,
    String? frontPath,
    String? backPath,
  }) async {
    final formData = FormData.fromMap({
      'studentId': studentId,
      if (frontPath != null)
        'frontImage': await MultipartFile.fromFile(frontPath, filename: 'front.jpg'),
      if (backPath != null)
        'backImage': await MultipartFile.fromFile(backPath, filename: 'back.jpg'),
    });
    await _apiClient.dio.post(
      '/api/transportation/private-driver/upload',
      data: formData,
    );
  }

  Future<List<ParentTripHistoryItem>> getParentTripHistory({int? studentId, int take = 50}) async {
    final response = await _apiClient.dio.get(
      '/api/transportation/parent/history',
      queryParameters: {
        if (studentId != null) 'studentId': studentId,
        'take': take,
      },
    );
    final list = response.data as List<dynamic>;
    return list.map((e) => ParentTripHistoryItem.fromJson(e as Map<String, dynamic>)).toList();
  }
}
