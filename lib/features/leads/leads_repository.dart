
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api/api_client.dart';
import '../../api/endpoints.dart';
import '../../core/constants.dart';
import '../auth/auth_controller.dart';
import 'lead_model.dart';

final leadsRepositoryProvider = Provider<LeadsRepository>((ref) {
  return LeadsRepository(
    apiClient: ref.read(apiClientProvider),
  );
});

class LeadsPage {
  const LeadsPage({
    required this.leads,
    required this.nextCursor,
    this.total,
  });

  final List<LeadModel> leads;
  final String? nextCursor;
  final int? total;
}

class LeadsRepository {
  LeadsRepository({
    required ApiClient apiClient,
  }) : _apiClient = apiClient;

  final ApiClient _apiClient;

  Future<LeadsPage> getLeads({
    String? cursor,
  }) async {
    final queryParameters = <String, dynamic>{
      'per_page': AppConstants.pageSize,
    };

    if (cursor != null && cursor.isNotEmpty) {
      queryParameters['cursor'] = cursor;
    }

    final response = await _apiClient.get(
      ApiEndpoints.leads(AppConstants.businessId),
      queryParameters: queryParameters,
    );

    final responseData = response.data;

    if (responseData is! Map<String, dynamic>) {
      throw Exception('Invalid leads response.');
    }

    final data = responseData['data'];

    if (data is! List) {
      throw Exception('Invalid leads data.');
    }

    final leads = data
        .whereType<Map<String, dynamic>>()
        .map(LeadModel.fromJson)
        .toList();

    String? nextCursor;
    int? total;

    final meta = responseData['meta'];

    if (meta is Map<String, dynamic>) {
      final cursorValue = meta['next_cursor'];

      if (cursorValue != null) {
        final value = cursorValue.toString().trim();

        if (value.isNotEmpty) {
          nextCursor = value;
        }
      }

      final totalVal = meta['total'] ?? meta['total_leads'] ?? meta['count'];
      if (totalVal != null) {
        total = int.tryParse(totalVal.toString());
      }
    }

    if (total == null && responseData['total'] != null) {
      total = int.tryParse(responseData['total'].toString());
    }

    return LeadsPage(
      leads: leads,
      nextCursor: nextCursor,
      total: total,
    );
  }

  Future<LeadModel> getLeadDetail(String leadId) async {
    final response = await _apiClient.get(
      ApiEndpoints.leadDetail(
        AppConstants.businessId,
        leadId,
      ),
    );

    final responseData = response.data;

    if (responseData is! Map<String, dynamic>) {
      throw Exception('Invalid lead response.');
    }

    final data = responseData['data'];

    if (data is! Map<String, dynamic>) {
      throw Exception('Invalid lead data.');
    }

    return LeadModel.fromJson(data);
  }
}

