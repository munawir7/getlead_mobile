import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'task_model.dart';
import 'tasks_repository.dart';

final taskListControllerProvider =
    AsyncNotifierProvider<TaskListController, List<TaskModel>>(
  TaskListController.new,
);

class TaskListController extends AsyncNotifier<List<TaskModel>> {
  late TasksRepository _repository;

  String _status = 'all';
  String _search = '';

  @override
  Future<List<TaskModel>> build() async {
    _repository = ref.read(tasksRepositoryProvider);

    final page = await _repository.getGeneralTasks(
      status: _status,
      search: _search,
    );

    return page.tasks;
  }

  // Refresh the task list.
  Future<void> refreshTasks() async {
    state = const AsyncLoading();

    state = await AsyncValue.guard(() async {
      final page = await _repository.getGeneralTasks(
        status: _status,
        search: _search,
      );

      return page.tasks;
    });
  }

  // Filter tasks by status.
  Future<void> filterByStatus(String status) async {
    _status = status;
    await refreshTasks();
  }

  // Search tasks.
  Future<void> searchTasks(String query) async {
    _search = query;
    await refreshTasks();
  }
}