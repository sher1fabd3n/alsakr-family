import 'package:dio/dio.dart';

import '../../../services/api_client.dart';
import '../models/student_ticket_models.dart';

class ParentTicketService {
  ParentTicketService(this._apiClient);

  final ApiClient _apiClient;

  Future<List<StudentTicketSummary>> getTickets({int? studentId}) async {
    final response = await _apiClient.dio.get(
      '/api/parent/tickets',
      queryParameters: {if (studentId != null) 'studentId': studentId},
    );
    final list = response.data as List<dynamic>;
    return list
        .map((e) => StudentTicketSummary.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<StudentTicketDetail> getTicket(int id) async {
    final response = await _apiClient.dio.get('/api/parent/tickets/$id');
    return StudentTicketDetail.fromJson(response.data as Map<String, dynamic>);
  }

  Future<StudentTicketDetail> createTicket({
    required int studentId,
    required StudentTicketType type,
    required String title,
    required String content,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        '/api/parent/tickets',
        data: {
          'studentId': studentId,
          'type': ticketTypeToApi(type),
          'title': title,
          'content': content,
        },
      );
      return StudentTicketDetail.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw Exception(_apiClient.extractErrorMessage(e));
    }
  }

  Future<StudentTicketDetail> reply(int ticketId, String message) async {
    try {
      final response = await _apiClient.dio.post(
        '/api/parent/tickets/$ticketId/reply',
        data: {'message': message},
      );
      return StudentTicketDetail.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw Exception(_apiClient.extractErrorMessage(e));
    }
  }
}

class AdminTicketService {
  AdminTicketService(this._apiClient);

  final ApiClient _apiClient;

  Future<StudentTicketStats> getStats() async {
    final response = await _apiClient.dio.get('/api/admin/student-tickets/stats');
    return StudentTicketStats.fromJson(response.data as Map<String, dynamic>);
  }

  Future<List<StudentTicketSummary>> searchTickets({
    String? status,
    String? search,
  }) async {
    final response = await _apiClient.dio.get(
      '/api/admin/student-tickets',
      queryParameters: {
        if (status != null && status.isNotEmpty && status != 'all') 'status': status,
        if (search != null && search.isNotEmpty) 'search': search,
      },
    );
    final list = response.data as List<dynamic>;
    return list
        .map((e) => StudentTicketSummary.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<StudentTicketDetail> getTicket(int id) async {
    final response = await _apiClient.dio.get('/api/admin/student-tickets/$id');
    return StudentTicketDetail.fromJson(response.data as Map<String, dynamic>);
  }

  Future<StudentTicketDetail> reply(int ticketId, String message) async {
    try {
      final response = await _apiClient.dio.post(
        '/api/admin/student-tickets/$ticketId/reply',
        data: {'message': message},
      );
      return StudentTicketDetail.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw Exception(_apiClient.extractErrorMessage(e));
    }
  }

  Future<StudentTicketDetail> close(int ticketId) async {
    try {
      final response = await _apiClient.dio.post('/api/admin/student-tickets/$ticketId/close');
      return StudentTicketDetail.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw Exception(_apiClient.extractErrorMessage(e));
    }
  }
}
