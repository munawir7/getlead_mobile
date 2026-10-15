import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../task/create_task_screen.dart';
import 'task_list_controller.dart';
import 'task_detail_screen.dart';
import 'task_model.dart';

class TaskListScreen extends ConsumerStatefulWidget {
  const TaskListScreen({super.key});

  @override
  ConsumerState<TaskListScreen> createState() =>
      _TaskListScreenState();
}

class _TaskListScreenState extends ConsumerState<TaskListScreen> {
  final TextEditingController _searchController =
      TextEditingController();

  String _selectedStatus = 'all';

  static const Color primaryColor = Color(0xFF2563EB);
  static const Color backgroundColor = Color(0xFFF5F7FB);

  final List<Map<String, String>> _filters = const [
    {'label': 'All', 'value': 'all'},
    {'label': 'Open', 'value': 'open'},
    {'label': 'Completed', 'value': 'completed'},
    {'label': 'Overdue', 'value': 'overdue'},
    {'label': 'Cancelled', 'value': 'cancelled'},
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ============================================================
  // CREATE TASK
  // ============================================================

  Future<void> _openCreateTaskScreen() async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => const CreateTaskScreen(),
      ),
    );

    if (!mounted) return;

    if (created == true) {
      await ref
          .read(taskListControllerProvider.notifier)
          .refreshTasks();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Task created successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  // ============================================================
  // OPEN TASK DETAILS
  // ============================================================

  Future<void> _openTaskDetails(TaskModel task) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TaskDetailScreen(
          taskId: task.id,
        ),
      ),
    );

    if (!mounted) return;

    // Refresh the list when returning from the details screen.
    await ref
        .read(taskListControllerProvider.notifier)
        .refreshTasks();
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final tasksState = ref.watch(taskListControllerProvider);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tasks',
              style: TextStyle(
                fontSize: 23,
                fontWeight: FontWeight.bold,
                color: Color(0xFF172033),
              ),
            ),
            SizedBox(height: 3),
            Text(
              'Manage your daily activities',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () {
              ref
                  .read(taskListControllerProvider.notifier)
                  .refreshTasks();
            },
            icon: const Icon(
              Icons.refresh_rounded,
              color: primaryColor,
            ),
            tooltip: 'Refresh tasks',
          ),
          IconButton(
            onPressed: _openCreateTaskScreen,
            icon: const Icon(
              Icons.add_circle_outline_rounded,
              color: primaryColor,
              size: 27,
            ),
            tooltip: 'Create task',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildSearchField(),
            _buildStatusFilters(),
            Expanded(
              child: tasksState.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(
                    color: primaryColor,
                  ),
                ),
                error: (error, stackTrace) =>
                    _buildErrorState(error.toString()),
                data: _buildTaskList,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // SEARCH FIELD
  // ============================================================

  Widget _buildSearchField() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: TextField(
        controller: _searchController,
        onChanged: (value) {
          ref
              .read(taskListControllerProvider.notifier)
              .searchTasks(value);

          setState(() {});
        },
        decoration: InputDecoration(
          hintText: 'Search tasks...',
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: Colors.grey,
          ),
          suffixIcon: _searchController.text.isEmpty
              ? null
              : IconButton(
                  onPressed: () {
                    _searchController.clear();

                    ref
                        .read(taskListControllerProvider.notifier)
                        .searchTasks('');

                    setState(() {});
                  },
                  icon: const Icon(Icons.close),
                ),
          filled: true,
          fillColor: backgroundColor,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // STATUS FILTERS
  // ============================================================

  Widget _buildStatusFilters() {
    return Container(
      color: Colors.white,
      height: 58,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: _filters.length,
        separatorBuilder: (_, __) =>
            const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final filter = _filters[index];
          final value = filter['value']!;
          final selected = _selectedStatus == value;

          return ChoiceChip(
            label: Text(filter['label']!),
            selected: selected,
            showCheckmark: false,
            selectedColor: primaryColor,
            backgroundColor: backgroundColor,
            side: BorderSide.none,
            labelStyle: TextStyle(
              color: selected ? Colors.white : Colors.black87,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
            onSelected: (_) {
              setState(() {
                _selectedStatus = value;
              });

              ref
                  .read(taskListControllerProvider.notifier)
                  .filterByStatus(value);
            },
          );
        },
      ),
    );
  }

  // ============================================================
  // TASK LIST
  // ============================================================

  Widget _buildTaskList(List<TaskModel> tasks) {
    if (tasks.isEmpty) {
      return RefreshIndicator(
        onRefresh: () => ref
            .read(taskListControllerProvider.notifier)
            .refreshTasks(),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(height: 110),
            Icon(
              Icons.task_alt_rounded,
              size: 68,
              color: Color(0xFFCBD5E1),
            ),
            SizedBox(height: 16),
            Center(
              child: Text(
                'No tasks found',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF334155),
                ),
              ),
            ),
            SizedBox(height: 8),
            Center(
              child: Text(
                'Try changing your filters or search.',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref
          .read(taskListControllerProvider.notifier)
          .refreshTasks(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: tasks.length,
        itemBuilder: (context, index) {
          return _buildTaskCard(tasks[index]);
        },
      ),
    );
  }

  // ============================================================
  // TASK CARD
  // ============================================================

  Widget _buildTaskCard(TaskModel task) {
    final priorityColor = _priorityColor(task.priority);
    final statusColor = _statusColor(task.status);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFE8ECF2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.025),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _openTaskDetails(task),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(alpha: 0.09),
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: const Icon(
                      Icons.task_alt_rounded,
                      color: primaryColor,
                      size: 23,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          task.name,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF172033),
                          ),
                        ),
                        if (task.description != null &&
                            task.description!.trim().isNotEmpty) ...[
                          const SizedBox(height: 5),
                          Text(
                            task.description!,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: Colors.grey,
                  ),
                ],
              ),
              const SizedBox(height: 15),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildBadge(
                    task.priority.toUpperCase(),
                    priorityColor,
                  ),
                  _buildBadge(
                    task.status.toUpperCase(),
                    statusColor,
                  ),
                  if (task.category != null)
                    _buildBadge(
                      task.category!.name,
                      primaryColor,
                    ),
                ],
              ),
              const SizedBox(height: 14),
              const Divider(
                height: 1,
                color: Color(0xFFEDF0F5),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(
                    Icons.calendar_today_outlined,
                    size: 15,
                    color: Colors.grey,
                  ),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      _formatDate(task.scheduledAt),
                      style: TextStyle(
                        fontSize: 12,
                        color: task.isOverdue
                            ? Colors.red
                            : Colors.grey.shade700,
                        fontWeight: task.isOverdue
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                  if (task.assignment?.assignedTo?.name != null) ...[
                    const Icon(
                      Icons.person_outline_rounded,
                      size: 16,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        task.assignment!.assignedTo!.name!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              if (task.entity?.name != null &&
                  task.entity!.name!.trim().isNotEmpty) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(
                      Icons.link_rounded,
                      size: 15,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 7),
                    Expanded(
                      child: Text(
                        '${task.entity!.type ?? 'Related'}: '
                        '${task.entity!.name}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 8),
              const Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'Tap to view details',
                  style: TextStyle(
                    color: primaryColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // BADGE
  // ============================================================

  Widget _buildBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  // ============================================================
  // ERROR STATE
  // ============================================================

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_rounded,
              size: 58,
              color: Colors.redAccent,
            ),
            const SizedBox(height: 16),
            const Text(
              'Unable to load tasks',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                ref
                    .read(taskListControllerProvider.notifier)
                    .refreshTasks();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Try again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // PRIORITY COLORS
  // ============================================================

  Color _priorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'urgent':
        return Colors.red;
      case 'high':
        return Colors.deepOrange;
      case 'medium':
        return Colors.orange.shade800;
      case 'low':
        return Colors.green;
      default:
        return Colors.blueGrey;
    }
  }

  // ============================================================
  // STATUS COLORS
  // ============================================================

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Colors.green;
      case 'overdue':
        return Colors.red;
      case 'cancelled':
        return Colors.grey;
      case 'upcoming':
        return Colors.purple;
      case 'open':
        return primaryColor;
      default:
        return Colors.blueGrey;
    }
  }

  // ============================================================
  // DATE FORMATTING
  // ============================================================

  String _formatDate(DateTime? date) {
    if (date == null) return 'No scheduled date';

    final localDate = date.toLocal();

    final day = localDate.day.toString().padLeft(2, '0');
    final month = localDate.month.toString().padLeft(2, '0');
    final year = localDate.year;

    final hour = localDate.hour % 12 == 0
        ? 12
        : localDate.hour % 12;

    final minute = localDate.minute.toString().padLeft(2, '0');
    final period = localDate.hour >= 12 ? 'PM' : 'AM';

    return '$day/$month/$year  $hour:$minute $period';
  }
}