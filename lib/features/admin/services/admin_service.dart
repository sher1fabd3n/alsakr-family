import 'package:dio/dio.dart';

import '../../../services/api_client.dart';
import '../../communication/models/communication_models.dart';
import '../models/admin_models.dart';

class AdminService {
  AdminService(this._apiClient);

  final ApiClient _apiClient;

  Future<AdminStats> getStats() async {
    final response = await _apiClient.dio.get('/api/communication/admin/stats');
    return AdminStats.fromJson(response.data as Map<String, dynamic>);
  }

  Future<List<AdminConversationSummary>> searchConversations({
    String? search,
    String? grade,
    int? teacherId,
    int? parentId,
    int? studentId,
  }) async {
    final response = await _apiClient.dio.get(
      '/api/communication/admin/conversations',
      queryParameters: {
        if (search != null && search.isNotEmpty) 'search': search,
        if (grade != null && grade.isNotEmpty) 'grade': grade,
        if (teacherId != null) 'teacherId': teacherId,
        if (parentId != null) 'parentId': parentId,
        if (studentId != null) 'studentId': studentId,
      },
    );
    final list = response.data as List<dynamic>;
    return list
        .map((e) => AdminConversationSummary.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<ChatMessageItem>> getConversationMessages(int conversationId) async {
    final response = await _apiClient.dio.get(
      '/api/communication/admin/conversations/$conversationId/messages',
    );
    final list = response.data as List<dynamic>;
    return list
        .map((e) => ChatMessageItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<AnnouncementItem>> getAnnouncements({String? search}) async {
    final response = await _apiClient.dio.get(
      '/api/communication/admin/announcements',
      queryParameters: {if (search != null && search.isNotEmpty) 'search': search},
    );
    final list = response.data as List<dynamic>;
    return list
        .map((e) => AnnouncementItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<AdminProfile> login(String username, String password) async {
    try {
      final response = await _apiClient.dio.post(
        '/api/communication/auth/admin/login',
        data: {'username': username, 'password': password},
      );
      final data = response.data as Map<String, dynamic>;
      await _apiClient.saveToken(data['token'] as String);
      await _apiClient.writeSecure('mobile_auth_role', 'Admin');
      final profile = data['profile'] as Map<String, dynamic>;
      return AdminProfile.fromJson(profile);
    } on DioException catch (e) {
      final msg = _apiClient.extractErrorMessage(e);
      throw Exception(msg);
    }
  }
}
