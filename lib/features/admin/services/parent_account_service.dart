import 'package:dio/dio.dart';

import '../../../services/api_client.dart';
import '../models/parent_account_models.dart';

class ParentAccountService {
  ParentAccountService(this._apiClient);

  final ApiClient _apiClient;

  // ── Parent profile (logged-in parent) ─────────────────────────────────────

  Future<ParentProfile> getProfile() async {
    final response = await _apiClient.dio.get('/api/parent/profile');
    return ParentProfile.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> completeFirstLogin({
    String? newPassword,
    required String phone,
    String? email,
  }) async {
    try {
      await _apiClient.dio.post(
        '/api/parent/first-login/complete',
        data: {
          if (newPassword != null && newPassword.isNotEmpty) 'newPassword': newPassword,
          'phone': phone,
          if (email != null && email.isNotEmpty) 'email': email,
        },
      );
    } on DioException catch (e) {
      throw Exception(_apiClient.extractErrorMessage(e));
    }
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      await _apiClient.dio.post(
        '/api/parent/change-password',
        data: {
          'currentPassword': currentPassword,
          'newPassword': newPassword,
        },
      );
    } on DioException catch (e) {
      throw Exception(_apiClient.extractErrorMessage(e));
    }
  }

  // ── Admin: parent accounts ────────────────────────────────────────────────

  Future<List<ParentAccountSummary>> searchAccounts({
    String? nationalId,
    String? name,
    ParentAccountStatus? status,
    ParentType? parentType,
  }) async {
    try {
      final response = await _apiClient.dio.get(
        '/api/admin/parent-accounts',
        queryParameters: {
          if (nationalId != null && nationalId.isNotEmpty) 'nationalId': nationalId,
          if (name != null && name.isNotEmpty) 'name': name,
          if (status != null) 'status': status.apiValue,
          if (parentType != null) 'parentType': parentType.apiValue,
        },
      );
      final list = response.data as List<dynamic>;
      return list
          .map((e) => ParentAccountSummary.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw Exception(_apiClient.extractErrorMessage(e));
    }
  }

  Future<ParentAccountDetail> getAccountDetail(int id) async {
    try {
      final response = await _apiClient.dio.get('/api/admin/parent-accounts/$id');
      return ParentAccountDetail.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw Exception(_apiClient.extractErrorMessage(e));
    }
  }

  Future<void> activateAccount(int id) => _postAction('/api/admin/parent-accounts/$id/activate');

  Future<void> deactivateAccount(int id) => _postAction('/api/admin/parent-accounts/$id/deactivate');

  Future<void> resetPassword(int id) => _postAction('/api/admin/parent-accounts/$id/reset-password');

  Future<ParentAccountDetail> regenerateAccount(int id) async {
    try {
      final response = await _apiClient.dio.post('/api/admin/parent-accounts/$id/regenerate');
      return ParentAccountDetail.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw Exception(_apiClient.extractErrorMessage(e));
    }
  }

  Future<List<int>> exportAccounts({
    String? nationalId,
    String? name,
    ParentAccountStatus? status,
  }) async {
    try {
      final response = await _apiClient.dio.get(
        '/api/admin/parent-accounts/export',
        queryParameters: {
          if (nationalId != null && nationalId.isNotEmpty) 'nationalId': nationalId,
          if (name != null && name.isNotEmpty) 'name': name,
          if (status != null) 'status': status.apiValue,
        },
        options: Options(responseType: ResponseType.bytes),
      );
      return (response.data as List<int>);
    } on DioException catch (e) {
      throw Exception(_apiClient.extractErrorMessage(e));
    }
  }

  // ── Admin: invalid parent ID validation center ────────────────────────────

  Future<List<InvalidParentIdRecord>> getInvalidRecords({String? search}) async {
    try {
      final response = await _apiClient.dio.get(
        '/api/admin/parent-id-validation',
        queryParameters: {if (search != null && search.isNotEmpty) 'search': search},
      );
      final list = response.data as List<dynamic>;
      return list
          .map((e) => InvalidParentIdRecord.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw Exception(_apiClient.extractErrorMessage(e));
    }
  }

  Future<ParentAccountDetail?> correctInvalidId({
    required int recordId,
    required String correctedNationalId,
    bool generateAccount = true,
  }) async {
    try {
      final response = await _apiClient.dio.put(
        '/api/admin/parent-id-validation/$recordId',
        data: {
          'correctedNationalId': correctedNationalId,
          'generateAccount': generateAccount,
        },
      );
      final data = response.data;
      if (data == null) return null;
      return ParentAccountDetail.fromJson(data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw Exception(_apiClient.extractErrorMessage(e));
    }
  }

  // ── Admin: audit log ──────────────────────────────────────────────────────

  Future<List<ParentAuditLogEntry>> getAuditLog({
    String? nationalId,
    ParentAuditAction? action,
    int take = 100,
  }) async {
    try {
      final response = await _apiClient.dio.get(
        '/api/admin/parent-audit-log',
        queryParameters: {
          if (nationalId != null && nationalId.isNotEmpty) 'nationalId': nationalId,
          if (action != null) 'action': action.name,
          'take': take,
        },
      );
      final list = response.data as List<dynamic>;
      return list
          .map((e) => ParentAuditLogEntry.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw Exception(_apiClient.extractErrorMessage(e));
    }
  }

  Future<void> _postAction(String path) async {
    try {
      await _apiClient.dio.post(path);
    } on DioException catch (e) {
      throw Exception(_apiClient.extractErrorMessage(e));
    }
  }
}
