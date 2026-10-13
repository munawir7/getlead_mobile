import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:getlead_mobile/features/auth/auth_controller.dart';

import '../../api/api_client.dart';
import '../../api/endpoints.dart';
import '../../core/constants.dart';
import 'deal_model.dart';

final dealsRepositoryProvider = Provider<DealsRepository>((ref) {
  return DealsRepository(
    apiClient: ref.read(apiClientProvider),
  );
});

class DealsPage {
  const DealsPage({
    required this.deals,
    required this.nextCursor,
    this.total,
  });

  final List<DealModel> deals;
  final String? nextCursor;
  final int? total;
}

class DealsRepository {
  DealsRepository({
    required ApiClient apiClient,
  }) : _apiClient = apiClient;

  final ApiClient _apiClient;

  // ============================================================
  // ERROR LOGGING
  // ============================================================

  void _logApiError(
    String operation,
    DioException error,
  ) {
    debugPrint('');
    debugPrint('========== $operation FAILED ==========');
    debugPrint('Status code: ${error.response?.statusCode}');
    debugPrint('Request method: ${error.requestOptions.method}');
    debugPrint('Request URL: ${error.requestOptions.uri}');
    debugPrint('Request data: ${error.requestOptions.data}');
    debugPrint('Response body: ${error.response?.data}');
    debugPrint('Dio error: ${error.message}');
    debugPrint('========================================');
    debugPrint('');
  }

  // ============================================================
  // GET ALL DEALS
  // ============================================================

  Future<DealsPage> getDeals({
    String? cursor,
    String? search,
  }) async {
    final queryParameters = <String, dynamic>{
      'per_page': AppConstants.pageSize,
    };

    if (cursor != null && cursor.trim().isNotEmpty) {
      queryParameters['cursor'] = cursor.trim();
    }

    if (search != null && search.trim().isNotEmpty) {
      queryParameters['search'] = search.trim();
    }

    try {
      final response = await _apiClient.get(
        ApiEndpoints.deals(AppConstants.businessId),
        queryParameters: queryParameters,
      );

      final responseData = response.data;

      if (responseData is! Map) {
        throw Exception('Invalid deals response from server.');
      }

      final rawData = responseData['data'];

      if (rawData is! List) {
        throw Exception('Invalid deals data returned by the server.');
      }

      final deals = rawData
          .whereType<Map>()
          .map(
            (item) => DealModel.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .toList();

      String? nextCursor;
      int? total;

      final meta = responseData['meta'];

      if (meta is Map) {
        final cursorValue = meta['next_cursor'];

        if (cursorValue != null &&
            cursorValue.toString().trim().isNotEmpty) {
          nextCursor = cursorValue.toString();
        }

        final totalValue =
            meta['total'] ?? meta['total_deals'] ?? meta['count'];

        if (totalValue != null) {
          total = int.tryParse(totalValue.toString());
        }
      }

      total ??= int.tryParse(
        (responseData['total'] ?? '').toString(),
      );

      return DealsPage(
        deals: deals,
        nextCursor: nextCursor,
        total: total,
      );
    } on DioException catch (error) {
      _logApiError('GET DEALS', error);
      rethrow;
    }
  }

  // ============================================================
// GET DEAL DETAILS
// ============================================================

Future<DealModel> getDealDetail(String dealId) async {
  try {
    final endpoint = ApiEndpoints.dealDetail(
      AppConstants.businessId,
      dealId,
    );

    debugPrint('');
    debugPrint('========== GET DEAL DETAIL REQUEST ==========');
    debugPrint('Business ID: ${AppConstants.businessId}');
    debugPrint('Deal ID: $dealId');
    debugPrint('Endpoint: $endpoint');

    final response = await _apiClient.get(endpoint);

    // Print the complete response for debugging.
    debugPrint('Response status: ${response.statusCode}');
    debugPrint('========== EXISTING DEAL DATA ==========');
    debugPrint('Deal response: ${response.data}');
    debugPrint('========================================');
    debugPrint('========== RAW DEAL DETAIL RESPONSE ==========');
    debugPrint('${response.data}');
    debugPrint('==============================================');

    final responseData = response.data;

    if (responseData is Map) {
      final data = responseData['data'];

      if (data is Map) {
        final dealJson = Map<String, dynamic>.from(data);

        // Print the existing custom fields.
        debugPrint('========== DEAL CUSTOM FIELDS ==========');
        debugPrint('Custom fields: ${dealJson['custom_fields']}');
        debugPrint('========================================');

        return DealModel.fromJson(dealJson);
      }

      if (responseData['id'] != null) {
        final dealJson = Map<String, dynamic>.from(responseData);

        debugPrint('========== DEAL CUSTOM FIELDS ==========');
        debugPrint('Custom fields: ${dealJson['custom_fields']}');
        debugPrint('========================================');

        return DealModel.fromJson(dealJson);
      }
    }

    throw Exception('Invalid deal detail response from server.');
  } on DioException catch (error) {
    _logApiError('GET DEAL DETAIL', error);
    rethrow;
  }
}
  
  // ============================================================
  // GET DEAL METADATA
  // ============================================================

  Future<Map<String, dynamic>> getDealMeta() async {
    final endpoint = ApiEndpoints.dealMeta(
      AppConstants.businessId,
    );

    try {
      debugPrint('========== DEAL METADATA REQUEST ==========');
      debugPrint('Business ID: ${AppConstants.businessId}');
      debugPrint('Endpoint: $endpoint');

      final response = await _apiClient.get(endpoint);

      debugPrint('Response status: ${response.statusCode}');
      debugPrint('Response data: ${response.data}');
      debugPrint('============================================');

      final responseData = response.data;

      if (responseData is! Map) {
        throw Exception('Invalid deal metadata response.');
      }

      final data = responseData['data'];

      if (data is Map) {
        return Map<String, dynamic>.from(data);
      }

      return Map<String, dynamic>.from(responseData);
    } on DioException catch (error) {
      _logApiError('GET DEAL METADATA', error);
      rethrow;
    } catch (error) {
      debugPrint('Deal metadata error: $error');
      rethrow;
    }
  }

  // ============================================================
  // CREATE DEAL - POST
  // ============================================================

 Future<DealModel> createDeal({
  required String name,
  required int amount,
  required String leadId,
  required String branchId,
  required String dealTypeId,
  required String dealStatusId,
  required String assignedToId,
  String? expectedCloseDate,
  String? notes,
  Map<String, dynamic>? customFields,
}) async {
    final data = <String, dynamic>{
      'name': name.trim(),
      'amount': amount,
      'lead_id': leadId.trim(),
      'branch_id': branchId.trim(),
      'deal_type_id': dealTypeId.trim(),
      'deal_status_id': dealStatusId.trim(),
      'assigned_to_id': assignedToId.trim(),
    };

    if (expectedCloseDate != null &&
        expectedCloseDate.trim().isNotEmpty) {
      data['expected_close_date'] = expectedCloseDate.trim();
    }

    if (notes != null && notes.trim().isNotEmpty) {
      data['notes'] = notes.trim();
    }
    if (customFields != null && customFields.isNotEmpty) {
  data['custom_fields'] = customFields;
    }

    try {
      debugPrint('========== CREATE DEAL REQUEST ==========');
      debugPrint('Endpoint: ${ApiEndpoints.deals(AppConstants.businessId)}');
      debugPrint('Request data: $data');

      final response = await _apiClient.post(
        ApiEndpoints.deals(AppConstants.businessId),
        data: data,
      );

      debugPrint('Create response status: ${response.statusCode}');
      debugPrint('Create response data: ${response.data}');
      debugPrint('=========================================');

      final responseData = response.data;

      if (responseData is Map) {
        final dealData = responseData['data'];

        if (dealData is Map && dealData['id'] != null) {
          return getDealDetail(dealData['id'].toString());
        }

        if (responseData['id'] != null) {
          return getDealDetail(responseData['id'].toString());
        }
      }

      throw Exception(
        'The deal was submitted, but the server did not return its ID. '
        'Check the API response before retrying.',
      );
    } on DioException catch (error) {
  debugPrint('========== EDIT DEAL ERROR ==========');
  debugPrint('Status code: ${error.response?.statusCode}');
  debugPrint('Response data: ${error.response?.data}');
  debugPrint('Request data: ${error.requestOptions.data}');
  debugPrint('Request URL: ${error.requestOptions.uri}');
  debugPrint('=====================================');

  rethrow;
}
  }

  // ============================================================
  // EDIT DEAL - PUT
  // ============================================================

  Future<DealModel> editDeal({
  required String dealId,
  required String name,
  required int amount,
  required String branchId,
  required String dealTypeId,
  String? expectedCloseDate,
  String? notes,
  Map<String, dynamic> customFields = const {},
}) async {
  final data = <String, dynamic>{
    'name': name.trim(),
    'amount': amount,
    'branch_id': branchId.trim(),
    'deal_type_id': dealTypeId.trim(),
    'expected_close_date':
        expectedCloseDate == null ||
                expectedCloseDate.trim().isEmpty
            ? null
            : expectedCloseDate.trim(),
    'notes': notes == null || notes.trim().isEmpty
        ? null
        : notes.trim(),
  };

  // Preserve custom field values when provided.
  if (customFields.isNotEmpty) {
    data['custom_fields'] = customFields;
  }

  final endpoint = ApiEndpoints.updateDeal(
    AppConstants.businessId,
    dealId,
  );

  try {
    debugPrint('========== EDIT DEAL REQUEST ==========');
    debugPrint('Business ID: ${AppConstants.businessId}');
    debugPrint('Deal ID: $dealId');
    debugPrint('Endpoint: $endpoint');
    debugPrint('Request data: $data');

    final response = await _apiClient.put(
      endpoint,
      data: data,
    );

    debugPrint('Edit response status: ${response.statusCode}');
    debugPrint('Edit response data: ${response.data}');
    debugPrint('=======================================');

    return await getDealDetail(dealId);
  } on DioException catch (error) {
    _logApiError('EDIT DEAL', error);
    rethrow;
  }
}
  // ============================================================
  // PATCH DEAL - PARTIAL UPDATE
  // ============================================================

  Future<DealModel> patchDeal({
    required String dealId,
    required Map<String, dynamic> changes,
  }) async {
    if (changes.isEmpty) {
      return getDealDetail(dealId);
    }

    final endpoint = ApiEndpoints.patchDeal(
      AppConstants.businessId,
      dealId,
    );

    try {
      debugPrint('========== PATCH DEAL REQUEST ==========');
      debugPrint('Deal ID: $dealId');
      debugPrint('Endpoint: $endpoint');
      debugPrint('Request data: $changes');

      final response = await _apiClient.patch(
        endpoint,
        data: changes,
      );

      debugPrint('Patch response status: ${response.statusCode}');
      debugPrint('Patch response data: ${response.data}');
      debugPrint('========================================');

      return getDealDetail(dealId);
    } on DioException catch (error) {
      _logApiError('PATCH DEAL', error);
      rethrow;
    }
  }

  // ============================================================
  // DELETE DEAL
  // ============================================================

  Future<void> deleteDeal({
    required String dealId,
  }) async {
    final endpoint = ApiEndpoints.deleteDeal(
      AppConstants.businessId,
      dealId,
    );

    try {
      debugPrint('========== DELETE DEAL REQUEST ==========');
      debugPrint('Deal ID: $dealId');
      debugPrint('Endpoint: $endpoint');

      final response = await _apiClient.delete(endpoint);

      debugPrint('Delete response status: ${response.statusCode}');
      debugPrint('Delete response data: ${response.data}');
      debugPrint('=========================================');
    } on DioException catch (error) {
      _logApiError('DELETE DEAL', error);
      rethrow;
    }
  }
}