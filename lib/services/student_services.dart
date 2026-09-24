import 'dart:convert';

import 'package:dio/dio.dart';

import '../features/admin/models/parent_account_models.dart';
import '../models/student_models.dart';
import 'api_client.dart';

class AuthService {
  AuthService(this._apiClient);

  final ApiClient _apiClient;

  StudentProfile? _currentStudent;
  ParentProfile? _currentParent;
  static const _mobileRoleKey = 'mobile_auth_role';
  static const _parentProfileKey = 'parent_profile_cache';

  StudentProfile? get currentStudent => _currentStudent;
  ParentProfile? get currentParent => _currentParent;

  Future<String?> readMobileToken() => _apiClient.readToken();
  Future<String?> readMobileRole() => _apiClient.readSecure(_mobileRoleKey);

  Future<void> restoreSession() async {
    final token = await _apiClient.readToken();
    if (token == null || token.isEmpty) {
      _currentStudent = null;
      _currentParent = null;
      return;
    }

    await _apiClient.tryRefreshSession();

    final role = await readMobileRole();
    if (role == 'Parent' || role == null || role.isEmpty) {
      await _restoreCachedParent();
      final loaded = await _loadParentProfile();
      if (loaded) {
        if (role != 'Parent') {
          await _apiClient.writeSecure(_mobileRoleKey, 'Parent');
        }
        return;
      }
      if (_currentParent != null) return;
    }
    if (role == 'Teacher' || role == 'Admin' || role == 'Driver') {
      _currentStudent = null;
      return;
    }
    if (role == 'Parent') return;

    try {
      final response = await _apiClient.dio.get('/api/student/profile');
      _currentStudent = StudentProfile.fromJson(
        response.data as Map<String, dynamic>,
      );
    } on DioException {
      // أبقِ الجلسة المحلية. التوكين المنتهي يتجدد تلقائياً بدون تسجيل خروج.
    }
  }

  Future<bool> _loadParentProfile() async {
    try {
      final response = await _apiClient.dio.get('/api/parent/profile');
      _currentStudent = null;
      _currentParent = ParentProfile.fromJson(response.data as Map<String, dynamic>);
      await _cacheParentProfile(response.data);
      return true;
    } on DioException {
      return false;
    }
  }

  Future<void> _restoreCachedParent() async {
    try {
      final raw = await _apiClient.readSecure(_parentProfileKey);
      if (raw == null || raw.isEmpty) return;
      final json = jsonDecode(raw);
      if (json is Map<String, dynamic>) {
        _currentParent = ParentProfile.fromJson(json);
      } else if (json is Map) {
        _currentParent = ParentProfile.fromJson(Map<String, dynamic>.from(json));
      }
    } catch (_) {}
  }

  Future<void> _cacheParentProfile(dynamic data) async {
    if (data is! Map) return;
    try {
      await _apiClient.writeSecure(
        _parentProfileKey,
        jsonEncode(Map<String, dynamic>.from(data)),
      );
    } catch (_) {}
  }

  Future<StudentProfile> loginStudent(String username, String password) async {
    try {
      final response = await _apiClient.dio.post(
        '/api/auth/login',
        data: {
          'username': username,
          'password': password,
        },
      );

      final loginResponse = LoginResponse.fromJson(
        response.data as Map<String, dynamic>,
      );

      await _apiClient.saveToken(loginResponse.token);
      await _apiClient.writeSecure(_mobileRoleKey, 'Student');
      _currentStudent = loginResponse.student;
      return loginResponse.student;
    } on DioException catch (e) {
      throw Exception(_apiClient.extractErrorMessage(e));
    }
  }

  Future<ParentLoginResponse> loginParent(String nationalId, String password) async {
    try {
      await _apiClient.clearToken();
      final id = nationalId.trim();
      final payload = {
        'username': id,
        'Username': id,
        'nationalId': id,
        'password': password,
        'Password': password,
      };
      late final Response response;
      DioException? lastError;
      for (var attempt = 0; attempt < 3; attempt++) {
        try {
          response = await _apiClient.dio.post(
            '/api/communication/auth/parent/login',
            data: payload,
          );
          lastError = null;
          break;
        } on DioException catch (e) {
          lastError = e;
          final code = e.response?.statusCode;
          final retryable = code == 500 ||
              e.type == DioExceptionType.connectionError ||
              e.type == DioExceptionType.connectionTimeout ||
              e.type == DioExceptionType.receiveTimeout;
          if (!retryable || attempt == 2) rethrow;
          await Future<void>.delayed(Duration(milliseconds: 400 * (attempt + 1)));
        }
      }
      if (lastError != null) throw lastError;
      final raw = response.data;
      if (raw is! Map) {
        throw Exception(
          'السيرفر لم يُرجع بيانات الدخول. تأكد أن التطبيق يتصل بـ https://alsakrschools.com',
        );
      }
      final loginResponse = ParentLoginResponse.fromJson(Map<String, dynamic>.from(raw));
      if (!loginResponse.profile.canLogin) {
        throw Exception(
          loginResponse.profile.status == ParentAccountStatus.inactive
              ? 'الحساب غير نشط. تواصل مع الإدارة.'
              : 'لا يمكن تسجيل الدخول. حالة الحساب: ${loginResponse.profile.status.labelAr}',
        );
      }
      await _apiClient.saveToken(loginResponse.token);
      await _apiClient.writeSecure(_mobileRoleKey, 'Parent');
      _currentParent = loginResponse.profile;
      final profileRaw = raw['profile'] ?? raw['Profile'] ?? raw;
      await _cacheParentProfile(profileRaw);
      return loginResponse;
    } on DioException catch (e) {
      throw Exception(_apiClient.extractErrorMessage(e));
    } on FormatException catch (e) {
      throw Exception('رد السيرفر غير مكتمل. ${e.message}');
    } catch (e) {
      final text = e.toString().replaceFirst('Exception: ', '');
      if (text.contains('السيرفر') ||
          text.contains('الحساب') ||
          text.contains('لا يمكن')) {
        throw Exception(text);
      }
      throw Exception('تعذر إكمال تسجيل الدخول. حاول مرة أخرى.');
    }
  }

  void updateCurrentParent(ParentProfile profile) => _currentParent = profile;

  Future<Map<String, dynamic>> loginTeacher(String email, String password) async {
    try {
      final response = await _apiClient.dio.post(
        '/api/communication/auth/teacher/login',
        data: {'username': email, 'password': password},
      );
      final data = response.data as Map<String, dynamic>;
      await _apiClient.saveToken(data['token'] as String);
      await _apiClient.writeSecure(_mobileRoleKey, 'Teacher');
      return data;
    } on DioException catch (e) {
      throw Exception(_apiClient.extractErrorMessage(e));
    }
  }

  Future<void> logout() async {
    await _apiClient.clearToken();
    await _apiClient.deleteSecure(_mobileRoleKey);
    await _apiClient.deleteSecure(_parentProfileKey);
    _currentStudent = null;
    _currentParent = null;
  }
}

class StudentService {
  StudentService(this._apiClient);

  final ApiClient _apiClient;

  Future<StudentProfile> getProfile() async {
    return _get(() => _apiClient.dio.get('/api/student/profile'), StudentProfile.fromJson);
  }

  Future<StudentResultsResponse> getResults() async {
    return _get(
      () => _apiClient.dio.get('/api/student/results'),
      StudentResultsResponse.fromJson,
    );
  }

  Future<StudentFeesResponse> getFees() async {
    return _get(
      () => _apiClient.dio.get('/api/student/fees'),
      StudentFeesResponse.fromJson,
    );
  }

  Future<List<StudentVideo>> getVideos() async {
    try {
      final response = await _apiClient.dio.get('/api/student/videos');
      final list = response.data as List<dynamic>;
      return list
          .map((e) => StudentVideo.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw Exception(_apiClient.extractErrorMessage(e));
    }
  }

  Future<T> _get<T>(
    Future<Response<dynamic>> Function() request,
    T Function(Map<String, dynamic>) fromJson,
  ) async {
    try {
      final response = await request();
      return fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw Exception(_apiClient.extractErrorMessage(e));
    }
  }
}
