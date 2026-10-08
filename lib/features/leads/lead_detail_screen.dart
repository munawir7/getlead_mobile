import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'create_lead_screen.dart';
import 'lead_list_controller.dart';
import 'lead_model.dart';
import 'leads_repository.dart';

class LeadDetailScreen extends ConsumerStatefulWidget {
  final String leadId;

  const LeadDetailScreen({
    super.key,
    required this.leadId,
  });

  @override
  ConsumerState<LeadDetailScreen> createState() =>
      _LeadDetailScreenState();
}

class _LeadDetailScreenState
    extends ConsumerState<LeadDetailScreen> {
  LeadModel? _lead;

  bool _isLoading = true;
  bool _isDeleting = false;

  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadLead();
  }

  // ============================================================
  // LOAD LEAD
  // ============================================================

  Future<void> _loadLead() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final lead = await ref
          .read(leadsRepositoryProvider)
          .getLeadDetail(widget.leadId);

      if (!mounted) return;

      setState(() {
        _lead = lead;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  // ============================================================
  // EDIT LEAD
  // ============================================================

  Future<void> _editLead() async {
    final lead = _lead;

    if (lead == null) {
      return;
    }

    final result = await Navigator.push<Object?>(
      context,
      MaterialPageRoute(
        builder: (context) => CreateLeadScreen(
          lead: lead,
        ),
      ),
    );

    if (!mounted) {
      return;
    }

    // The edit screen returns the updated LeadModel.
    if (result is LeadModel) {
      setState(() {
        _lead = result;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Lead details updated successfully.',
          ),
        ),
      );

      return;
    }

    // Fallback if the screen returns true.
    if (result == true) {
      await _loadLead();

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Lead details updated successfully.',
          ),
        ),
      );
    }
  }

  // ============================================================
  // DELETE LEAD
  // ============================================================

  Future<void> _deleteLead() async {
    final lead = _lead;

    if (lead == null || _isDeleting) {
      return;
    }

    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'Delete Lead',
          ),
          content: Text(
            'Are you sure you want to delete "${lead.name}"?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  false,
                );
              },
              child: const Text(
                'Cancel',
              ),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  true,
                );
              },
              child: const Text(
                'Delete',
              ),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true) {
      return;
    }

    setState(() {
      _isDeleting = true;
    });

    try {
      await ref
          .read(
            leadListControllerProvider.notifier,
          )
          .deleteLead(
            leadId: lead.id,
          );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Lead deleted successfully.',
          ),
        ),
      );

      Navigator.pop(
        context,
        true,
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isDeleting = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to delete lead: $e',
          ),
        ),
      );
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Lead Details',
        ),
        actions: [
          if (_lead != null)
            IconButton(
              onPressed: _isDeleting
                  ? null
                  : _editLead,
              icon: const Icon(
                Icons.edit,
              ),
              tooltip: 'Edit Lead',
            ),
          if (_lead != null)
            IconButton(
              onPressed: _isDeleting
                  ? null
                  : _deleteLead,
              icon: const Icon(
                Icons.delete_outline,
              ),
              tooltip: 'Delete Lead',
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  // ============================================================
  // BODY
  // ============================================================

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline,
                size: 48,
              ),
              const SizedBox(height: 16),
              const Text(
                'Unable to load lead.',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _loadLead,
                child: const Text(
                  'Retry',
                ),
              ),
            ],
          ),
        ),
      );
    }

    final lead = _lead;

    if (lead == null) {
      return const Center(
        child: Text(
          'Lead not found.',
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadLead,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ======================================================
          // NAME
          // ======================================================

          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    lead.name,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Lead ID: ${lead.id}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          // ======================================================
          // CONTACT INFORMATION
          // ======================================================

          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Contact Information',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 16),

                  if (lead.phoneNumbers.isNotEmpty)
                    _InfoRow(
                      icon: Icons.phone,
                      title: 'Phone',
                      value:
                          lead.phoneNumbers.join(', '),
                    ),

                  if (lead.email != null &&
                      lead.email!.isNotEmpty)
                    _InfoRow(
                      icon: Icons.email_outlined,
                      title: 'Email',
                      value: lead.email!,
                    ),

                  if (lead.phoneNumbers.isEmpty &&
                      (lead.email == null ||
                          lead.email!.isEmpty))
                    const Text(
                      'No contact information available.',
                    ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          // ======================================================
          // LEAD INFORMATION
          // ======================================================

          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Lead Information',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 16),

                  if (lead.source != null)
                    _InfoRow(
                      icon: Icons.source_outlined,
                      title: 'Source',
                      value: lead.source!.name,
                    ),

                  if (lead.status != null)
                    _InfoRow(
                      icon: Icons.flag_outlined,
                      title: 'Status',
                      value: lead.status!.name,
                    ),

                  if (lead.purposes.isNotEmpty)
                    _InfoRow(
                      icon: Icons.category_outlined,
                      title: 'Purpose',
                      value:
                          lead.purposes.join(', '),
                    ),

                  // score is non-nullable in LeadModel,
                  // so no null check is required.
                  _InfoRow(
                    icon: Icons.star_outline,
                    title: 'Score',
                    value: lead.score.toString(),
                  ),
                ],
              ),
            ),
          ),

          // ======================================================
          // NOTES
          // ======================================================

          if (lead.notes != null &&
              lead.notes!.isNotEmpty) ...[
            const SizedBox(height: 12),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Notes',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 12),

                    Text(
                      lead.notes!,
                      style: const TextStyle(
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],

          const SizedBox(height: 24),

          // ======================================================
          // DELETE BUTTON
          // ======================================================

          SizedBox(
            height: 48,
            child: OutlinedButton.icon(
              onPressed: _isDeleting
                  ? null
                  : _deleteLead,
              icon: _isDeleting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child:
                          CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(
                      Icons.delete_outline,
                    ),
              label: Text(
                _isDeleting
                    ? 'Deleting...'
                    : 'Delete Lead',
              ),
            ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// ================================================================
// INFO ROW
// ================================================================

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        bottom: 14,
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 22,
            color: Theme.of(context)
                .colorScheme
                .primary,
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),

                const SizedBox(height: 3),

                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}