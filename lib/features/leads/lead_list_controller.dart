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

  Future<void> loadMore() async {
    if (_isLoadingMore) {
      return;
    }

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
    } catch (e, stackTrace) {
      state = AsyncError(e, stackTrace);
    } finally {
      _isLoadingMore = false;
    }
  }

  bool get hasMore {
    return _nextCursor != null && _nextCursor!.isNotEmpty;
  }

  bool get isLoadingMore {
    return _isLoadingMore;
  }

  int? get totalCount {
    return _totalCount;
  }
}