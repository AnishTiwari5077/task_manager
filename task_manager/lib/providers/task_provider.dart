import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:task_manager/services/api_services.dart';
import '../models/task.dart';

// API Service Provider
final apiServiceProvider = Provider<ApiService>((ref) => ApiService());

// Connectivity Provider
final connectivityProvider = StreamProvider<List<ConnectivityResult>>((ref) {
  return Connectivity().onConnectivityChanged;
});

// Filter State Providers
final statusFilterProvider = StateProvider<String?>((ref) => null);
final categoryFilterProvider = StateProvider<String?>((ref) => null);
final priorityFilterProvider = StateProvider<String?>((ref) => null);
final searchQueryProvider = StateProvider<String>((ref) => '');

// Tasks Provider with auto-refresh
final tasksProvider = FutureProvider.autoDispose<List<Task>>((ref) async {
  final apiService = ref.watch(apiServiceProvider);
  final statusFilter = ref.watch(statusFilterProvider);
  final categoryFilter = ref.watch(categoryFilterProvider);
  final priorityFilter = ref.watch(priorityFilterProvider);
  final searchQuery = ref.watch(searchQueryProvider);

  return apiService.getTasks(
    status: statusFilter,
    category: categoryFilter,
    priority: priorityFilter,
    search: searchQuery.isEmpty ? null : searchQuery,
  );
});

// Task counts by status
final taskCountsProvider = Provider<Map<String, int>>((ref) {
  final tasksAsync = ref.watch(tasksProvider);

  return tasksAsync.when(
    data: (tasks) {
      return {
        'pending': tasks.where((t) => t.status == 'pending').length,
        'in_progress': tasks.where((t) => t.status == 'in_progress').length,
        'completed': tasks.where((t) => t.status == 'completed').length,
        'total': tasks.length,
      };
    },
    loading: () => {'pending': 0, 'in_progress': 0, 'completed': 0, 'total': 0},
    error: (_, __) => {
      'pending': 0,
      'in_progress': 0,
      'completed': 0,
      'total': 0,
    },
  );
});

// Task Management Notifier
class TaskNotifier extends StateNotifier<AsyncValue<void>> {
  TaskNotifier(this.ref) : super(const AsyncValue.data(null));

  final Ref ref;

  Future<void> createTask(Map<String, dynamic> taskData) async {
    state = const AsyncValue.loading();
    try {
      final apiService = ref.read(apiServiceProvider);
      await apiService.createTask(taskData);
      state = const AsyncValue.data(null);
      // Invalidate tasks to refresh the list
      ref.invalidate(tasksProvider);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> updateTask(String id, Map<String, dynamic> updates) async {
    state = const AsyncValue.loading();
    try {
      final apiService = ref.read(apiServiceProvider);
      await apiService.updateTask(id, updates);
      state = const AsyncValue.data(null);
      ref.invalidate(tasksProvider);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> deleteTask(String id) async {
    state = const AsyncValue.loading();
    try {
      final apiService = ref.read(apiServiceProvider);
      await apiService.deleteTask(id);
      state = const AsyncValue.data(null);
      ref.invalidate(tasksProvider);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> updateTaskStatus(String id, String status) async {
    await updateTask(id, {'status': status});
  }
}

final taskNotifierProvider =
    StateNotifierProvider<TaskNotifier, AsyncValue<void>>((ref) {
      return TaskNotifier(ref);
    });
