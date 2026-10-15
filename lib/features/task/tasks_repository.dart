import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api/api_client.dart';
import '../../api/endpoints.dart';
import '../../core/constants.dart';
import '../auth/auth_controller.dart';
import 'task_model.dart';

final tasksRepositoryProvider = Provider<TasksRepository>((ref) {
  return TasksRepository(
    apiClient: ref.read(apiClientProvider),
  );
});

class TasksPage {
  const TasksPage({
    required this.tasks,
    this.nextCursor,
    this.total,
  });

  final List<TaskModel> tasks;
  final String? nextCursor;
  final int? total;
}

class TasksRepository {
  TasksRepository({
    required ApiClient apiClient,
  }) : _apiClient = apiClient;

  final ApiClient _apiClient;

  // ============================================================
  // GET GENERAL TASKS
  // ============================================================

  Future<TasksPage> getGeneralTasks({
    String? cursor,
    String? status,
    String? search,
    int? perPage,
  }) async {
    final endpoint = ApiEndpoints.generalTasks(
      AppConstants.businessId,
    );

    final queryParameters = <String, dynamic>{
      'per_page': perPage ?? AppConstants.pageSize,
    };

    if (cursor != null && cursor.isNotEmpty) {
      queryParameters['cursor'] = cursor;
    }

    if (status != null && status.isNotEmpty && status != 'all') {
      queryParameters['status'] = status;
    }

    if (search != null && search.trim().isNotEmpty) {
      queryParameters['search'] = search.trim();
    }

    if (kDebugMode) {
      debugPrint('========== GET GENERAL TASKS ==========');
      debugPrint('Endpoint: $endpoint');
      debugPrint('Query: $queryParameters');
    }

    try {
      final response = await _apiClient.get(
        endpoint,
        queryParameters: queryParameters,
      );

      if (kDebugMode) {
        debugPrint('GET TASKS STATUS: ${response.statusCode}');
        debugPrint('GET TASKS RESPONSE: ${response.data}');
      }

      final responseData = response.data;

      if (responseData is! Map<String, dynamic>) {
        throw Exception('Invalid tasks response.');
      }

      final rawTasks = responseData['data'];

      if (rawTasks is! List) {
        throw Exception('Invalid tasks data.');
      }

      final tasks = rawTasks
          .whereType<Map<String, dynamic>>()
          .map(TaskModel.fromJson)
          .toList();

      String? nextCursor;
      int? total;

      final meta = responseData['meta'];

      if (meta is Map<String, dynamic>) {
        final cursorValue = meta['next_cursor'];

        if (cursorValue != null &&
            cursorValue.toString().trim().isNotEmpty) {
          nextCursor = cursorValue.toString();
        }

        final totalValue = meta['total'] ?? meta['count'];

        if (totalValue != null) {
          total = int.tryParse(totalValue.toString());
        }
      }

      return TasksPage(
        tasks: tasks,
        nextCursor: nextCursor,
        total: total,
      );
    } catch (error) {
      if (kDebugMode) {
        debugPrint('GET GENERAL TASKS ERROR: $error');
      }

      rethrow;
    }
  }

  // ============================================================
  // GET TASK DETAILS
  // ============================================================

  Future<TaskModel> getTaskDetail(String taskId) async {
    final endpoint = ApiEndpoints.taskDetail(
      AppConstants.businessId,
      taskId,
    );

    final response = await _apiClient.get(endpoint);
    final responseData = response.data;

    if (responseData is Map<String, dynamic>) {
      final data = responseData['data'];

      if (data is Map<String, dynamic>) {
        return TaskModel.fromJson(data);
      }

      if (responseData['id'] != null) {
        return TaskModel.fromJson(responseData);
      }
    }

    throw Exception('Invalid task detail response.');
  }

  // ============================================================
  // RESCHEDULE TASK
  // ============================================================

  Future<void> rescheduleTask({
    required String taskId,
    required DateTime scheduledAt,
    String? reason,
  }) async {
    final endpoint = ApiEndpoints.rescheduleTask(
      AppConstants.businessId,
      taskId,
    );

    final formattedDate =
        '${scheduledAt.year.toString().padLeft(4, '0')}-'
        '${scheduledAt.month.toString().padLeft(2, '0')}-'
        '${scheduledAt.day.toString().padLeft(2, '0')} '
        '${scheduledAt.hour.toString().padLeft(2, '0')}:'
        '${scheduledAt.minute.toString().padLeft(2, '0')}:00';

    final requestData = <String, dynamic>{
      'scheduled_at': formattedDate,
    };

    if (reason != null && reason.trim().isNotEmpty) {
      requestData['reason'] = reason.trim();
    }

    if (kDebugMode) {
      debugPrint('========== RESCHEDULE TASK ==========');
      debugPrint('Endpoint: $endpoint');
      debugPrint('Request: $requestData');
    }

    try {
      final response = await _apiClient.post(
        endpoint,
        data: requestData,
      );

      if (kDebugMode) {
        debugPrint('RESCHEDULE STATUS: ${response.statusCode}');
        debugPrint('RESCHEDULE RESPONSE: ${response.data}');
      }
    } catch (error) {
      if (kDebugMode) {
        debugPrint('RESCHEDULE TASK ERROR: $error');
      }

      rethrow;
    }
  }
// ============================================================
// DELETE TASK
// ============================================================

Future<void> deleteTask(String taskId) async {
  final endpoint = ApiEndpoints.deleteTask(
    AppConstants.businessId,
    taskId,
  );

  if (kDebugMode) {
    debugPrint('========== DELETE TASK ==========');
    debugPrint('Endpoint: $endpoint');
  }

  try {
    final response = await _apiClient.delete(endpoint);

    if (kDebugMode) {
      debugPrint('DELETE TASK STATUS: ${response.statusCode}');
      debugPrint('DELETE TASK RESPONSE: ${response.data}');
    }
  } catch (error) {
    if (kDebugMode) {
      debugPrint('DELETE TASK ERROR: $error');
    }

    rethrow;
  }
}
// ============================================================
// COMPLETE TASK
// ============================================================

Future<void> completeTask({
  required String taskId,
  String? comment,
}) async {
  final endpoint = ApiEndpoints.completeTask(
    AppConstants.businessId,
    taskId,
  );

  final trimmedComment = comment?.trim();

  final Map<String, dynamic> requestData = {};

  if (trimmedComment != null && trimmedComment.isNotEmpty) {
    requestData['comment'] = trimmedComment;
  }

  if (kDebugMode) {
    debugPrint('========== COMPLETE TASK ==========');
    debugPrint('Endpoint: $endpoint');
    debugPrint('Request data: $requestData');
  }

  try {
    final response = await _apiClient.post(
      endpoint,
      data: requestData.isEmpty ? null : requestData,
    );

    if (kDebugMode) {
      debugPrint('COMPLETE TASK STATUS: ${response.statusCode}');
      debugPrint('COMPLETE TASK RESPONSE: ${response.data}');
    }
  } catch (error) {
    if (kDebugMode) {
      debugPrint('COMPLETE TASK ERROR: $error');
    }
    rethrow;
  }
}
Future<void> cancelTask({
  required String taskId,
  String? reason,
}) async {
  final endpoint = ApiEndpoints.cancelTask(
    AppConstants.businessId,
    taskId,
  );

  final trimmedReason = reason?.trim();

  final Map<String, dynamic> requestData = {};

  if (trimmedReason != null && trimmedReason.isNotEmpty) {
    requestData['reason'] = trimmedReason;
  }

  if (kDebugMode) {
    debugPrint('========== CANCEL TASK ==========');
    debugPrint('Endpoint: $endpoint');
    debugPrint('Request data: $requestData');
  }

  try {
    final response = await _apiClient.post(
      endpoint,
      data: requestData.isEmpty ? null : requestData,
    );

    if (kDebugMode) {
      debugPrint('CANCEL TASK STATUS: ${response.statusCode}');
      debugPrint('CANCEL TASK RESPONSE: ${response.data}');
    }
  } catch (error) {
    if (kDebugMode) {
      debugPrint('CANCEL TASK ERROR: $error');
    }

    rethrow;
  }
}
Future<void> completeCallTask({
  required String taskId,
  required String callStatusId,
  String? comment,
  int? callDurationSeconds,
  String? callNotes,
  String? newLeadStatusId,
  String? newDealStatusId,
  String? lostReasonId,
  String? lostReasonNote,
}) async {
  final endpoint = ApiEndpoints.completeCallTask(
    AppConstants.businessId,
    taskId,
  );

  final Map<String, dynamic> requestData = {
    'call_status_id': callStatusId,
  };

  if (comment != null && comment.trim().isNotEmpty) {
    requestData['comment'] = comment.trim();
  }

  if (callDurationSeconds != null) {
    requestData['call_duration_seconds'] = callDurationSeconds;
  }

  if (callNotes != null && callNotes.trim().isNotEmpty) {
    requestData['call_notes'] = callNotes.trim();
  }

  if (newLeadStatusId != null && newLeadStatusId.isNotEmpty) {
    requestData['new_lead_status_id'] = newLeadStatusId;
  }

  if (newDealStatusId != null && newDealStatusId.isNotEmpty) {
    requestData['new_deal_status_id'] = newDealStatusId;
  }

  if (lostReasonId != null && lostReasonId.isNotEmpty) {
    requestData['lost_reason_id'] = lostReasonId;
  }

  if (lostReasonNote != null && lostReasonNote.trim().isNotEmpty) {
    requestData['lost_reason_note'] = lostReasonNote.trim();
  }

  if (kDebugMode) {
    debugPrint('========== COMPLETE CALL TASK ==========');
    debugPrint('Endpoint: $endpoint');
    debugPrint('Request data: $requestData');
  }

  try {
    final response = await _apiClient.post(
      endpoint,
      data: requestData,
    );

    if (kDebugMode) {
      debugPrint('COMPLETE CALL STATUS: ${response.statusCode}');
      debugPrint('COMPLETE CALL RESPONSE: ${response.data}');
    }
  } catch (error) {
    if (kDebugMode) {
      debugPrint('COMPLETE CALL ERROR: $error');
    }

    rethrow;
  }
}
}