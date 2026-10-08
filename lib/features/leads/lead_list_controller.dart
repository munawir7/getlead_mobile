import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'lead_model.dart';
import 'leads_repository.dart';

final leadListControllerProvider =
    AsyncNotifierProvider<LeadListController, List<LeadModel>>(
  LeadListController.new,
);

class LeadListController extends AsyncNotifier<List<LeadModel>> {
  String? _nextCursor;

  bool _isLoadingMore = false;
  bool _isCreating = false;
  bool _isUpdating = false;
  bool _isDeleting = false;

  int? _totalCount;

  @override
  Future<List<LeadModel>> build() async {
    final result = await ref
        .read(leadsRepositoryProvider)
        .getLeads();

    _nextCursor = result.nextCursor;
    _totalCount = result.total;

    return result.leads;
  }

  // ------------------------------------------------------------
  // REFRESH LEADS
  // ------------------------------------------------------------

  Future<void> refreshLeads() async {
    _nextCursor = null;

    state = const AsyncLoading();

    try {
      final result = await ref
          .read(leadsRepositoryProvider)
          .getLeads();

      _nextCursor = result.nextCursor;
      _totalCount = result.total;

      state = AsyncData(result.leads);
    } catch (e, stackTrace) {
      state = AsyncError(e, stackTrace);
    }
  }

  // ------------------------------------------------------------
  // LOAD MORE
  // ------------------------------------------------------------

  Future<void> loadMore() async {
    if (_isLoadingMore) return;

    if (_nextCursor == null || _nextCursor!.isEmpty) {
      return;
    }

    final currentLeads = state.value;

    if (currentLeads == null) {
      return;
    }

    _isLoadingMore = true;

    try {
      final result = await ref
          .read(leadsRepositoryProvider)
          .getLeads(
            cursor: _nextCursor,
          );

      _nextCursor = result.nextCursor;

      final updatedLeads = <LeadModel>[
        ...currentLeads,
        ...result.leads,
      ];

      state = AsyncData(updatedLeads);
    } catch (e) {
      state = AsyncData(currentLeads);
      rethrow;
    } finally {
      _isLoadingMore = false;
    }
  }

  // ------------------------------------------------------------
  // CREATE LEAD
  // ------------------------------------------------------------

  Future<void> createLead({
    required String name,
    required String phoneNumber,
    String? email,
    required String sourceId,
    String? statusId,
    String? notes,
  }) async {
    if (_isCreating) return;

    _isCreating = true;

    try {
      final newLead = await ref
          .read(leadsRepositoryProvider)
          .createLead(
            name: name,
            phoneNumber: phoneNumber,
            email: email,
            sourceId: sourceId,
            statusId: statusId,
            notes: notes,
          );

      final currentLeads = state.value ?? [];

      // Add newly created lead at the top.
      state = AsyncData([
        newLead,
        ...currentLeads,
      ]);

      if (_totalCount != null) {
        _totalCount = _totalCount! + 1;
      }
    } finally {
      _isCreating = false;
    }
  }

  // ------------------------------------------------------------
  // EDIT LEAD
  // ------------------------------------------------------------

  Future<LeadModel> editLead({
    required String leadId,
    required String name,
    required String phoneNumber,
    String? email,
    required String sourceId,
    String? statusId,
    String? notes,
  }) async {
    if (_isUpdating) {
      throw StateError(
        'An update is already in progress.',
      );
    }

    _isUpdating = true;

    try {
      final updatedLead = await ref
          .read(leadsRepositoryProvider)
          .editLead(
            leadId: leadId,
            name: name,
            phoneNumber: phoneNumber,
            email: email,
            sourceId: sourceId,
            statusId: statusId,
            notes: notes,
          );

      // Update the lead inside the in-memory list.
      _replaceLead(updatedLead);

      // IMPORTANT:
      // Return the updated LeadModel to the edit screen.
      return updatedLead;
    } finally {
      _isUpdating = false;
    }
  }

  // ------------------------------------------------------------
  // PATCH LEAD
  // ------------------------------------------------------------

  Future<void> patchLead({
    required String leadId,
    required Map<String, dynamic> changes,
  }) async {
    if (_isUpdating) return;

    _isUpdating = true;

    try {
      final updatedLead = await ref
          .read(leadsRepositoryProvider)
          .patchLead(
            leadId: leadId,
            changes: changes,
          );

      _replaceLead(updatedLead);
    } finally {
      _isUpdating = false;
    }
  }

  // ------------------------------------------------------------
  // UPDATE STATUS
  // ------------------------------------------------------------

  Future<void> updateLeadStatus({
    required String leadId,
    required String statusId,
  }) async {
    if (_isUpdating) return;

    _isUpdating = true;

    try {
      final updatedLead = await ref
          .read(leadsRepositoryProvider)
          .updateLeadStatus(
            leadId: leadId,
            statusId: statusId,
          );

      _replaceLead(updatedLead);
    } finally {
      _isUpdating = false;
    }
  }

  // ------------------------------------------------------------
  // TOGGLE STAR
  // ------------------------------------------------------------

  Future<void> toggleLeadStar({
    required String leadId,
  }) async {
    if (_isUpdating) return;

    _isUpdating = true;

    try {
      final updatedLead = await ref
          .read(leadsRepositoryProvider)
          .toggleLeadStar(
            leadId: leadId,
          );

      _replaceLead(updatedLead);
    } finally {
      _isUpdating = false;
    }
  }

  // ------------------------------------------------------------
  // DELETE LEAD
  // ------------------------------------------------------------

  Future<void> deleteLead({
    required String leadId,
  }) async {
    if (_isDeleting) return;

    _isDeleting = true;

    try {
      await ref
          .read(leadsRepositoryProvider)
          .deleteLead(
            leadId: leadId,
          );

      final currentLeads = state.value ?? [];

      final updatedLeads = currentLeads
          .where(
            (lead) => lead.id != leadId,
          )
          .toList();

      state = AsyncData(updatedLeads);

      if (_totalCount != null && _totalCount! > 0) {
        _totalCount = _totalCount! - 1;
      }
    } finally {
      _isDeleting = false;
    }
  }

  // ------------------------------------------------------------
  // REPLACE LEAD IN MEMORY
  // ------------------------------------------------------------

  void _replaceLead(LeadModel updatedLead) {
    final currentLeads = state.value ?? [];

    final index = currentLeads.indexWhere(
      (lead) => lead.id == updatedLead.id,
    );

    if (index == -1) {
      return;
    }

    final updatedLeads = [...currentLeads];

    updatedLeads[index] = updatedLead;

    state = AsyncData(updatedLeads);
  }

  // ------------------------------------------------------------
  // GETTERS
  // ------------------------------------------------------------

  bool get hasMore {
    return _nextCursor != null &&
        _nextCursor!.isNotEmpty;
  }

  bool get isLoadingMore => _isLoadingMore;

  bool get isCreating => _isCreating;

  bool get isUpdating => _isUpdating;

  bool get isDeleting => _isDeleting;

  int? get totalCount => _totalCount;
}