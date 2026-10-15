import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'task_model.dart';
import 'tasks_repository.dart';

class TaskDetailScreen extends ConsumerStatefulWidget {
  final String taskId;

  const TaskDetailScreen({
    super.key,
    required this.taskId,
  });

  @override
  ConsumerState<TaskDetailScreen> createState() =>
      _TaskDetailScreenState();
}

class _TaskDetailScreenState extends ConsumerState<TaskDetailScreen> {
  TaskModel? _task;

  bool _isLoading = true;
  bool _isRescheduling = false;
  bool _isDeleting = false;
  bool _isCompleting = false;
  bool _isCancelling = false;

  String? _errorMessage;

  final TextEditingController _reasonController =
      TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadTaskDetails();
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  // ============================================================
  // LOAD TASK DETAILS
  // ============================================================

  Future<void> _loadTaskDetails() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final repository = ref.read(tasksRepositoryProvider);

      final task = await repository.getTaskDetail(widget.taskId);

      if (!mounted) return;

      setState(() {
        _task = task;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage = 'Unable to load task details.';
        _isLoading = false;
      });
    }
  }

  // ============================================================
  // CHECK WHETHER AN ACTION IS RUNNING
  // ============================================================

  bool get _isPerformingAction =>
      _isRescheduling ||
      _isDeleting ||
      _isCompleting ||
      _isCancelling;

  // ============================================================
  // COMPLETE TASK CONFIRMATION
  // ============================================================

  Future<void> _showCompleteTaskDialog() async {
    if (_task == null || _isPerformingAction) return;

    final commentController = TextEditingController();

    final shouldComplete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Row(
            children: [
              Icon(
                Icons.task_alt,
                color: Colors.green,
              ),
              SizedBox(width: 10),
              Expanded(
                child: Text('Complete Task'),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Are you sure you want to mark '
                  '"${_task!.name}" as completed?',
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: commentController,
                  maxLength: 1000,
                  maxLines: 3,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    labelText: 'Comment (optional)',
                    hintText: 'Enter completion notes',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              icon: const Icon(Icons.check),
              label: const Text('Complete'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        );
      },
    );

    if (shouldComplete != true || !mounted) {
      commentController.dispose();
      return;
    }

    final comment = commentController.text.trim();
    commentController.dispose();

    await _completeTask(
      comment: comment.isEmpty ? null : comment,
    );
  }

  // ============================================================
  // COMPLETE TASK API CALL
  // ============================================================

  Future<void> _completeTask({String? comment}) async {
    if (_isPerformingAction) return;

    setState(() {
      _isCompleting = true;
    });

    try {
      final repository = ref.read(tasksRepositoryProvider);

      await repository.completeTask(
        taskId: widget.taskId,
        comment: comment,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Task completed successfully.'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );

      await _loadTaskDetails();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to complete task: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isCompleting = false;
        });
      }
    }
  }

  // ============================================================
  // CANCEL TASK CONFIRMATION
  // ============================================================

  Future<void> _showCancelTaskDialog() async {
    if (_task == null || _isPerformingAction) return;

    final reasonController = TextEditingController();

    final shouldCancel = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Row(
            children: [
              Icon(
                Icons.cancel_outlined,
                color: Colors.orange,
              ),
              SizedBox(width: 10),
              Expanded(
                child: Text('Cancel Task'),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Are you sure you want to cancel '
                  '"${_task!.name}"?',
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: reasonController,
                  maxLength: 500,
                  maxLines: 3,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    labelText: 'Reason (optional)',
                    hintText: 'Enter the cancellation reason',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('Keep Task'),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              icon: const Icon(Icons.cancel_outlined),
              label: const Text('Cancel Task'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        );
      },
    );

    if (shouldCancel != true || !mounted) {
      reasonController.dispose();
      return;
    }

    final reason = reasonController.text.trim();
    reasonController.dispose();

    await _cancelTask(
      reason: reason.isEmpty ? null : reason,
    );
  }

  // ============================================================
  // CANCEL TASK API CALL
  // ============================================================

  Future<void> _cancelTask({String? reason}) async {
    if (_isPerformingAction) return;

    setState(() {
      _isCancelling = true;
    });

    try {
      final repository = ref.read(tasksRepositoryProvider);

      await repository.cancelTask(
        taskId: widget.taskId,
        reason: reason,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Task cancelled successfully.'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );

      await _loadTaskDetails();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to cancel task: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isCancelling = false;
        });
      }
    }
  }

  // ============================================================
  // DELETE TASK CONFIRMATION
  // ============================================================

  Future<void> _showDeleteConfirmation() async {
    if (_isPerformingAction) return;

    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: Colors.red,
              ),
              SizedBox(width: 10),
              Expanded(
                child: Text('Delete Task'),
              ),
            ],
          ),
          content: Text(
            'Are you sure you want to delete '
            '"${_task?.name ?? 'this task'}"?\n\n'
            'This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              icon: const Icon(Icons.delete_outline),
              label: const Text('Delete'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true || !mounted) return;

    await _deleteTask();
  }

  // ============================================================
  // DELETE TASK API CALL
  // ============================================================

  Future<void> _deleteTask() async {
    if (_isPerformingAction) return;

    setState(() {
      _isDeleting = true;
    });

    try {
      final repository = ref.read(tasksRepositoryProvider);

      await repository.deleteTask(widget.taskId);

      if (!mounted) return;

      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to delete task: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isDeleting = false;
        });
      }
    }
  }

  // ============================================================
  // RESCHEDULE TASK DIALOG
  // ============================================================

  Future<void> _showRescheduleDialog() async {
    if (_task == null || _isPerformingAction) return;

    DateTime selectedDate = DateTime.now().add(
      const Duration(days: 1),
    );

    TimeOfDay selectedTime = const TimeOfDay(
      hour: 10,
      minute: 0,
    );

    _reasonController.clear();

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Row(
                children: [
                  Icon(
                    Icons.calendar_month,
                    color: Color(0xFF2563EB),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text('Reschedule Task'),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Select a new date and time for this task.',
                      style: TextStyle(
                        color: Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 20),

                    OutlinedButton.icon(
                      onPressed: () async {
                        final now = DateTime.now();

                        final pickedDate = await showDatePicker(
                          context: dialogContext,
                          initialDate: selectedDate.isBefore(
                            DateTime(now.year, now.month, now.day),
                          )
                              ? now
                              : selectedDate,
                          firstDate: DateTime(
                            now.year,
                            now.month,
                            now.day,
                          ),
                          lastDate: DateTime(now.year + 5),
                        );

                        if (pickedDate != null) {
                          setDialogState(() {
                            selectedDate = pickedDate;
                          });
                        }
                      },
                      icon: const Icon(Icons.event),
                      label: Text(
                        'Date: ${_formatDateOnly(selectedDate)}',
                      ),
                    ),

                    const SizedBox(height: 12),

                    OutlinedButton.icon(
                      onPressed: () async {
                        final pickedTime = await showTimePicker(
                          context: dialogContext,
                          initialTime: selectedTime,
                        );

                        if (pickedTime != null) {
                          setDialogState(() {
                            selectedTime = pickedTime;
                          });
                        }
                      },
                      icon: const Icon(Icons.access_time),
                      label: Text(
                        'Time: ${selectedTime.format(dialogContext)}',
                      ),
                    ),

                    const SizedBox(height: 20),

                    TextField(
                      controller: _reasonController,
                      maxLength: 500,
                      maxLines: 3,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        labelText: 'Reason (optional)',
                        hintText: 'Enter the reason for rescheduling',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: const Padding(
                          padding: EdgeInsets.only(bottom: 42),
                          child: Icon(Icons.notes),
                        ),
                        alignLabelWithHint: true,
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop(false);
                  },
                  child: const Text('Cancel'),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    final scheduledAt = DateTime(
                      selectedDate.year,
                      selectedDate.month,
                      selectedDate.day,
                      selectedTime.hour,
                      selectedTime.minute,
                    );

                    if (!scheduledAt.isAfter(DateTime.now())) {
                      ScaffoldMessenger.of(dialogContext).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Please select a future date and time.',
                          ),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }

                    Navigator.of(dialogContext).pop(true);
                  },
                  icon: const Icon(Icons.check),
                  label: const Text('Confirm'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result != true || !mounted) return;

    final scheduledAt = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
      selectedTime.hour,
      selectedTime.minute,
    );

    await _rescheduleTask(scheduledAt);
  }

  // ============================================================
  // RESCHEDULE TASK API CALL
  // ============================================================

  Future<void> _rescheduleTask(DateTime scheduledAt) async {
    if (_isPerformingAction) return;

    setState(() {
      _isRescheduling = true;
    });

    try {
      final repository = ref.read(tasksRepositoryProvider);

      await repository.rescheduleTask(
        taskId: widget.taskId,
        scheduledAt: scheduledAt,
        reason: _reasonController.text,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Task rescheduled successfully.'),
          backgroundColor: Colors.green,
        ),
      );

      await _loadTaskDetails();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to reschedule task: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isRescheduling = false;
        });
      }
    }
  }

  // ============================================================
  // BUILD SCREEN
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        title: const Text(
          'Task Details',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1E293B),
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _isLoading || _isPerformingAction
                ? null
                : _loadTaskDetails,
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading && _task == null) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_errorMessage != null && _task == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline,
                size: 48,
                color: Colors.redAccent,
              ),
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _loadTaskDetails,
                icon: const Icon(Icons.refresh),
                label: const Text('Try Again'),
              ),
            ],
          ),
        ),
      );
    }

    if (_task == null) {
      return const Center(
        child: Text('Task details are unavailable.'),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadTaskDetails,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildHeader(_task!),

          const SizedBox(height: 16),

          // RESCHEDULE TASK BUTTON
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isPerformingAction
                  ? null
                  : _showRescheduleDialog,
              icon: _isRescheduling
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.calendar_month_outlined),
              label: Text(
                _isRescheduling
                    ? 'Rescheduling...'
                    : 'Reschedule Task',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // COMPLETE TASK BUTTON
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isPerformingAction
                  ? null
                  : _showCompleteTaskDialog,
              icon: _isCompleting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.task_alt),
              label: Text(
                _isCompleting
                    ? 'Completing Task...'
                    : 'Complete Task',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // CANCEL TASK BUTTON
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _isPerformingAction
                  ? null
                  : _showCancelTaskDialog,
              icon: _isCancelling
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.orange,
                      ),
                    )
                  : const Icon(Icons.cancel_outlined),
              label: Text(
                _isCancelling
                    ? 'Cancelling Task...'
                    : 'Cancel Task',
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.orange,
                side: const BorderSide(color: Colors.orange),
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // DELETE TASK BUTTON
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _isPerformingAction
                  ? null
                  : _showDeleteConfirmation,
              icon: _isDeleting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.red,
                      ),
                    )
                  : const Icon(Icons.delete_outline),
              label: Text(
                _isDeleting ? 'Deleting Task...' : 'Delete Task',
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // TASK INFORMATION
          _buildSection(
            title: 'Task Information',
            icon: Icons.assignment_outlined,
            children: [
              _buildInfoRow(
                'Task Name',
                _task!.name,
                Icons.title,
              ),
              _buildInfoRow(
                'Description',
                _task!.description,
                Icons.description_outlined,
              ),
              _buildInfoRow(
                'Category',
                _task!.category?.name,
                Icons.category_outlined,
              ),
              _buildInfoRow(
                'Priority',
                _task!.priority,
                Icons.flag_outlined,
              ),
              _buildInfoRow(
                'Status',
                _task!.status,
                Icons.check_circle_outline,
              ),
            ],
          ),

          const SizedBox(height: 16),

          // SCHEDULE
          _buildSection(
            title: 'Schedule',
            icon: Icons.calendar_month_outlined,
            children: [
              _buildInfoRow(
                'Scheduled Date',
                _formatDate(_task!.scheduledAt),
                Icons.event_outlined,
              ),
              _buildInfoRow(
                'Created At',
                _formatDate(_task!.createdAt),
                Icons.add_circle_outline,
              ),
              _buildInfoRow(
                'Last Updated',
                _formatDate(_task!.updatedAt),
                Icons.update,
              ),
              _buildInfoRow(
                'Completed At',
                _formatDate(_task!.completedAt),
                Icons.task_alt,
              ),
              _buildInfoRow(
                'Cancelled At',
                _formatDate(_task!.cancelledAt),
                Icons.cancel_outlined,
              ),
            ],
          ),

          const SizedBox(height: 16),

          // ASSIGNMENT
          _buildSection(
            title: 'Assignment',
            icon: Icons.people_outline,
            children: [
              _buildInfoRow(
                'Assigned To',
                _task!.assignment?.assignedTo?.name,
                Icons.person_outline,
              ),
              _buildInfoRow(
                'Assigned User ID',
                _task!.assignment?.assignedTo?.id,
                Icons.badge_outlined,
              ),
              _buildInfoRow(
                'Assigned By',
                _task!.assignment?.assignedBy?.name,
                Icons.person_add_alt,
              ),
              _buildInfoRow(
                'Assignment Date',
                _formatDate(_task!.assignment?.assignedAt),
                Icons.access_time,
              ),
            ],
          ),

          // RELATED RECORD
          if (_task!.entity != null) ...[
            const SizedBox(height: 16),
            _buildSection(
              title: 'Related Record',
              icon: Icons.link,
              children: [
                _buildInfoRow(
                  'Record Name',
                  _task!.entity?.name,
                  Icons.label_outline,
                ),
                _buildInfoRow(
                  'Record Type',
                  _task!.entity?.type,
                  Icons.category_outlined,
                ),
                _buildInfoRow(
                  'Record ID',
                  _task!.entity?.id,
                  Icons.fingerprint,
                ),
              ],
            ),
          ],

          // COMMENT
          if (_task!.comment != null &&
              _task!.comment!.trim().isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildSection(
              title: 'Comment',
              icon: Icons.comment_outlined,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(_task!.comment!),
                ),
              ],
            ),
          ],

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeader(TaskModel task) {
    final statusColor = _getStatusColor(task.status);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFE5EAF2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 7,
            ),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              task.status.toUpperCase(),
              style: TextStyle(
                color: statusColor,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),

          const SizedBox(height: 16),

          Text(
            task.name,
            style: const TextStyle(
              fontSize: 23,
              fontWeight: FontWeight.bold,
              color: Color(0xFF172033),
            ),
          ),

          const SizedBox(height: 8),

          Text(
            task.description?.trim().isNotEmpty == true
                ? task.description!
                : 'No description available.',
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontSize: 14,
              height: 1.5,
            ),
          ),

          const SizedBox(height: 16),

          Row(
            children: [
              const Icon(
                Icons.flag_outlined,
                size: 19,
                color: Colors.orange,
              ),
              const SizedBox(width: 8),
              Text(
                'Priority: ${task.priority}',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),

          if (task.isOverdue) ...[
            const SizedBox(height: 12),
            const Row(
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.red,
                  size: 20,
                ),
                SizedBox(width: 8),
                Text(
                  'This task is overdue',
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // ============================================================
  // SECTION
  // ============================================================

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFE5EAF2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: const Color(0xFF2563EB),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF172033),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(),
          ...children,
        ],
      ),
    );
  }

  // ============================================================
  // INFORMATION ROW
  // ============================================================

  Widget _buildInfoRow(
    String label,
    String? value,
    IconData icon,
  ) {
    final displayValue =
        value == null || value.trim().isEmpty
            ? 'Not available'
            : value;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 19,
            color: const Color(0xFF64748B),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF64748B),
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 3,
            child: Text(
              displayValue,
              textAlign: TextAlign.end,
              style: const TextStyle(
                color: Color(0xFF172033),
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // DATE FORMATTING
  // ============================================================

  String _formatDate(DateTime? date) {
    if (date == null) return 'Not available';

    final localDate = date.toLocal();

    final day = localDate.day.toString().padLeft(2, '0');
    final month = localDate.month.toString().padLeft(2, '0');
    final year = localDate.year.toString();

    final hour = localDate.hour % 12 == 0
        ? 12
        : localDate.hour % 12;

    final minute = localDate.minute.toString().padLeft(2, '0');
    final period = localDate.hour >= 12 ? 'PM' : 'AM';

    return '$day/$month/$year, $hour:$minute $period';
  }

  String _formatDateOnly(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');

    return '$day/$month/${date.year}';
  }

  // ============================================================
  // STATUS COLORS
  // ============================================================

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      case 'overdue':
        return Colors.deepOrange;
      case 'upcoming':
        return Colors.purple;
      case 'open':
        return Colors.blue;
      default:
        return Colors.blueGrey;
    }
  }
}