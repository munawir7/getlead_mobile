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

/// Data returned by the /meta endpoint.
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
  // GET LEADS
  // ============================================================

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
      ApiEndpoints.leads(
        AppConstants.businessId,
      ),
      queryParameters: queryParameters,
    );

    final responseData = response.data;

    if (responseData is! Map<String, dynamic>) {
      throw Exception(
        'Invalid leads response.',
      );
    }

    final data = responseData['data'];

    if (data is! List) {
      throw Exception(
        'Invalid leads data.',
      );
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
        total = int.tryParse(
          totalValue.toString(),
        );
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
  }

  // ============================================================
  // GET LEAD DETAIL
  // ============================================================

  Future<LeadModel> getLeadDetail(String leadId) async {
    final response = await _apiClient.get(
      ApiEndpoints.leadDetail(
        AppConstants.businessId,
        leadId,
      ),
    );

    final responseData = response.data;

    if (responseData is Map<String, dynamic>) {
      // Most mobile API responses return:
      //
      // {
      //   "data": {
      //      ...
      //   }
      // }

      final data = responseData['data'];

      if (data is Map<String, dynamic>) {
        return LeadModel.fromJson(data);
      }

      // Also support a direct lead object response.
      if (responseData['id'] != null) {
        return LeadModel.fromJson(responseData);
      }
    }

    throw Exception(
      'Invalid lead detail response from server.',
    );
  }

  // ============================================================
  // GET META
  // ============================================================

  Future<LeadMeta> getLeadMeta() async {
    final response = await _apiClient.get(
      ApiEndpoints.leadMeta(
        AppConstants.businessId,
      ),
    );

    final responseData = response.data;

    if (responseData is! Map<String, dynamic>) {
      throw Exception(
        'Invalid lead meta response.',
      );
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
          sources.add(
            LeadSource.fromJson(item),
          );
        }
      }
    }

    final statuses = <LeadStatus>[];

    final rawStatuses = metaData['statuses'];

    if (rawStatuses is List) {
      for (final item in rawStatuses) {
        if (item is Map<String, dynamic>) {
          statuses.add(
            LeadStatus.fromJson(item),
          );
        }
      }
    }

    return LeadMeta(
      sources: sources,
      statuses: statuses,
    );
  }

  // ============================================================
  // CREATE LEAD - POST
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
        {
          'phone_number': phoneNumber.trim(),
        },
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

    final response = await _apiClient.post(
      ApiEndpoints.leads(
        AppConstants.businessId,
      ),
      data: data,
    );

    final responseData = response.data;

    if (responseData is! Map<String, dynamic>) {
      throw Exception(
        'Invalid create lead response.',
      );
    }

    final responseLead = responseData['data'];

    if (responseLead is Map<String, dynamic>) {
      return LeadModel.fromJson(
        responseLead,
      );
    }

    final leadId = responseData['id'];

    if (leadId != null &&
        leadId.toString().trim().isNotEmpty) {
      return getLeadDetail(
        leadId.toString(),
      );
    }

    throw Exception(
      'Created lead ID was not returned by the server.',
    );
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
        {
          'phone_number': phoneNumber.trim(),
        },
      ],
    };

    if (email != null && email.trim().isNotEmpty) {
      data['email'] = email.trim();
    } else {
      data['email'] = null;
    }

    if (statusId != null && statusId.trim().isNotEmpty) {
      data['status_id'] = statusId.trim();
    } else {
      data['status_id'] = null;
    }

    if (notes != null && notes.trim().isNotEmpty) {
      data['notes'] = notes.trim();
    } else {
      data['notes'] = null;
    }

    // ------------------------------------------------------------
    // DEBUG REQUEST
    // ------------------------------------------------------------

    assert(() {
      // ignore: avoid_print
      print('================================');
      // ignore: avoid_print
      print('PUT EDIT LEAD');
      // ignore: avoid_print
      print('Lead ID: $leadId');
      // ignore: avoid_print
      print('Request body: $data');
      // ignore: avoid_print
      print('================================');

      return true;
    }());

    final response = await _apiClient.put(
      ApiEndpoints.updateLead(
        AppConstants.businessId,
        leadId,
      ),
      data: data,
    );

    // ------------------------------------------------------------
    // DEBUG RESPONSE
    // ------------------------------------------------------------

    assert(() {
      // ignore: avoid_print
      print('================================');
      // ignore: avoid_print
      print('PUT STATUS: ${response.statusCode}');
      // ignore: avoid_print
      print('PUT RESPONSE: ${response.data}');
      // ignore: avoid_print
      print('================================');

      return true;
    }());

    // ------------------------------------------------------------
    // IMPORTANT
    //
    // Do not use the PUT response as the final LeadModel.
    // The PUT response may not contain the complete lead data.
    //
    // After a successful PUT, fetch the complete lead again.
    // ------------------------------------------------------------

    if (response.statusCode == 200 ||
        response.statusCode == 201) {
      return getLeadDetail(leadId);
    }

    throw Exception(
      'Failed to update lead.',
    );
  }

  // ============================================================
  // PATCH LEAD - UPDATE ONE OR MORE FIELDS
  // ============================================================

  Future<LeadModel> patchLead({
    required String leadId,
    required Map<String, dynamic> changes,
  }) async {
    if (changes.isEmpty) {
      return getLeadDetail(leadId);
    }

    final response = await _apiClient.patch(
      ApiEndpoints.patchLead(
        AppConstants.businessId,
        leadId,
      ),
      data: changes,
    );

    final responseData = response.data;

    if (responseData is Map<String, dynamic>) {
      final dataValue = responseData['data'];

      if (dataValue is Map<String, dynamic>) {
        return LeadModel.fromJson(
          dataValue,
        );
      }

      if (responseData['id'] != null) {
        return LeadModel.fromJson(
          responseData,
        );
      }
    }

    return getLeadDetail(leadId);
  }

  // ============================================================
  // UPDATE STATUS - PATCH
  // ============================================================

  Future<LeadModel> updateLeadStatus({
    required String leadId,
    required String statusId,
  }) async {
    final response = await _apiClient.patch(
      ApiEndpoints.updateLeadStatus(
        AppConstants.businessId,
        leadId,
      ),
      data: {
        'status_id': statusId,
      },
    );

    final responseData = response.data;

    if (responseData is Map<String, dynamic>) {
      final dataValue = responseData['data'];

      if (dataValue is Map<String, dynamic>) {
        return LeadModel.fromJson(
          dataValue,
        );
      }

      if (responseData['id'] != null) {
        return LeadModel.fromJson(
          responseData,
        );
      }
    }

    return getLeadDetail(leadId);
  }

  // ============================================================
  // TOGGLE STAR - PATCH
  // ============================================================

  Future<LeadModel> toggleLeadStar({
    required String leadId,
  }) async {
    final response = await _apiClient.patch(
      ApiEndpoints.toggleLeadStar(
        AppConstants.businessId,
        leadId,
      ),
    );

    final responseData = response.data;

    if (responseData is Map<String, dynamic>) {
      final dataValue = responseData['data'];

      if (dataValue is Map<String, dynamic>) {
        return LeadModel.fromJson(
          dataValue,
        );
      }

      if (responseData['id'] != null) {
        return LeadModel.fromJson(
          responseData,
        );
      }
    }

    return getLeadDetail(leadId);
  }

  // ============================================================
  // DELETE LEAD
  // ============================================================

  Future<void> deleteLead({
    required String leadId,
  }) async {
    await _apiClient.delete(
      ApiEndpoints.deleteLead(
        AppConstants.businessId,
        leadId,
      ),
    );
  }
}