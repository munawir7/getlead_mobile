
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'lead_model.dart';
import 'leads_repository.dart';

class LeadDetailScreen extends ConsumerStatefulWidget {
  const LeadDetailScreen({
    super.key,
    required this.leadId,
    this.initialLead,
  });

  final String leadId;
  final LeadModel? initialLead;

  @override
  ConsumerState<LeadDetailScreen> createState() =>
      _LeadDetailScreenState();
}

class _LeadDetailScreenState
    extends ConsumerState<LeadDetailScreen> {
  LeadModel? _lead;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();

    _lead = widget.initialLead;

    _loadLead();
  }

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
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage = error.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final lead = _lead;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Lead Details',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: _buildBody(lead),
    );
  }

  Widget _buildBody(LeadModel? lead) {
    if (_isLoading && lead == null) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_errorMessage != null && lead == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline,
                size: 50,
              ),
              const SizedBox(height: 16),
              const Text(
                'Failed to load lead',
                style: TextStyle(
                  fontSize: 20,
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
                child: const Text('Try Again'),
              ),
            ],
          ),
        ),
      );
    }

    if (lead == null) {
      return const Center(
        child: Text('Lead not found.'),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadLead,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildHeader(lead),
          const SizedBox(height: 16),
          _buildContactSection(lead),
          const SizedBox(height: 16),
          _buildLeadInformation(lead),
        ],
      ),
    );
  }

  Widget _buildHeader(LeadModel lead) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            CircleAvatar(
              radius: 36,
              child: Text(
                lead.name.isNotEmpty
                    ? lead.name[0].toUpperCase()
                    : '?',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              lead.name,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (lead.status != null) ...[
              const SizedBox(height: 10),
              Chip(
                label: Text(lead.status!.name),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildContactSection(LeadModel lead) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Contact Information',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 14),
            if (lead.email != null && lead.email!.isNotEmpty)
              _InfoRow(
                icon: Icons.email_outlined,
                label: 'Email',
                value: lead.email!,
              ),
            if (lead.phoneNumbers.isNotEmpty)
              ...lead.phoneNumbers.map(
                (phone) => _InfoRow(
                  icon: Icons.phone_outlined,
                  label: 'Phone',
                  value: phone,
                ),
              ),
            if ((lead.email == null || lead.email!.isEmpty) &&
                lead.phoneNumbers.isEmpty)
              const Text(
                'No contact information available.',
                style: TextStyle(
                  color: Colors.grey,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLeadInformation(LeadModel lead) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Lead Information',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 14),
            _InfoRow(
              icon: Icons.fingerprint,
              label: 'Lead ID',
              value: lead.id,
            ),
            if (lead.source != null)
              _InfoRow(
                icon: Icons.source_outlined,
                label: 'Source',
                value: lead.source!.name,
              ),
            _InfoRow(
              icon: Icons.star_outline,
              label: 'Score',
              value: lead.score.toString(),
            ),
            if (lead.purposes.isNotEmpty)
              _InfoRow(
                icon: Icons.flag_outlined,
                label: 'Purpose',
                value: lead.purposes.join(', '),
              ),
            if (lead.status != null) ...[
              _InfoRow(
                icon: Icons.info_outline,
                label: 'Status',
                value: lead.status!.name,
              ),
              if (lead.status!.slug != null)
                _InfoRow(
                  icon: Icons.link,
                  label: 'Status Slug',
                  value: lead.status!.slug!,
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 21,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: SelectableText(
              value,
              style: TextStyle(
                color: Colors.grey.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

