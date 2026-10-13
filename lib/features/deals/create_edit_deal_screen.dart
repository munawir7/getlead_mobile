
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'deal_list_controller.dart';
import 'deal_model.dart';

class CreateEditDealScreen extends ConsumerStatefulWidget {
  final DealModel? deal;

  const CreateEditDealScreen({
    super.key,
    this.deal,
  });

  @override
  ConsumerState<CreateEditDealScreen> createState() =>
      _CreateEditDealScreenState();
}

class _CreateEditDealScreenState
    extends ConsumerState<CreateEditDealScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController =
      TextEditingController();

  final TextEditingController _amountController =
      TextEditingController();

  final TextEditingController _leadIdController =
      TextEditingController();

  final TextEditingController _branchIdController =
      TextEditingController();

  final TextEditingController _dealTypeIdController =
      TextEditingController();

  final TextEditingController _dealStatusIdController =
      TextEditingController();

  final TextEditingController _assignedToIdController =
      TextEditingController();

  final TextEditingController _dateController =
      TextEditingController();

  final TextEditingController _notesController =
      TextEditingController();

  final TextEditingController _educationController =
      TextEditingController();

  static const String _educationFieldId =
      '01KTE48YRAR6WY4PC9ACA58N13';

  bool _isSaving = false;

  bool get _isEditing => widget.deal != null;

  @override
  void initState() {
    super.initState();

    final deal = widget.deal;

    if (deal != null) {
      _nameController.text = deal.name;
      _amountController.text = deal.amount.toString();
      _leadIdController.text = deal.leadId ?? '';
      _branchIdController.text = deal.branchId ?? '';
      _dealTypeIdController.text = deal.dealTypeId ?? '';
      _dealStatusIdController.text = deal.dealStatusId ?? '';
      _assignedToIdController.text = deal.assignedToId ?? '';
      _dateController.text = deal.expectedCloseDate ?? '';
      _notesController.text = deal.notes ?? '';

      _educationController.text =
          deal.customFields[_educationFieldId]?.toString() ?? '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _leadIdController.dispose();
    _branchIdController.dispose();
    _dealTypeIdController.dispose();
    _dealStatusIdController.dispose();
    _assignedToIdController.dispose();
    _dateController.dispose();
    _notesController.dispose();
    _educationController.dispose();

    super.dispose();
  }

  Future<void> _saveDeal() async {
    if (_isSaving) return;

    if (!_formKey.currentState!.validate()) {
      return;
    }

    final amount = int.tryParse(_amountController.text.trim());

    if (amount == null || amount < 0) {
      _showMessage('Enter a valid non-negative whole-number amount.');
      return;
    }

    final name = _nameController.text.trim();
    final leadId = _leadIdController.text.trim();
    final branchId = _branchIdController.text.trim();
    final dealTypeId = _dealTypeIdController.text.trim();
    final dealStatusId = _dealStatusIdController.text.trim();
    final assignedToId = _assignedToIdController.text.trim();
    final education = _educationController.text.trim();
    final expectedCloseDate = _dateController.text.trim();
    final notes = _notesController.text.trim();

    if (education.isEmpty) {
      _showMessage('Education is required.');
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final values = <String, dynamic>{
        'name': name,
        'amount': amount,
        'lead_id': leadId,
        'branch_id': branchId,
        'deal_type_id': dealTypeId,
        'deal_status_id': dealStatusId,
        'assigned_to_id': assignedToId,
        'expected_close_date':
            expectedCloseDate.isEmpty ? null : expectedCloseDate,
        'notes': notes.isEmpty ? null : notes,
        'custom_fields': {
          _educationFieldId: education,
        },
      };

      if (_isEditing) {
        final updatedDeal = await ref
            .read(dealListControllerProvider.notifier)
            .editDeal(widget.deal!.id, values);

        if (!mounted) return;

        if (updatedDeal == null) {
          _showMessage('The deal update returned no deal data.');
          return;
        }
      } else {
        await ref
            .read(dealListControllerProvider.notifier)
            .createDeal(values);

        if (!mounted) return;
      }

      _showMessage(
        _isEditing
            ? 'Deal updated successfully.'
            : 'Deal created successfully.',
      );

      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;

      _showMessage(
        'Failed to ${_isEditing ? 'update' : 'create'} deal: $error',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _selectDate() async {
    final now = DateTime.now();

    final existingDate = DateTime.tryParse(
      _dateController.text.trim(),
    );

    final selectedDate = await showDatePicker(
      context: context,
      initialDate: existingDate ?? now,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (selectedDate != null && mounted) {
      setState(() {
        _dateController.text =
            '${selectedDate.year.toString().padLeft(4, '0')}-'
            '${selectedDate.month.toString().padLeft(2, '0')}-'
            '${selectedDate.day.toString().padLeft(2, '0')}';
      });
    }
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      border: const OutlineInputBorder(),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 14,
      ),
    );
  }

  Widget _buildRequiredField({
    required TextEditingController controller,
    required String label,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      decoration: _inputDecoration(label),
      keyboardType: keyboardType,
      textInputAction: TextInputAction.next,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return '$label is required.';
        }

        return null;
      },
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Deal' : 'Create Deal'),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildRequiredField(
                controller: _nameController,
                label: 'Deal Name',
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: _amountController,
                decoration: _inputDecoration('Amount *'),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: false,
                ),
                textInputAction: TextInputAction.next,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Amount is required.';
                  }

                  final amount = int.tryParse(value.trim());

                  if (amount == null || amount < 0) {
                    return 'Enter a valid non-negative whole number.';
                  }

                  return null;
                },
              ),

              const SizedBox(height: 16),

              _buildRequiredField(
                controller: _leadIdController,
                label: 'Lead ID',
              ),

              const SizedBox(height: 16),

              _buildRequiredField(
                controller: _branchIdController,
                label: 'Branch ID',
              ),

              const SizedBox(height: 16),

              _buildRequiredField(
                controller: _dealTypeIdController,
                label: 'Deal Type ID',
              ),

              const SizedBox(height: 16),

              _buildRequiredField(
                controller: _dealStatusIdController,
                label: 'Deal Status ID',
              ),

              const SizedBox(height: 16),

              _buildRequiredField(
                controller: _assignedToIdController,
                label: 'Assigned User ID',
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: _dateController,
                readOnly: true,
                decoration: _inputDecoration(
                  'Expected Close Date',
                ).copyWith(
                  suffixIcon: IconButton(
                    onPressed: _selectDate,
                    icon: const Icon(Icons.calendar_today),
                  ),
                ),
                onTap: _selectDate,
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: _notesController,
                decoration: _inputDecoration('Notes'),
                minLines: 3,
                maxLines: 5,
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: _educationController,
                decoration: _inputDecoration('Education *'),
                textInputAction: TextInputAction.done,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Education is required.';
                  }

                  return null;
                },
              ),

              const SizedBox(height: 24),

              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveDeal,
                  child: _isSaving
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          _isEditing ? 'Update Deal' : 'Create Deal',
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

