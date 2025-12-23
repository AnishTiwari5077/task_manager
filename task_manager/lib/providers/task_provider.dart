import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:task_manager/services/api_services.dart';
import 'package:task_manager/services/task_classification_services.dart';
import '../models/task.dart';

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
    error: (_, _) => {
      'pending': 0,
      'in_progress': 0,
      'completed': 0,
      'total': 0,
    },
  );
});

// Task counts by category
final taskCountsByCategoryProvider = Provider<Map<String, int>>((ref) {
  final tasksAsync = ref.watch(tasksProvider);
  return tasksAsync.when(
    data: (tasks) {
      return {
        'scheduling': tasks.where((t) => t.category == 'scheduling').length,
        'finance': tasks.where((t) => t.category == 'finance').length,
        'technical': tasks.where((t) => t.category == 'technical').length,
        'safety': tasks.where((t) => t.category == 'safety').length,
        'general': tasks.where((t) => t.category == 'general').length,
      };
    },
    loading: () => {
      'scheduling': 0,
      'finance': 0,
      'technical': 0,
      'safety': 0,
      'general': 0,
    },
    error: (_, _) => {
      'scheduling': 0,
      'finance': 0,
      'technical': 0,
      'safety': 0,
      'general': 0,
    },
  );
});

// Classification State Provider
class ClassificationState {
  final Map<String, dynamic>? classification;
  final bool isClassifying;
  final String? error;

  ClassificationState({
    this.classification,
    this.isClassifying = false,
    this.error,
  });

  ClassificationState copyWith({
    Map<String, dynamic>? classification,
    bool? isClassifying,
    String? error,
  }) {
    return ClassificationState(
      classification: classification ?? this.classification,
      isClassifying: isClassifying ?? this.isClassifying,
      error: error ?? this.error,
    );
  }
}

// Classification Notifier
class ClassificationNotifier extends StateNotifier<ClassificationState> {
  ClassificationNotifier() : super(ClassificationState());

  /// Classify task content and return classification
  Map<String, dynamic> classifyTask({
    required String title,
    String? description,
  }) {
    state = state.copyWith(isClassifying: true, error: null);

    try {
      final classification = TaskClassificationService.classifyWithConfidence(
        title: title,
        description: description,
      );

      state = state.copyWith(
        classification: classification,
        isClassifying: false,
      );

      return classification;
    } catch (e) {
      state = state.copyWith(isClassifying: false, error: e.toString());

      // Return default classification on error
      return {
        'category': 'general',
        'priority': 'low',
        'extracted_entities': {},
        'suggested_actions': [],
        'confidence': {'category': 0.5, 'priority': 0.5},
      };
    }
  }

  /// Clear classification state
  void clearClassification() {
    state = ClassificationState();
  }
}

final classificationNotifierProvider =
    StateNotifierProvider<ClassificationNotifier, ClassificationState>((ref) {
      return ClassificationNotifier();
    });

// Task Management Notifier
class TaskNotifier extends StateNotifier<AsyncValue<void>> {
  TaskNotifier(this.ref) : super(const AsyncValue.data(null));
  final Ref ref;

  bool get isLoading => state.isLoading;

  Future<void> createTask(Map<String, dynamic> taskData) async {
    state = const AsyncValue.loading();
    try {
      final apiService = ref.read(apiServiceProvider);

      // Auto-classify if category and priority are not provided
      if (!taskData.containsKey('category') ||
          !taskData.containsKey('priority')) {
        final classification = TaskClassificationService.classifyTask(
          title: taskData['title'] ?? '',
          description: taskData['description'],
        );

        // Merge classification with user data
        taskData['category'] =
            taskData['category'] ?? classification['category'];
        taskData['priority'] =
            taskData['priority'] ?? classification['priority'];
        taskData['extracted_entities'] = classification['extracted_entities'];
        taskData['suggested_actions'] = classification['suggested_actions'];
      }

      await apiService.createTask(taskData);
      state = const AsyncValue.data(null);

      // Invalidate tasks to refresh the list
      ref.invalidate(tasksProvider);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow;
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
      rethrow;
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
      rethrow;
    }
  }

  Future<void> updateTaskStatus(String id, String status) async {
    await updateTask(id, {'status': status});
  }

  /// Reclassify an existing task
  Future<void> reclassifyTask(String id) async {
    state = const AsyncValue.loading();
    try {
      final tasksAsync = ref.read(tasksProvider);
      final tasks = tasksAsync.value;

      if (tasks != null) {
        final task = tasks.firstWhere((t) => t.id == id);

        final classification = TaskClassificationService.classifyTask(
          title: task.title,
          description: task.description,
        );

        await updateTask(id, {
          'category': classification['category'],
          'priority': classification['priority'],
          'extracted_entities': classification['extracted_entities'],
          'suggested_actions': classification['suggested_actions'],
        });
      }

      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }
}

final taskNotifierProvider =
    StateNotifierProvider<TaskNotifier, AsyncValue<void>>((ref) {
      return TaskNotifier(ref);
    });
