import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';

import '../../../models/student_models.dart';
import '../../../services/api_client.dart';
import '../models/parent_family_models.dart';

class ParentFamilyService {
  ParentFamilyService(this._apiClient);

  final ApiClient _apiClient;

  Future<FamilyDashboardSummary> getFamilyDashboard() async {
    final response = await _apiClient.dio.get('/api/parent/children');
    return FamilyDashboardSummary.fromJson(response.data as Map<String, dynamic>);
  }

  Future<FamilyDashboardSummary> getFamilyOverview() async {
    final response = await _apiClient.dio.get('/api/parent/family/summary');
    final children = (response.data['children'] as List<dynamic>? ?? [])
        .map((e) => ChildDashboardSummary.fromJson(e as Map<String, dynamic>))
        .toList();
    return FamilyDashboardSummary(
      totalChildren: children.length,
      children: children,
    );
  }

  Future<FamilyTransportationSummary> getFamilyTransportation() async {
    final response = await _apiClient.dio.get('/api/parent/family/transportation');
    return FamilyTransportationSummary.fromJson(response.data as Map<String, dynamic>);
  }

  Future<ChildDashboardSummary> switchActiveChild(int studentId) async {
    final response = await _apiClient.dio.post(
      '/api/parent/active-child',
      data: {'studentId': studentId},
    );
    final data = response.data as Map<String, dynamic>;
    return ChildDashboardSummary.fromJson(data['child'] as Map<String, dynamic>);
  }

  Future<({int? activeStudentId, ChildDashboardSummary? child})> getActiveChild() async {
    final response = await _apiClient.dio.get('/api/parent/active-child');
    final data = response.data as Map<String, dynamic>;
    final childJson = data['child'];
    return (
      activeStudentId: data['activeStudentId'] as int?,
      child: childJson != null
          ? ChildDashboardSummary.fromJson(childJson as Map<String, dynamic>)
          : null,
    );
  }

  Future<ChildDashboardSummary> getChildSummary(int studentId) async {
    final response = await _apiClient.dio.get('/api/parent/children/$studentId/summary');
    return ChildDashboardSummary.fromJson(response.data as Map<String, dynamic>);
  }

  Future<StudentResultsResponse> getChildResults(int studentId) async {
    final response = await _apiClient.dio.get('/api/parent/children/$studentId/results');
    return StudentResultsResponse.fromJson(response.data as Map<String, dynamic>);
  }

  Future<StudentFeesResponse> getChildFees(int studentId) async {
    final response = await _apiClient.dio.get('/api/parent/children/$studentId/fees');
    return StudentFeesResponse.fromJson(response.data as Map<String, dynamic>);
  }

  Future<List<ParentHomeworkItem>> getChildHomework(int studentId) async {
    final response = await _apiClient.dio.get('/api/parent/children/$studentId/homework');
    final list = response.data as List<dynamic>;
    return list.map((e) => ParentHomeworkItem.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<ParentAttendanceSummary> getChildAttendance(int studentId) async {
    final response = await _apiClient.dio.get('/api/parent/children/$studentId/attendance');
    return ParentAttendanceSummary.fromJson(response.data as Map<String, dynamic>);
  }

  Future<List<ParentPublishedReport>> getChildReports(int studentId) async {
    final response = await _apiClient.dio.get('/api/parent/children/$studentId/reports');
    final list = response.data as List<dynamic>;
    return list
        .map((e) => ParentPublishedReport.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<ParentPublishedReport> uploadChildReport({
    required int studentId,
    required String title,
    String? body,
    required String category,
    List<int>? bytes,
    String? filename,
  }) async {
    try {
      final map = <String, dynamic>{
        'title': title,
        'body': body ?? '',
        'category': category,
      };
      if (bytes != null && bytes.isNotEmpty && filename != null) {
        map['file'] = MultipartFile.fromBytes(bytes, filename: filename);
      }
      final formData = FormData.fromMap(map);
      final response = await _apiClient.dio.post(
        '/api/parent/children/$studentId/reports',
        data: formData,
        options: Options(
          sendTimeout: const Duration(minutes: 2),
          receiveTimeout: const Duration(minutes: 2),
        ),
      );
      final data = response.data;
      if (data is Map && data['report'] is Map) {
        return ParentPublishedReport.fromJson(
          Map<String, dynamic>.from(data['report'] as Map),
        );
      }
      throw Exception('تم رفع التقرير.');
    } on DioException catch (e) {
      throw Exception(_apiClient.extractErrorMessage(e));
    }
  }

  Future<List<ParentChildNotification>> getNotifications({int take = 50}) async {
    final response = await _apiClient.dio.get('/api/parent/notifications', queryParameters: {'take': take});
    final list = response.data as List<dynamic>;
    return list.map((e) => ParentChildNotification.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<ParentUnreadSummary> getUnreadSummary() async {
    try {
      final response = await _apiClient.dio.get('/api/parent/unread-summary');
      return ParentUnreadSummary.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.statusCode != 404) {
        throw Exception(_apiClient.extractErrorMessage(e));
      }
      final notes = await getNotifications();
      final notifications = notes.where((n) => !n.isRead).length;
      var chats = 0;
      try {
        final comm = await _apiClient.dio.get(
          '/api/communication/notifications',
          queryParameters: {'page': 0},
        );
        chats = (comm.data as Map<String, dynamic>)['unread'] as int? ?? 0;
      } catch (_) {}
      return ParentUnreadSummary(
        notifications: notifications,
        chats: chats,
        total: notifications + chats,
      );
    }
  }

  Future<ParentUnreadSummary> markAllNotificationsRead() async {
    try {
      final response = await _apiClient.dio.post('/api/parent/notifications/read-all');
      return ParentUnreadSummary.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.statusCode != 404) {
        throw Exception(_apiClient.extractErrorMessage(e));
      }
      final summary = await getUnreadSummary();
      return ParentUnreadSummary(
        notifications: 0,
        chats: summary.chats,
        total: summary.chats,
      );
    }
  }

  Future<String> uploadChildPhoto(int studentId, Uint8List bytes) async {
    try {
      final formData = FormData.fromMap({
        'photo': MultipartFile.fromBytes(
          bytes,
          filename: 'photo.jpg',
          contentType: MediaType('image', 'jpeg'),
        ),
      });
      final response = await _apiClient.dio.post(
        '/api/parent/children/$studentId/photo',
        data: formData,
        options: Options(
          sendTimeout: const Duration(minutes: 2),
          receiveTimeout: const Duration(minutes: 2),
        ),
      );
      final data = response.data;
      if (data is! Map) {
        throw Exception(
          'تعذر حفظ الصورة على السيرفر. تأكد أن نسخة الموقع المنشورة هي الأحدث.',
        );
      }
      final photoUrl =
          (data['photoUrl'] ?? data['PhotoUrl'])?.toString().trim() ?? '';
      if (photoUrl.isEmpty) {
        throw Exception(
          'السيرفر لم يُرجع رابط الصورة. أعد رفع نسخة الموقع ثم حاول مرة أخرى.',
        );
      }
      return photoUrl;
    } on DioException catch (e) {
      throw Exception(_apiClient.extractErrorMessage(e));
    }
  }

  Future<void> refreshChildData(int studentId) async {
    await Future.wait([
      getChildSummary(studentId),
      getChildResults(studentId),
      getChildFees(studentId),
      getChildHomework(studentId),
      getChildAttendance(studentId),
    ], eagerError: false);
  }
}
