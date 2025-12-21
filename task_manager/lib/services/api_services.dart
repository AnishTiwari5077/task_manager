import 'package:dio/dio.dart';
import '../models/task.dart';

class ApiService {
  late final Dio _dio;

  // Replace with your Render deployment URL
  static const String baseUrl = 'https://your-app.onrender.com';

  ApiService() {
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        headers: {'Content-Type': 'application/json'},
      ),
    );

    // Add interceptors
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          print('REQUEST[${options.method}] => PATH: ${options.path}');
          return handler.next(options);
        },
        onResponse: (response, handler) {
          print('RESPONSE[${response.statusCode}] => DATA: ${response.data}');
          return handler.next(response);
        },
        onError: (DioException error, handler) {
          print(
            'ERROR[${error.response?.statusCode}] => MESSAGE: ${error.message}',
          );
          return handler.next(error);
        },
      ),
    );
  }

  // Create a new task
  Future<Map<String, dynamic>> createTask(Map<String, dynamic> taskData) async {
    try {
      final response = await _dio.post('/api/tasks', data: taskData);
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Get all tasks with filters
  Future<List<Task>> getTasks({
    String? status,
    String? category,
    String? priority,
    String? search,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final queryParams = <String, dynamic>{'limit': limit, 'offset': offset};

      if (status != null) queryParams['status'] = status;
      if (category != null) queryParams['category'] = category;
      if (priority != null) queryParams['priority'] = priority;
      if (search != null && search.isNotEmpty) queryParams['search'] = search;

      final response = await _dio.get(
        '/api/tasks',
        queryParameters: queryParams,
      );

      final List<dynamic> tasksJson = response.data['data'];
      return tasksJson.map((json) => Task.fromJson(json)).toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Get single task by ID
  Future<Task> getTask(String id) async {
    try {
      final response = await _dio.get('/api/tasks/$id');
      return Task.fromJson(response.data['data']);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Update a task
  Future<Task> updateTask(String id, Map<String, dynamic> updates) async {
    try {
      final response = await _dio.patch('/api/tasks/$id', data: updates);
      return Task.fromJson(response.data['data']);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Delete a task
  Future<void> deleteTask(String id) async {
    try {
      await _dio.delete('/api/tasks/$id');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Check API health
  Future<bool> checkHealth() async {
    try {
      final response = await _dio.get('/health');
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  String _handleError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Connection timeout. Please check your internet connection.';
      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        final message =
            error.response?.data['error'] ?? 'Unknown error occurred';
        return 'Error ($statusCode): $message';
      case DioExceptionType.cancel:
        return 'Request was cancelled';
      default:
        return 'Network error. Please check your connection.';
    }
  }
}
