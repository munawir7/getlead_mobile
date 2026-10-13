
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'deal_detail_screen.dart';
import 'create_edit_deal_screen.dart';
import 'deal_list_controller.dart';
import 'deal_model.dart';
import 'deals_repository.dart';

class DealListScreen extends ConsumerStatefulWidget {
  const DealListScreen({super.key});

  @override
  ConsumerState<DealListScreen> createState() =>
      _DealListScreenState();
}

class _DealListScreenState extends ConsumerState<DealListScreen> {
  final TextEditingController _searchController =
      TextEditingController();

  static const Color _backgroundColor = Color(0xFFFFF8F0);
  static const Color _primaryColor = Color(0xFFB93832);
  static const Color _textColor = Color(0xFF292524);
  static const Color _secondaryTextColor = Color(0xFF78716C);

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ============================================================
  // REFRESH DEALS
  // ============================================================

  Future<void> _refreshDeals() async {
    await ref
        .read(dealListControllerProvider.notifier)
        .refreshDeals();
  }

  // ============================================================
  // SEARCH DEALS
  // ============================================================

  Future<void> _searchDeals(String query) async {
    await ref
        .read(dealListControllerProvider.notifier)
        .searchDeals(query);
  }

  // ============================================================
  // SHOW MESSAGE
  // ============================================================

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  // ============================================================
  // LOAD AND DEBUG DEAL METADATA
  // ============================================================

  Future<void> _debugDealMetadata() async {
    try {
      debugPrint('');
      debugPrint('========== DEAL META DEBUG ==========');

      final meta = await ref
          .read(dealsRepositoryProvider)
          .getDealMeta();

      debugPrint('FULL DEAL META: $meta');
      debugPrint('CUSTOM FIELDS: ${meta['custom_fields']}');

      final customFields = meta['custom_fields'];

      if (customFields is List) {
        for (final field in customFields) {
          debugPrint('CUSTOM FIELD ITEM: $field');
        }
      } else {
        debugPrint(
          'No custom_fields list found at the metadata root.',
        );
      }

      debugPrint('=====================================');
      debugPrint('');
    } catch (error, stackTrace) {
      debugPrint('Failed to load deal metadata: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  // ============================================================
  // OPEN CREATE / EDIT DEAL FORM
  // ============================================================

  Future<void> _openDealForm({DealModel? deal}) async {
    // Keep metadata debugging when opening the form.
    await _debugDealMetadata();

    if (!mounted) return;

    // No deal supplied = create mode.
    // A deal supplied = edit mode.
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => CreateEditDealScreen(
          deal: deal,
        ),
      ),
    );

    if (!mounted) return;

    // The form should return true after a successful save.
    if (result == true) {
      await _refreshDeals();

      if (!mounted) return;

      _showMessage(
        deal == null
            ? 'Deal created successfully.'
            : 'Deal updated successfully.',
      );
    }
  }

  // ============================================================
  // DELETE CONFIRMATION
  // ============================================================

  Future<void> _confirmDelete(DealModel deal) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: const Text('Delete Deal'),
          content: Text(
            'Are you sure you want to delete "${deal.name}"?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text(
                'Cancel',
                style: TextStyle(
                  color: _secondaryTextColor,
                ),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryColor,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) return;

    try {
      await ref
          .read(dealListControllerProvider.notifier)
          .deleteDeal(deal.id);

      if (!mounted) return;

      _showMessage('Deal deleted successfully.');
    } catch (error) {
      if (!mounted) return;

      _showMessage('Unable to delete deal: $error');
    }
  }

  // ============================================================
  // DEAL CARD
  // ============================================================

  Widget _buildDealCard(DealModel deal) {
    return Card(
      color: Colors.white,
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(
          color: Color(0xFFF0E7DE),
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () async {
          final updated = await Navigator.of(context).push<bool>(
            MaterialPageRoute(
              builder: (_) => DealDetailScreen(deal: deal),
            ),
          );

          if (!mounted) return;

          if (updated == true) {
            await _refreshDeals();
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      deal.name.isEmpty
                          ? 'Untitled Deal'
                          : deal.name,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: _textColor,
                      ),
                    ),
                  ),
                  PopupMenuButton<String>(
                    icon: const Icon(
                      Icons.more_vert,
                      color: _secondaryTextColor,
                    ),
                    onSelected: (value) {
                      if (value == 'edit') {
                        _openDealForm(deal: deal);
                      } else if (value == 'delete') {
                        _confirmDelete(deal);
                      }
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem<String>(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(
                              Icons.edit_outlined,
                              size: 20,
                            ),
                            SizedBox(width: 10),
                            Text('Edit'),
                          ],
                        ),
                      ),
                      PopupMenuItem<String>(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(
                              Icons.delete_outline,
                              color: _primaryColor,
                              size: 20,
                            ),
                            SizedBox(width: 10),
                            Text('Delete'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 8),

              Text(
                '${deal.currency} '
                '${deal.amount.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: _primaryColor,
                ),
              ),

              if (deal.dealNumber != null &&
                  deal.dealNumber!.isNotEmpty) ...[
                const SizedBox(height: 8),
                _buildInfoRow(
                  Icons.confirmation_number_outlined,
                  'Deal number',
                  deal.dealNumber!,
                ),
              ],

              if (deal.leadName != null &&
                  deal.leadName!.isNotEmpty) ...[
                const SizedBox(height: 6),
                _buildInfoRow(
                  Icons.person_outline,
                  'Lead',
                  deal.leadName!,
                ),
              ],

              if (deal.dealTypeName != null &&
                  deal.dealTypeName!.isNotEmpty) ...[
                const SizedBox(height: 6),
                _buildInfoRow(
                  Icons.category_outlined,
                  'Type',
                  deal.dealTypeName!,
                ),
              ],

              if (deal.dealStatusName != null &&
                  deal.dealStatusName!.isNotEmpty) ...[
                const SizedBox(height: 6),
                _buildInfoRow(
                  Icons.flag_outlined,
                  'Status',
                  deal.dealStatusName!,
                ),
              ],

              if (deal.expectedCloseDate != null &&
                  deal.expectedCloseDate!.isNotEmpty) ...[
                const SizedBox(height: 6),
                _buildInfoRow(
                  Icons.calendar_today_outlined,
                  'Expected close',
                  deal.expectedCloseDate!,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // INFORMATION ROW
  // ============================================================

  Widget _buildInfoRow(
    IconData icon,
    String label,
    String value,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 18,
          color: _secondaryTextColor,
        ),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: const TextStyle(
            fontSize: 13,
            color: _secondaryTextColor,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              color: _textColor,
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // LOADING STATE
  // ============================================================

  Widget _buildLoading() {
    return const Center(
      child: CircularProgressIndicator(
        color: _primaryColor,
      ),
    );
  }

  // ============================================================
  // ERROR STATE
  // ============================================================

  Widget _buildError(Object error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              size: 48,
              color: _primaryColor,
            ),
            const SizedBox(height: 12),
            const Text(
              'Unable to load deals',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: _textColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _secondaryTextColor,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _refreshDeals,
              icon: const Icon(Icons.refresh),
              label: const Text('Try again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryColor,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // EMPTY STATE
  // ============================================================

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.handshake_outlined,
              size: 64,
              color: _secondaryTextColor,
            ),
            const SizedBox(height: 16),
            const Text(
              'No deals found',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: _textColor,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Try another search or refresh the list.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _secondaryTextColor,
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _refreshDeals,
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh'),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final dealsAsync = ref.watch(dealListControllerProvider);

    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        backgroundColor: _backgroundColor,
        foregroundColor: _textColor,
        elevation: 0,
        title: const Text(
          'Deals',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh deals',
            onPressed: _refreshDeals,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: TextField(
              controller: _searchController,
              onChanged: _searchDeals,
              decoration: InputDecoration(
                hintText: 'Search deals...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Clear search',
                        onPressed: () {
                          _searchController.clear();
                          _searchDeals('');
                          setState(() {});
                        },
                        icon: const Icon(Icons.clear),
                      ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(
                    color: Color(0xFFE7DDD3),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(
                    color: Color(0xFFE7DDD3),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(
                    color: _primaryColor,
                    width: 1.5,
                  ),
                ),
              ),
            ),
          ),

          Expanded(
            child: dealsAsync.when(
              loading: _buildLoading,
              error: (error, stackTrace) => _buildError(error),
              data: (deals) {
                if (deals.isEmpty) {
                  return RefreshIndicator(
                    color: _primaryColor,
                    onRefresh: _refreshDeals,
                    child: ListView(
                      physics:
                          const AlwaysScrollableScrollPhysics(),
                      children: [
                        SizedBox(
                          height:
                              MediaQuery.of(context).size.height *
                                  0.45,
                          child: _buildEmptyState(),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  color: _primaryColor,
                  onRefresh: _refreshDeals,
                  child: ListView.builder(
                    physics:
                        const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(
                      16,
                      0,
                      16,
                      100,
                    ),
                    itemCount: deals.length,
                    itemBuilder: (context, index) {
                      return _buildDealCard(deals[index]);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),

      // ========================================================
      // ADD DEAL BUTTON
      // ========================================================

      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
        onPressed: () => _openDealForm(),
        icon: const Icon(Icons.add),
        label: const Text('Add Deal'),
      ),
    );
  }
}
