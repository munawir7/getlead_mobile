
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'lead_list_controller.dart';
import 'lead_model.dart';
import 'leads_repository.dart';

class CreateLeadScreen extends ConsumerStatefulWidget {
  final LeadModel? lead;

  const CreateLeadScreen({
    super.key,
    this.lead,
  });

  @override
  ConsumerState<CreateLeadScreen> createState() =>
      _CreateLeadScreenState();
}

class _CreateLeadScreenState
    extends ConsumerState<CreateLeadScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _notesController = TextEditingController();

  bool _isLoadingMeta = true;
  bool _isSaving = false;

  String? _selectedSourceId;
  String? _selectedStatusId;

  List<dynamic> _sources = [];
  List<LeadStatus> _statuses = [];

  bool get _isEdit => widget.lead != null;

  @override
  void initState() {
    super.initState();

    _initializeForm();
    _loadMeta();
  }

  // ============================================================
  // INITIALIZE FORM
  // ============================================================

  void _initializeForm() {
    final lead = widget.lead;

    if (lead == null) {
      return;
    }

    _nameController.text = lead.name;

    // Load existing mobile number when editing.
    if (lead.phoneNumbers.isNotEmpty) {
      _phoneController.text = lead.phoneNumbers.first;
    } else {
      _phoneController.text = '';
    }

    _emailController.text = lead.email ?? '';
    _notesController.text = lead.notes ?? '';

    _selectedSourceId = lead.source?.id;
    _selectedStatusId = lead.status?.id;
  }

  // ============================================================
  // LOAD META
  // ============================================================

  Future<void> _loadMeta() async {
    try {
      final meta = await ref
          .read(leadsRepositoryProvider)
          .getLeadMeta();

      if (!mounted) {
        return;
      }

      final sourceMap = <String, dynamic>{};

      for (final source in meta.sources) {
        final id = _readId(source);

        if (id != null && id.isNotEmpty) {
          sourceMap[id] = source;
        }
      }

      final uniqueSources = sourceMap.values.toList();

      String? sourceId = _selectedSourceId;

      final sourceExists = sourceId != null &&
          uniqueSources.any(
            (source) => _readId(source) == sourceId,
          );

      if (!sourceExists) {
        sourceId = null;
      }

      String? statusId = _selectedStatusId;

      final statusExists = statusId != null &&
          meta.statuses.any(
            (status) => status.id == statusId,
          );

      if (!statusExists) {
        statusId = null;
      }

      setState(() {
        _sources = uniqueSources;
        _statuses = meta.statuses;
        _selectedSourceId = sourceId;
        _selectedStatusId = statusId;
        _isLoadingMeta = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoadingMeta = false;
      });

      _showError(
        'Failed to load lead options: $e',
      );
    }
  }

  // ============================================================
  // READ META ID
  // ============================================================

  String? _readId(dynamic item) {
    if (item == null) {
      return null;
    }

    if (item is Map<String, dynamic>) {
      final id = item['id'];

      if (id == null) {
        return null;
      }

      return id.toString();
    }

    try {
      final value = item.id;

      if (value == null) {
        return null;
      }

      return value.toString();
    } catch (_) {
      return null;
    }
  }

  // ============================================================
  // READ META NAME
  // ============================================================

  String _readName(dynamic item) {
    if (item == null) {
      return '';
    }

    if (item is Map<String, dynamic>) {
      final name = item['name'];

      if (name == null) {
        return '';
      }

      return name.toString();
    }

    try {
      final value = item.name;

      if (value == null) {
        return '';
      }

      return value.toString();
    } catch (_) {
      return '';
    }
  }

  // ============================================================
  // SAVE LEAD
  // ============================================================

  Future<void> _saveLead() async {
    if (_isSaving) {
      return;
    }

    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedSourceId == null ||
        _selectedSourceId!.isEmpty) {
      _showError(
        'Please select a source.',
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      if (_isEdit) {
        final updatedLead = await ref
            .read(
              leadListControllerProvider.notifier,
            )
            .editLead(
              leadId: widget.lead!.id,
              name: _nameController.text.trim(),
              phoneNumber: _phoneController.text.trim(),
              email: _emailController.text.trim().isEmpty
                  ? null
                  : _emailController.text.trim(),
              sourceId: _selectedSourceId!,
              statusId: _selectedStatusId,
              notes: _notesController.text.trim().isEmpty
                  ? null
                  : _notesController.text.trim(),
            );

        if (!mounted) {
          return;
        }

        Navigator.pop(
          context,
          updatedLead,
        );
      } else {
        await ref
            .read(
              leadListControllerProvider.notifier,
            )
            .createLead(
              name: _nameController.text.trim(),
              phoneNumber: _phoneController.text.trim(),
              email: _emailController.text.trim().isEmpty
                  ? null
                  : _emailController.text.trim(),
              sourceId: _selectedSourceId!,
              statusId: _selectedStatusId,
              notes: _notesController.text.trim().isEmpty
                  ? null
                  : _notesController.text.trim(),
            );

        if (!mounted) {
          return;
        }

        Navigator.pop(
          context,
          true,
        );
      }
    } catch (e) {
      if (!mounted) {
        return;
      }

      _showApiError(e);
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  // ============================================================
  // SHOW ERROR
  // ============================================================

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  // ============================================================
  // API ERROR
  // ============================================================

  void _showApiError(Object error) {
    String message = 'Something went wrong.';

    if (error is DioException) {
      final response = error.response;

      if (response?.statusCode == 422) {
        final data = response?.data;

        if (data is Map<String, dynamic>) {
          final errors = data['errors'];

          if (errors is Map<String, dynamic>) {
            final messages = <String>[];

            errors.forEach(
              (key, value) {
                if (value is List) {
                  messages.addAll(
                    value.map(
                      (item) => item.toString(),
                    ),
                  );
                } else {
                  messages.add(
                    value.toString(),
                  );
                }
              },
            );

            if (messages.isNotEmpty) {
              message = messages.join('\n');
            }
          }

          if (message == 'Something went wrong.') {
            final apiMessage = data['message'];

            if (apiMessage != null) {
              message = apiMessage.toString();
            }
          }
        }
      } else if (response?.statusCode == 401) {
        message =
            'Session expired. Please login again.';
      } else if (response?.statusCode == 404) {
        message =
            'Lead or resource not found.';
      } else if (response?.statusCode == 400) {
        message = 'Invalid request.';
      } else {
        message =
            error.message ?? 'Request failed.';
      }
    } else {
      message = error.toString();
    }

    _showError(message);
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _notesController.dispose();

    super.dispose();
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final title = _isEdit
        ? 'Edit Lead'
        : 'Create Lead';

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: _isLoadingMeta
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // ==================================================
                  // NAME
                  // ==================================================

                  TextFormField(
                    controller: _nameController,
                    textInputAction:
                        TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Name',
                      hintText: 'Enter lead name',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null ||
                          value.trim().isEmpty) {
                        return 'Name is required';
                      }

                      return null;
                    },
                  ),

                  const SizedBox(height: 16),

                  // ==================================================
                  // CONTACT INFORMATION
                  // ==================================================

                  const Text(
                    'Contact Information',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 12),

                  // ==================================================
                  // MOBILE NUMBER
                  // ==================================================

                  TextFormField(
                    controller: _phoneController,
                    keyboardType:
                        TextInputType.phone,
                    textInputAction:
                        TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Mobile Number',
                      hintText:
                          'Enter mobile number',
                      prefixIcon:
                          Icon(Icons.phone_outlined),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (!_isEdit &&
                          (value == null ||
                              value.trim().isEmpty)) {
                        return 'Mobile number is required';
                      }

                      return null;
                    },
                  ),

                  const SizedBox(height: 16),

                  // ==================================================
                  // EMAIL
                  // ==================================================

                  TextFormField(
                    controller: _emailController,
                    keyboardType:
                        TextInputType.emailAddress,
                    textInputAction:
                        TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      hintText:
                          'Enter email address',
                      prefixIcon:
                          Icon(Icons.email_outlined),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null ||
                          value.trim().isEmpty) {
                        return null;
                      }

                      final email = value.trim();

                      if (!email.contains('@') ||
                          !email.contains('.')) {
                        return 'Enter a valid email';
                      }

                      return null;
                    },
                  ),

                  const SizedBox(height: 16),

                  // ==================================================
                  // SOURCE
                  // ==================================================

                  DropdownButtonFormField<String>(
                    initialValue:
                        _selectedSourceId,
                    decoration:
                        const InputDecoration(
                      labelText: 'Source',
                      border: OutlineInputBorder(),
                    ),
                    items: _sources.map(
                      (source) {
                        final id =
                            _readId(source);

                        final name =
                            _readName(source);

                        if (id == null ||
                            id.isEmpty) {
                          return null;
                        }

                        return DropdownMenuItem<String>(
                          value: id,
                          child: Text(
                            name.isEmpty
                                ? id
                                : name,
                          ),
                        );
                      },
                    ).whereType<
                        DropdownMenuItem<String>>()
                        .toList(),
                    onChanged: _isSaving
                        ? null
                        : (value) {
                            setState(() {
                              _selectedSourceId =
                                  value;
                            });
                          },
                    validator: (value) {
                      if (value == null ||
                          value.isEmpty) {
                        return 'Source is required';
                      }

                      return null;
                    },
                  ),

                  const SizedBox(height: 16),

                  // ==================================================
                  // STATUS
                  // ==================================================

                  DropdownButtonFormField<String>(
                    initialValue:
                        _selectedStatusId,
                    decoration:
                        const InputDecoration(
                      labelText: 'Status',
                      border: OutlineInputBorder(),
                    ),
                    items: _statuses.map(
                      (status) {
                        return DropdownMenuItem<String>(
                          value: status.id,
                          child: Text(
                            status.name,
                          ),
                        );
                      },
                    ).toList(),
                    onChanged: _isSaving
                        ? null
                        : (value) {
                            setState(() {
                              _selectedStatusId =
                                  value;
                            });
                          },
                  ),

                  const SizedBox(height: 16),

                  // ==================================================
                  // NOTES
                  // ==================================================

                  TextFormField(
                    controller: _notesController,
                    minLines: 4,
                    maxLines: 6,
                    textInputAction:
                        TextInputAction.newline,
                    decoration: const InputDecoration(
                      labelText: 'Notes',
                      hintText: 'Enter notes',
                      alignLabelWithHint: true,
                      border: OutlineInputBorder(),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ==================================================
                  // SAVE BUTTON
                  // ==================================================

                  SizedBox(
                    height: 50,
                    child: FilledButton(
                      onPressed: _isSaving
                          ? null
                          : _saveLead,
                      child: _isSaving
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child:
                                  CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              _isEdit
                                  ? 'Update Lead'
                                  : 'Create Lead',
                            ),
                    ),
                  ),

                  const SizedBox(height: 16),
                ],
              ),
            ),
    );
  }
}
