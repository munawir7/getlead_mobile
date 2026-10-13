
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'deal_model.dart';
import 'deals_repository.dart';

final dealListControllerProvider =
    AsyncNotifierProvider<DealListController, List<DealModel>>(
  DealListController.new,
);

class DealListController extends AsyncNotifier<List<DealModel>> {
  String _searchQuery = '';

  DealsRepository get _repository => ref.read(dealsRepositoryProvider);

  static const String _educationFieldId =
      '01KTE48YRAR6WY4PC9ACA58N13';

  // ============================================================
  // LOAD DEALS
  // ============================================================

  @override
  Future<List<DealModel>> build() async {
    final result = await _repository.getDeals();
    return result.deals;
  }

  // ============================================================
  // LOAD DEALS WITH OPTIONAL SEARCH
  // ============================================================

  Future<void> loadDeals({String? search}) async {
    if (search != null) {
      _searchQuery = search;
    }

    state = const AsyncLoading<List<DealModel>>();

    try {
      final result = await _repository.getDeals(
        search: _searchQuery.isEmpty ? null : _searchQuery,
      );

      state = AsyncData(result.deals);
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
    }
  }

  // ============================================================
  // REFRESH DEALS
  // ============================================================

  Future<void> refreshDeals() async {
    await loadDeals();
  }

  // ============================================================
  // SEARCH DEALS
  // ============================================================

  Future<void> searchDeals(String query) async {
    await loadDeals(search: query);
  }

  // ============================================================
  // CREATE DEAL
  // ============================================================

  Future<DealModel?> createDeal(
    Map<String, dynamic> values,
  ) async {
    final name = (values['name'] ?? '').toString().trim();

    final amount = _parseAmount(values['amount']);

    final leadId = (values['lead_id'] ?? '').toString().trim();

    final branchId = (values['branch_id'] ?? '').toString().trim();

    final dealTypeId =
        (values['deal_type_id'] ?? '').toString().trim();

    final dealStatusId =
        (values['deal_status_id'] ?? '').toString().trim();

    final assignedToId =
        (values['assigned_to_id'] ?? '').toString().trim();

    final customFields =
        values['custom_fields'] as Map<String, dynamic>? ?? {};

    // ----------------------------------------------------------
    // VALIDATE REQUIRED FIELDS
    // ----------------------------------------------------------

    if (name.isEmpty) {
      throw Exception('Deal name is required.');
    }

    if (amount < 0) {
      throw Exception('Enter a valid deal amount.');
    }

    if (leadId.isEmpty) {
      throw Exception('Lead ID is required.');
    }

    if (branchId.isEmpty) {
      throw Exception('Branch ID is required.');
    }

    if (dealTypeId.isEmpty) {
      throw Exception('Deal type is required.');
    }

    if (dealStatusId.isEmpty) {
      throw Exception('Deal status is required.');
    }

    if (assignedToId.isEmpty) {
      throw Exception('Assigned user ID is required.');
    }

    // ----------------------------------------------------------
    // VALIDATE EDUCATION CUSTOM FIELD
    // ----------------------------------------------------------

    final education =
        customFields[_educationFieldId]?.toString().trim() ?? '';

    if (education.isEmpty) {
      throw Exception('Education is required.');
    }

    // ----------------------------------------------------------
    // CALL CREATE DEAL API
    // ----------------------------------------------------------

    final deal = await _repository.createDeal(
      name: name,
      amount: amount,
      leadId: leadId,
      branchId: branchId,
      dealTypeId: dealTypeId,
      dealStatusId: dealStatusId,
      assignedToId: assignedToId,
      expectedCloseDate:
          _optionalString(values['expected_close_date']),
      notes: _optionalString(values['notes']),
      customFields: customFields,
    );

    // Refresh the deal list after successful creation.
    await loadDeals();

    return deal;
  }

  // ============================================================
  // EDIT DEAL
  // ============================================================

  Future<DealModel?> editDeal(
    String dealId,
    Map<String, dynamic> values,
  ) async {
    final name = (values['name'] ?? '').toString().trim();

    final amount = _parseAmount(values['amount']);

    final branchId = (values['branch_id'] ?? '').toString().trim();

    final dealTypeId =
        (values['deal_type_id'] ?? '').toString().trim();

    final customFields =
        values['custom_fields'] as Map<String, dynamic>? ?? {};

    // ----------------------------------------------------------
    // VALIDATE REQUIRED FIELDS
    // ----------------------------------------------------------

    if (name.isEmpty) {
      throw Exception('Deal name is required.');
    }

    if (amount < 0) {
      throw Exception('Enter a valid deal amount.');
    }

    if (branchId.isEmpty) {
      throw Exception('Branch ID is required.');
    }

    if (dealTypeId.isEmpty) {
      throw Exception('Deal type is required.');
    }

    // ----------------------------------------------------------
    // VALIDATE EDUCATION
    // ----------------------------------------------------------

    final education =
        customFields[_educationFieldId]?.toString().trim() ?? '';

    if (education.isEmpty) {
      throw Exception('Education is required.');
    }

    // ----------------------------------------------------------
    // CALL EDIT DEAL API
    // ----------------------------------------------------------

    final deal = await _repository.editDeal(
      dealId: dealId,
      name: name,
      amount: amount,
      branchId: branchId,
      dealTypeId: dealTypeId,
      expectedCloseDate:
          _optionalString(values['expected_close_date']),
      notes: _optionalString(values['notes']),
      customFields: customFields,
    );

    // Refresh the deal list after successful editing.
    await loadDeals();

    return deal;
  }

  // ============================================================
  // DELETE DEAL
  // ============================================================

  Future<void> deleteDeal(String dealId) async {
    await _repository.deleteDeal(dealId: dealId);

    await loadDeals();
  }

  // ============================================================
  // PARSE AMOUNT
  // ============================================================

  int _parseAmount(dynamic value) {
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(value?.toString().trim() ?? '') ?? -1;
  }

  // ============================================================
  // HANDLE OPTIONAL STRINGS
  // ============================================================

  String? _optionalString(dynamic value) {
    if (value == null) {
      return null;
    }

    final result = value.toString().trim();

    return result.isEmpty ? null : result;
  }
}

