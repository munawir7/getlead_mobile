import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'create_edit_deal_screen.dart';
import 'deal_list_controller.dart';
import 'deal_model.dart';
import 'deals_repository.dart';

class DealDetailScreen extends ConsumerStatefulWidget {
  final DealModel deal;

  const DealDetailScreen({
    super.key,
    required this.deal,
  });

  @override
  ConsumerState<DealDetailScreen> createState() =>
      _DealDetailScreenState();
}

class _DealDetailScreenState extends ConsumerState<DealDetailScreen> {
  late DealModel _deal;

  bool _isLoading = true;
  String? _errorMessage;

  static const Color _backgroundColor = Color(0xFFFFF8F0);
  static const Color _primaryColor = Color(0xFFB93832);
  static const Color _textColor = Color(0xFF292524);
  static const Color _secondaryTextColor = Color(0xFF78716C);

  @override
  void initState() {
    super.initState();
    _deal = widget.deal;
    _loadDealDetails();
  }

  // ============================================================
  // LOAD DEAL DETAILS
  // ============================================================

  Future<void> _loadDealDetails() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final deal = await ref
          .read(dealsRepositoryProvider)
          .getDealDetail(widget.deal.id);

      if (!mounted) return;

      setState(() {
        _deal = deal;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _errorMessage = error.toString();
        _isLoading = false;
      });
    }
  }

  // ============================================================
  // EDIT DEAL
  // ============================================================

 Future<void> _editDeal() async {
  final updated = await Navigator.of(context).push<bool>(
    MaterialPageRoute(
      builder: (_) => CreateEditDealScreen(
        deal: _deal,
      ),
    ),
  );

  if (!mounted) return;

  if (updated == true) {
    // Reload the updated deal details.
    await _loadDealDetails();

    if (!mounted) return;

    // Refresh the deals list.
    await ref
        .read(dealListControllerProvider.notifier)
        .refreshDeals();

    if (!mounted) return;

    // Return to the deals list and notify it to refresh.
    Navigator.of(context).pop(true);
  }
}
  // ============================================================
  // DISPLAY INFORMATION ROW
  // ============================================================

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    if (value.trim().isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 38,
            width: 38,
            decoration: BoxDecoration(
              color: _primaryColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              size: 20,
              color: _primaryColor,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: _secondaryTextColor,
                  ),
                ),
                const SizedBox(height: 4),
                SelectableText(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: _textColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SECTION CARD
  // ============================================================

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFF0E7DE),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: _primaryColor,
                size: 22,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: _textColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 8),
          ...children,
        ],
      ),
    );
  }

  // ============================================================
  // CUSTOM FIELDS
  // ============================================================

  Widget _buildCustomFields() {
    final fields = _deal.customFields;

   if (fields.isEmpty)  {
      return _buildSection(
        title: 'Custom Fields',
        icon: Icons.tune,
        children: const [
          Text(
            'No custom field values are available for this deal.',
            style: TextStyle(
              fontSize: 14,
              color: _secondaryTextColor,
            ),
          ),
        ],
      );
    }

    final widgets = <Widget>[];

    fields.forEach((key, value) {
      String displayValue;

      if (value == null || value.toString().trim().isEmpty) {
        displayValue = 'Not provided';
      } else if (value is List) {
        displayValue = value.join(', ');
      } else if (value is Map) {
        displayValue = value.values.join(', ');
      } else {
        displayValue = value.toString();
      }

      widgets.add(
        _buildInfoRow(
          icon: Icons.label_outline,
          label: _formatFieldName(key),
          value: displayValue,
        ),
      );
    });

    return _buildSection(
      title: 'Custom Fields',
      icon: Icons.tune,
      children: widgets,
    );
  }

  String _formatFieldName(String key) {
    final spaced = key.replaceAllMapped(
      RegExp(r'([a-z])([A-Z])'),
      (match) => '${match[1]} ${match[2]}',
    );

    if (spaced.isEmpty) return spaced;

    return spaced[0].toUpperCase() + spaced.substring(1);
  }

  // ============================================================
  // LOADING
  // ============================================================

  Widget _buildLoading() {
    return const Center(
      child: CircularProgressIndicator(
        color: _primaryColor,
      ),
    );
  }

  // ============================================================
  // ERROR
  // ============================================================

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              color: _primaryColor,
              size: 52,
            ),
            const SizedBox(height: 12),
            const Text(
              'Unable to load deal details',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: _textColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'Something went wrong.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _secondaryTextColor,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadDealDetails,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
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
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        backgroundColor: _backgroundColor,
        foregroundColor: _textColor,
        elevation: 0,
        title: const Text(
          'Deal Details',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh details',
            onPressed: _loadDealDetails,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _isLoading
          ? _buildLoading()
          : _errorMessage != null
              ? _buildError()
              : RefreshIndicator(
                  color: _primaryColor,
                  onRefresh: _loadDealDetails,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    children: [
                      // Deal summary.
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: _primaryColor,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.handshake_outlined,
                              size: 32,
                              color: Colors.white,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _deal.name.isEmpty
                                  ? 'Untitled Deal'
                                  : _deal.name,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              '${_deal.currency} '
                              '${_deal.amount.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            if (_deal.dealNumber != null &&
                                _deal.dealNumber!.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(
                                'Deal number: ${_deal.dealNumber}',
                                style: const TextStyle(
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // General information.
                      _buildSection(
                        title: 'Deal Information',
                        icon: Icons.info_outline,
                        children: [
                          _buildInfoRow(
                            icon: Icons.category_outlined,
                            label: 'Deal Type',
                            value: _deal.dealTypeName ?? '',
                          ),
                          _buildInfoRow(
                            icon: Icons.flag_outlined,
                            label: 'Deal Status',
                            value: _deal.dealStatusName ?? '',
                          ),
                          _buildInfoRow(
                            icon: Icons.person_outline,
                            label: 'Lead',
                            value: _deal.leadName ?? '',
                          ),
                          _buildInfoRow(
                            icon: Icons.account_tree_outlined,
                            label: 'Branch',
                            value: _deal.branchName ??
                                _deal.branchId ??
                                '',
                          ),
                          _buildInfoRow(
                            icon: Icons.calendar_month_outlined,
                            label: 'Expected Close Date',
                            value: _deal.expectedCloseDate ?? '',
                          ),
                          _buildInfoRow(
                            icon: Icons.notes_outlined,
                            label: 'Notes',
                            value: _deal.notes ?? '',
                          ),
                          _buildInfoRow(
                            icon: Icons.person_pin_outlined,
                            label: 'Assigned To ID',
                            value: _deal.assignedToId ?? '',
                          ),
                        ],
                      ),

                      // Custom field values returned by the detail API.
                      _buildCustomFields(),

                      const SizedBox(height: 8),

                      SizedBox(
                        height: 52,
                        child: ElevatedButton.icon(
                          onPressed: _editDeal,
                          icon: const Icon(Icons.edit_outlined),
                          label: const Text(
                            'Edit Deal',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _primaryColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),
                    ],
                  ),
                ),
    );
  }
}