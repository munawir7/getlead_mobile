import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:getlead_mobile/features/auth/auth_controller.dart';

import '../../api/api_client.dart';
import '../../api/endpoints.dart';
import '../../core/constants.dart';
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

class LeadMeta {
  const LeadMeta({
    required this.sources,
    required this.statuses,
  });

  final List<LeadSource> sources;
  final List<LeadStatus> statuses;
}

class LeadsRepository {
  LeadsRepository({
    required ApiClient apiClient,
  }) : _apiClient = apiClient;

  final ApiClient _apiClient;

  // ============================================================
  // DEBUG HELPER
  // ============================================================

  void _logRequest(String label, String endpoint) {
    if (!kDebugMode) return;

    debugPrint('========== $label ==========');
    debugPrint('Business ID: ${AppConstants.businessId}');
    debugPrint('Endpoint: $endpoint');
  }

  void _logError(String label, Object error) {
    if (!kDebugMode) return;

    debugPrint('========== $label ERROR ==========');
    debugPrint(error.toString());
    debugPrint('==================================');
  }

  // ============================================================
  // GET LEADS
  // ============================================================

  Future<LeadsPage> getLeads({
    String? cursor,
  }) async {
    final endpoint = ApiEndpoints.leads(
      AppConstants.businessId,
    );

    final queryParameters = <String, dynamic>{
      'per_page': AppConstants.pageSize,
    };

    if (cursor != null && cursor.isNotEmpty) {
      queryParameters['cursor'] = cursor;
    }

    _logRequest('GET LEADS', endpoint);

    try {
      final response = await _apiClient.get(
        endpoint,
        queryParameters: queryParameters,
      );

      if (kDebugMode) {
        debugPrint('GET LEADS STATUS: ${response.statusCode}');
        debugPrint('GET LEADS RESPONSE: ${response.data}');
      }

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

        final totalValue =
            meta['total'] ??
            meta['total_leads'] ??
            meta['count'];

        if (totalValue != null) {
          total = int.tryParse(totalValue.toString());
        }
      }

      if (total == null && responseData['total'] != null) {
        total = int.tryParse(
          responseData['total'].toString(),
        );
      }

      return LeadsPage(
        leads: leads,
        nextCursor: nextCursor,
        total: total,
      );
    } catch (error) {
      _logError('GET LEADS', error);
      rethrow;
    }
  }

  // ============================================================
  // GET LEAD DETAIL
  // ============================================================

  Future<LeadModel> getLeadDetail(String leadId) async {
    final endpoint = ApiEndpoints.leadDetail(
      AppConstants.businessId,
      leadId,
    );

    _logRequest('GET LEAD DETAIL', endpoint);

    try {
      final response = await _apiClient.get(endpoint);

      if (kDebugMode) {
        debugPrint('LEAD DETAIL STATUS: ${response.statusCode}');
        debugPrint('LEAD DETAIL RESPONSE: ${response.data}');
      }

      final responseData = response.data;

      if (responseData is Map<String, dynamic>) {
        final data = responseData['data'];

        if (data is Map<String, dynamic>) {
          return LeadModel.fromJson(data);
        }

        if (responseData['id'] != null) {
          return LeadModel.fromJson(responseData);
        }
      }

      throw Exception('Invalid lead detail response from server.');
    } catch (error) {
      _logError('GET LEAD DETAIL', error);
      rethrow;
    }
  }

  // ============================================================
  // GET LEAD METADATA
  // ============================================================

  Future<LeadMeta> getLeadMeta() async {
    final endpoint = ApiEndpoints.leadMeta(
      AppConstants.businessId,
    );

    _logRequest('GET LEAD METADATA', endpoint);

    try {
      final response = await _apiClient.get(endpoint);

      if (kDebugMode) {
        debugPrint('LEAD META STATUS: ${response.statusCode}');
        debugPrint('LEAD META RESPONSE: ${response.data}');
      }

      final responseData = response.data;

      if (responseData is! Map<String, dynamic>) {
        throw Exception('Invalid lead metadata response.');
      }

      final rawData = responseData['data'];

      final Map<String, dynamic> metaData;

      if (rawData is Map<String, dynamic>) {
        metaData = rawData;
      } else {
        metaData = responseData;
      }

      final sources = <LeadSource>[];
      final rawSources = metaData['sources'];

      if (rawSources is List) {
        for (final item in rawSources) {
          if (item is Map<String, dynamic>) {
            sources.add(LeadSource.fromJson(item));
          }
        }
      }

      final statuses = <LeadStatus>[];
      final rawStatuses = metaData['statuses'];

      if (rawStatuses is List) {
        for (final item in rawStatuses) {
          if (item is Map<String, dynamic>) {
            statuses.add(LeadStatus.fromJson(item));
          }
        }
      }

      return LeadMeta(
        sources: sources,
        statuses: statuses,
      );
    } catch (error) {
      _logError('GET LEAD METADATA', error);
      rethrow;
    }
  }

  // ============================================================
  // CREATE LEAD
  // ============================================================

  Future<LeadModel> createLead({
    required String name,
    required String phoneNumber,
    String? email,
    required String sourceId,
    String? statusId,
    String? notes,
  }) async {
    final data = <String, dynamic>{
      'name': name.trim(),
      'phone_numbers': [
        {'phone_number': phoneNumber.trim()},
      ],
      'source_id': sourceId,
    };

    if (email != null && email.trim().isNotEmpty) {
      data['email'] = email.trim();
    }

    if (statusId != null && statusId.trim().isNotEmpty) {
      data['status_id'] = statusId.trim();
    }

    if (notes != null && notes.trim().isNotEmpty) {
      data['notes'] = notes.trim();
    }

    final endpoint = ApiEndpoints.leads(
      AppConstants.businessId,
    );

    _logRequest('CREATE LEAD', endpoint);

    try {
      final response = await _apiClient.post(
        endpoint,
        data: data,
      );

      if (kDebugMode) {
        debugPrint('CREATE LEAD STATUS: ${response.statusCode}');
        debugPrint('CREATE LEAD RESPONSE: ${response.data}');
      }

      final responseData = response.data;

      if (responseData is! Map<String, dynamic>) {
        throw Exception('Invalid create lead response.');
      }

      final responseLead = responseData['data'];

      if (responseLead is Map<String, dynamic>) {
        return LeadModel.fromJson(responseLead);
      }

      final leadId = responseData['id'];

      if (leadId != null && leadId.toString().trim().isNotEmpty) {
        return getLeadDetail(leadId.toString());
      }

      throw Exception('Created lead ID was not returned by the server.');
    } catch (error) {
      _logError('CREATE LEAD', error);
      rethrow;
    }
  }

  // ============================================================
  // EDIT LEAD - PUT
  // ============================================================

  Future<LeadModel> editLead({
    required String leadId,
    required String name,
    required String phoneNumber,
    String? email,
    required String sourceId,
    String? statusId,
    String? notes,
  }) async {
    final data = <String, dynamic>{
      'name': name.trim(),
      'source_id': sourceId,
      'phone_numbers': [
        {'phone_number': phoneNumber.trim()},
      ],
      'email': email?.trim().isNotEmpty == true
          ? email!.trim()
          : null,
      'status_id': statusId?.trim().isNotEmpty == true
          ? statusId!.trim()
          : null,
      'notes': notes?.trim().isNotEmpty == true
          ? notes!.trim()
          : null,
    };

    final endpoint = ApiEndpoints.updateLead(
      AppConstants.businessId,
      leadId,
    );

    _logRequest('EDIT LEAD', endpoint);

    if (kDebugMode) {
      debugPrint('EDIT LEAD BODY: $data');
    }

    try {
      final response = await _apiClient.put(
        endpoint,
        data: data,
      );

      if (kDebugMode) {
        debugPrint('EDIT LEAD STATUS: ${response.statusCode}');
        debugPrint('EDIT LEAD RESPONSE: ${response.data}');
      }

      if (response.statusCode == 200 ||
          response.statusCode == 201) {
        return getLeadDetail(leadId);
      }

      throw Exception('Failed to update lead.');
    } catch (error) {
      _logError('EDIT LEAD', error);
      rethrow;
    }
  }

  // ============================================================
  // PATCH LEAD
  // ============================================================

  Future<LeadModel> patchLead({
    required String leadId,
    required Map<String, dynamic> changes,
  }) async {
    if (changes.isEmpty) {
      return getLeadDetail(leadId);
    }

    final endpoint = ApiEndpoints.patchLead(
      AppConstants.businessId,
      leadId,
    );

    _logRequest('PATCH LEAD', endpoint);

    try {
      final response = await _apiClient.patch(
        endpoint,
        data: changes,
      );

      if (kDebugMode) {
        debugPrint('PATCH LEAD STATUS: ${response.statusCode}');
        debugPrint('PATCH LEAD RESPONSE: ${response.data}');
      }

      final responseData = response.data;

      if (responseData is Map<String, dynamic>) {
        final dataValue = responseData['data'];

        if (dataValue is Map<String, dynamic>) {
          return LeadModel.fromJson(dataValue);
        }

        if (responseData['id'] != null) {
          return LeadModel.fromJson(responseData);
        }
      }

      return getLeadDetail(leadId);
    } catch (error) {
      _logError('PATCH LEAD', error);
      rethrow;
    }
  }

  // ============================================================
  // UPDATE LEAD STATUS
  // ============================================================

  Future<LeadModel> updateLeadStatus({
    required String leadId,
    required String statusId,
  }) async {
    final endpoint = ApiEndpoints.updateLeadStatus(
      AppConstants.businessId,
      leadId,
    );

    _logRequest('UPDATE LEAD STATUS', endpoint);

    try {
      final response = await _apiClient.patch(
        endpoint,
        data: {'status_id': statusId},
      );

      if (kDebugMode) {
        debugPrint('UPDATE STATUS RESPONSE: ${response.data}');
      }

      final responseData = response.data;

      if (responseData is Map<String, dynamic>) {
        final dataValue = responseData['data'];

        if (dataValue is Map<String, dynamic>) {
          return LeadModel.fromJson(dataValue);
        }

        if (responseData['id'] != null) {
          return LeadModel.fromJson(responseData);
        }
      }

      return getLeadDetail(leadId);
    } catch (error) {
      _logError('UPDATE LEAD STATUS', error);
      rethrow;
    }
  }

  // ============================================================
  // TOGGLE LEAD STAR
  // ============================================================

  Future<LeadModel> toggleLeadStar({
    required String leadId,
  }) async {
    final endpoint = ApiEndpoints.toggleLeadStar(
      AppConstants.businessId,
      leadId,
    );

    _logRequest('TOGGLE LEAD STAR', endpoint);

    try {
      final response = await _apiClient.patch(endpoint);

      if (kDebugMode) {
        debugPrint('TOGGLE STAR RESPONSE: ${response.data}');
      }

      final responseData = response.data;

      if (responseData is Map<String, dynamic>) {
        final dataValue = responseData['data'];

        if (dataValue is Map<String, dynamic>) {
          return LeadModel.fromJson(dataValue);
        }

        if (responseData['id'] != null) {
          return LeadModel.fromJson(responseData);
        }
      }

      return getLeadDetail(leadId);
    } catch (error) {
      _logError('TOGGLE LEAD STAR', error);
      rethrow;
    }
  }

  // ============================================================
  // DELETE LEAD
  // ============================================================

  Future<void> deleteLead({
    required String leadId,
  }) async {
    final endpoint = ApiEndpoints.deleteLead(
      AppConstants.businessId,
      leadId,
    );

    _logRequest('DELETE LEAD', endpoint);

    try {
      final response = await _apiClient.delete(endpoint);

      if (kDebugMode) {
        debugPrint('DELETE LEAD STATUS: ${response.statusCode}');
        debugPrint('DELETE LEAD RESPONSE: ${response.data}');
      }
    } catch (error) {
      _logError('DELETE LEAD', error);
      rethrow;
    }
  }
}