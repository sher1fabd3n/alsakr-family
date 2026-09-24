import 'package:dio/dio.dart';

import '../../../services/api_client.dart';
import '../models/education_content_models.dart';

class EducationContentService {
  EducationContentService(this._apiClient);

  final ApiClient _apiClient;

  // ── Quizzes ─────────────────────────────────────────────────────────

  Future<List<FamilyQuizSummary>> getAvailableQuizzes(int classId) async {
    try {
      final response = await _apiClient.dio.get(
        '/api/education/quizzes/available',
        queryParameters: {'classId': classId},
      );
      final list = response.data as List<dynamic>;
      return list
          .map((e) => FamilyQuizSummary.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw Exception(_apiClient.extractErrorMessage(e));
    }
  }

  Future<Map<String, dynamic>> startQuiz(int quizId) async {
    try {
      final response = await _apiClient.dio.post(
        '/api/education/quizzes/$quizId/start',
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw Exception(_apiClient.extractErrorMessage(e));
    }
  }

  Future<FamilyQuizResult> submitQuiz({
    required int attemptId,
    required List<Map<String, dynamic>> answers,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        '/api/education/quizzes/attempts/$attemptId/submit',
        data: answers,
      );
      return FamilyQuizResult.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw Exception(_apiClient.extractErrorMessage(e));
    }
  }

  // ── Schedule ────────────────────────────────────────────────────────

  Future<FamilyScheduleResult> getClassSchedule(
    int classId, {
    int? academicYearId,
  }) async {
    try {
      final query = <String, dynamic>{};
      if (academicYearId != null && academicYearId > 0) {
        query['academicYearId'] = academicYearId;
      }

      final response = await _apiClient.dio.get(
        '/api/education/schedule/class/$classId',
        queryParameters: query.isEmpty ? null : query,
      );

      String? imageUrl;
      String? fileType;
      List<dynamic> list = const [];
      final data = response.data;
      if (data is Map<String, dynamic>) {
        imageUrl = data['imageUrl'] as String?;
        fileType = data['fileType'] as String?;
        list = data['items'] as List<dynamic>? ?? const [];
      } else if (data is List<dynamic>) {
        list = data;
      }

      final dayNames = ['الأحد', 'الإثنين', 'الثلاثاء', 'الأربعاء', 'الخميس'];
      final slotsByDay = <int, List<FamilyScheduleSlot>>{};

      for (final item in list) {
        final json = item as Map<String, dynamic>;
        final dayIndex = FamilyScheduleSlot.dayIndexFromJson(json['dayOfWeek']);
        if (dayIndex > 4) continue;
        slotsByDay.putIfAbsent(dayIndex, () => []).add(FamilyScheduleSlot.fromJson(json));
      }

      final days = List.generate(5, (i) {
        final daySlots = slotsByDay[i] ?? [];
        daySlots.sort((a, b) => a.startTime.compareTo(b.startTime));
        return FamilyScheduleDay(
          dayName: dayNames[i],
          dayOfWeek: i,
          slots: daySlots,
        );
      });

      return FamilyScheduleResult(imageUrl: imageUrl, fileType: fileType, days: days);
    } on DioException catch (e) {
      throw Exception(_apiClient.extractErrorMessage(e));
    }
  }

  // ── Videos ──────────────────────────────────────────────────────────

  Future<List<FamilyEducationalVideo>> getClassVideos(int classId) async {
    try {
      final response = await _apiClient.dio.get(
        '/api/education/videos/class/$classId',
      );
      final list = response.data as List<dynamic>;
      return list
          .map((e) => FamilyEducationalVideo.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw Exception(_apiClient.extractErrorMessage(e));
    }
  }
}
