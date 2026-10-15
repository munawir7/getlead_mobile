import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants.dart';
import '../auth/auth_controller.dart';

class CreateTaskScreen extends ConsumerStatefulWidget {
  const CreateTaskScreen({super.key});

  @override
  ConsumerState<CreateTaskScreen> createState() => _CreateTaskScreenState();
}

class _CreateTaskScreenState extends ConsumerState<CreateTaskScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _assigneeIdController = TextEditingController();

  List<Map<String, dynamic>> _categories = [];
  List<Map<String, dynamic>> _priorities = [];

  String? _selectedCategoryId;
  String? _selectedPriority;

  DateTime _scheduledAt = DateTime.now().add(const Duration(hours: 1));

  bool _loadingMetadata = true;
  bool _creatingTask = false;

  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadMetadata();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _assigneeIdController.dispose();
    super.dispose();
  }

  // ============================================================
  // LOAD TASK CATEGORIES AND PRIORITIES
  // ============================================================

  Future<void> _loadMetadata() async {
    if (mounted) {
      setState(() {
        _loadingMetadata = true;
        _errorMessage = null;
      });
    }

    try {
      final api = ref.read(apiClientProvider);

      final response = await api.get(
        '/api/mobile/businesses/${AppConstants.businessId}/tasks/meta',
      );

      final responseData = response.data;

      if (responseData is! Map) {
        throw Exception('Unexpected task metadata response.');
      }

      final data = responseData['data'];

      if (data is! Map) {
        throw Exception('Task metadata was not returned.');
      }

      final categoriesData = data['categories'];
      final prioritiesData = data['priorities'];

      final categories = categoriesData is List
          ? categoriesData
              .whereType<Map>()
              .map((item) => Map<String, dynamic>.from(item))
              .where((item) => item['is_active'] != false)
              .where((item) => item['id'] != null)
              .toList()
          : <Map<String, dynamic>>[];

      final priorities = prioritiesData is List
          ? prioritiesData
              .whereType<Map>()
              .map((item) => Map<String, dynamic>.from(item))
              .where((item) => item['is_active'] != false)
              .where((item) => item['slug'] != null)
              .toList()
          : <Map<String, dynamic>>[];

      if (!mounted) return;

      setState(() {
        _categories = categories;
        _priorities = priorities;

        // Select the Call category by default when available.
        final callCategory = categories.where(
          (item) => item['slug']?.toString().toLowerCase() == 'call',
        );

        if (callCategory.isNotEmpty) {
          _selectedCategoryId = callCategory.first['id'].toString();
        } else if (categories.isNotEmpty) {
          _selectedCategoryId = categories.first['id'].toString();
        }

        // Select Medium priority by default when available.
        final mediumPriority = priorities.where(
          (item) => item['slug']?.toString().toLowerCase() == 'medium',
        );

        if (mediumPriority.isNotEmpty) {
          _selectedPriority = mediumPriority.first['slug'].toString();
        } else if (priorities.isNotEmpty) {
          _selectedPriority = priorities.first['slug'].toString();
        }

        _loadingMetadata = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loadingMetadata = false;
        _errorMessage = _friendlyError(e);
      });
    }
  }

  // ============================================================
  // PICK SCHEDULE DATE
  // ============================================================

  Future<void> _pickDate() async {
    final now = DateTime.now();

    final initialDate = _scheduledAt.isBefore(now)
        ? now
        : _scheduledAt;

    final selectedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: DateTime(now.year + 5),
    );

    if (selectedDate == null || !mounted) return;

    setState(() {
      _scheduledAt = DateTime(
        selectedDate.year,
        selectedDate.month,
        selectedDate.day,
        _scheduledAt.hour,
        _scheduledAt.minute,
      );
    });
  }

  // ============================================================
  // PICK SCHEDULE TIME
  // ============================================================

  Future<void> _pickTime() async {
    final selectedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_scheduledAt),
    );

    if (selectedTime == null || !mounted) return;

    setState(() {
      _scheduledAt = DateTime(
        _scheduledAt.year,
        _scheduledAt.month,
        _scheduledAt.day,
        selectedTime.hour,
        selectedTime.minute,
      );
    });
  }

  // ============================================================
  // CREATE TASK API
  // ============================================================

  Future<void> _createTask() async {
    if (_creatingTask) return;

    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) return;

    if (_selectedCategoryId == null || _selectedPriority == null) {
      _showMessage('Please select a category and priority.');
      return;
    }

    if (!_scheduledAt.isAfter(DateTime.now())) {
      _showMessage('Please select a future date and time.');
      return;
    }

    final assigneeId = _assigneeIdController.text.trim();

    if (assigneeId.isEmpty) {
      _showMessage('Please enter the assignee user ID.');
      return;
    }

    setState(() {
      _creatingTask = true;
    });

    try {
      final api = ref.read(apiClientProvider);

      final requestData = <String, dynamic>{
        'name': _nameController.text.trim(),
        'category_id': _selectedCategoryId,
        'scheduled_at': _scheduledAt.toUtc().toIso8601String(),
        'priority': _selectedPriority,
        'assigned_to_id': assigneeId,
      };

      final description = _descriptionController.text.trim();

      if (description.isNotEmpty) {
        requestData['description'] = description;
      }

      final response = await api.post(
        '/api/mobile/businesses/${AppConstants.businessId}/tasks',
        data: requestData,
      );

      if (!mounted) return;

      // The API returns the created task ID.
      final responseData = response.data;
      String? taskId;

      if (responseData is Map) {
        final data = responseData['data'];

        if (data is Map && data['id'] != null) {
          taskId = data['id'].toString();
        } else if (responseData['id'] != null) {
          taskId = responseData['id'].toString();
        }
      }

      if (taskId != null) {
        _showMessage('Task created successfully! ID: $taskId');
      } else {
        _showMessage('Task created successfully!');
      }

      // Return true so the previous screen can refresh its task list.
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;

      _showMessage(_friendlyError(e));
    } finally {
      if (mounted) {
        setState(() {
          _creatingTask = false;
        });
      }
    }
  }

  // ============================================================
  // ERROR HANDLING
  // ============================================================

  String _friendlyError(Object error) {
    if (error is DioException) {
      final statusCode = error.response?.statusCode;
      final responseData = error.response?.data;

      String? serverMessage;

      if (responseData is Map) {
        final message = responseData['message'];

        if (message != null) {
          serverMessage = message.toString();
        }

        // Laravel validation errors can contain field-specific messages.
        final errors = responseData['errors'];

        if (errors is Map && errors.isNotEmpty) {
          final firstErrors = errors.values.first;

          if (firstErrors is List && firstErrors.isNotEmpty) {
            return firstErrors.first.toString();
          }
        }
      }

      if (statusCode == 401) {
        return 'Your session may have expired. Please log in again.';
      }

      if (statusCode == 403) {
        return serverMessage ?? 'You do not have permission to create this task.';
      }

      if (statusCode == 404) {
        return serverMessage ?? 'The task API endpoint or business was not found.';
      }

      if (statusCode == 422) {
        return serverMessage ??
            'The server rejected the task details. Check the required fields.';
      }

      if (statusCode != null && statusCode >= 500) {
        return 'Server error ($statusCode). Please try again later.';
      }

      if (error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.receiveTimeout ||
          error.type == DioExceptionType.sendTimeout) {
        return 'The request timed out. Please try again.';
      }

      if (error.type == DioExceptionType.connectionError) {
        return 'Unable to connect. Check your internet connection.';
      }

      return serverMessage ?? error.message ?? 'Unable to create the task.';
    }

    return error.toString();
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
  // DATE FORMATTING
  // ============================================================

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');

    return '$day/$month/${date.year}';
  }

  // ============================================================
  // BUILD SCREEN
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Task'),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loadingMetadata) {
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
                color: Colors.red,
              ),
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _loadMetadata,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_categories.isEmpty || _priorities.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.info_outline,
                size: 48,
              ),
              const SizedBox(height: 12),
              const Text(
                'Task categories or priorities are unavailable.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadMetadata,
                child: const Text('Reload'),
              ),
            ],
          ),
        ),
      );
    }

    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ======================================================
          // TASK INFORMATION
          // ======================================================

          const Text(
            'Task Information',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 20),

          TextFormField(
            controller: _nameController,
            textCapitalization: TextCapitalization.sentences,
            maxLength: 255,
            decoration: const InputDecoration(
              labelText: 'Task Name *',
              hintText: 'Enter task name',
              prefixIcon: Icon(Icons.task_alt),
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              final name = value?.trim() ?? '';

              if (name.isEmpty) {
                return 'Task name is required.';
              }

              if (name.length < 3) {
                return 'Task name must contain at least 3 characters.';
              }

              if (name.length > 255) {
                return 'Task name cannot exceed 255 characters.';
              }

              return null;
            },
          ),

          const SizedBox(height: 16),

          TextFormField(
            controller: _descriptionController,
            textCapitalization: TextCapitalization.sentences,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Description',
              hintText: 'Enter task description',
              prefixIcon: Icon(Icons.description_outlined),
              border: OutlineInputBorder(),
              alignLabelWithHint: true,
            ),
          ),

          const SizedBox(height: 16),

          // ======================================================
          // CATEGORY
          // ======================================================

          DropdownButtonFormField<String>(
            key: ValueKey(_selectedCategoryId),
            initialValue: _selectedCategoryId,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Category *',
              prefixIcon: Icon(Icons.category_outlined),
              border: OutlineInputBorder(),
            ),
            items: _categories.map((category) {
              return DropdownMenuItem<String>(
                value: category['id'].toString(),
                child: Text(
                  '${category['name'] ?? 'Unnamed'}',
                  overflow: TextOverflow.ellipsis,
                ),
              );
            }).toList(),
            onChanged: _creatingTask
                ? null
                : (value) {
                    setState(() {
                      _selectedCategoryId = value;
                    });
                  },
            validator: (value) {
              if (value == null) {
                return 'Please select a category.';
              }

              return null;
            },
          ),

          const SizedBox(height: 16),

          // ======================================================
          // PRIORITY
          // ======================================================

          DropdownButtonFormField<String>(
            key: ValueKey(_selectedPriority),
            initialValue: _selectedPriority,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Priority *',
              prefixIcon: Icon(Icons.flag_outlined),
              border: OutlineInputBorder(),
            ),
            items: _priorities.map((priority) {
              return DropdownMenuItem<String>(
                value: priority['slug'].toString(),
                child: Text(
                  '${priority['name'] ?? 'Unnamed'}',
                  overflow: TextOverflow.ellipsis,
                ),
              );
            }).toList(),
            onChanged: _creatingTask
                ? null
                : (value) {
                    setState(() {
                      _selectedPriority = value;
                    });
                  },
            validator: (value) {
              if (value == null) {
                return 'Please select a priority.';
              }

              return null;
            },
          ),

          const SizedBox(height: 28),

          // ======================================================
          // SCHEDULE
          // ======================================================

          const Text(
            'Schedule',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _creatingTask ? null : _pickDate,
                  icon: const Icon(Icons.calendar_month),
                  label: Text(_formatDate(_scheduledAt)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _creatingTask ? null : _pickTime,
                  icon: const Icon(Icons.access_time),
                  label: Text(
                    TimeOfDay.fromDateTime(_scheduledAt).format(context),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 28),

          // ======================================================
          // ASSIGNMENT
          // ======================================================

          const Text(
            'Assignment',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 12),

          TextFormField(
            controller: _assigneeIdController,
            enabled: !_creatingTask,
            decoration: const InputDecoration(
              labelText: 'Assignee User ID *',
              hintText: 'Enter a valid user ID',
              prefixIcon: Icon(Icons.person_outline),
              border: OutlineInputBorder(),
              helperText: 'Enter the ID of the user assigned to this task.',
              helperMaxLines: 2,
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Assignee user ID is required.';
              }

              return null;
            },
          ),

          const SizedBox(height: 28),

          // ======================================================
          // CREATE TASK BUTTON
          // ======================================================

          SizedBox(
            height: 50,
            child: ElevatedButton.icon(
              onPressed: _creatingTask ? null : _createTask,
              icon: _creatingTask
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.add_task),
              label: Text(
                _creatingTask ? 'Creating Task...' : 'Create Task',
              ),
            ),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }
}