import 'package:dio/dio.dart';
import '../models/task.dart';

class ApiService {
  late final Dio _dio;

  // Replace with your actual backend URL
  // For local testing: http://10.0.2.2:3000 (Android Emulator)
  // For local testing: http://localhost:3000 (iOS Simulator)
  // For production: https://your-app.onrender.com
  // static const String baseUrl = 'http://localhost:3000'; // Change this!
  static const String baseUrl = 'http://10.0.2.2:3000';

  ApiService() {
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // Add interceptors
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          print('🚀 REQUEST[${options.method}] => PATH: ${options.path}');
          print('📦 DATA: ${options.data}');
          return handler.next(options);
        },
        onResponse: (response, handler) {
          print(
            '✅ RESPONSE[${response.statusCode}] => PATH: ${response.requestOptions.path}',
          );
          print('📥 DATA: ${response.data}');
          return handler.next(response);
        },
        onError: (DioException error, handler) {
          print(
            '❌ ERROR[${error.response?.statusCode}] => PATH: ${error.requestOptions.path}',
          );
          print('💥 MESSAGE: ${error.message}');
          print('📄 RESPONSE: ${error.response?.data}');
          return handler.next(error);
        },
      ),
    );
  }

  // Create a new task
  Future<Map<String, dynamic>> createTask(Map<String, dynamic> taskData) async {
    try {
      print('Creating task with data: $taskData');
      final response = await _dio.post('/api/tasks', data: taskData);

      if (response.data is Map<String, dynamic>) {
        return response.data as Map<String, dynamic>;
      }
      throw Exception('Invalid response format');
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

      print('Fetching tasks with params: $queryParams');
      final response = await _dio.get(
        '/api/tasks',
        queryParameters: queryParams,
      );

      // Check if response has the expected structure
      if (response.data is Map<String, dynamic>) {
        final responseData = response.data as Map<String, dynamic>;

        if (responseData['success'] == true && responseData['data'] is List) {
          final List<dynamic> tasksJson = responseData['data'] as List;
          print('Parsing ${tasksJson.length} tasks');

          return tasksJson.map((json) {
            try {
              return Task.fromJson(json as Map<String, dynamic>);
            } catch (e) {
              print('Error parsing task: $e');
              print('Task JSON: $json');
              rethrow;
            }
          }).toList();
        }
      }

      throw Exception('Invalid response format from server');
    } on DioException catch (e) {
      throw _handleError(e);
    } catch (e) {
      print('Unexpected error in getTasks: $e');
      rethrow;
    }
  }

  // Get single task by ID
  Future<Task> getTask(String id) async {
    try {
      final response = await _dio.get('/api/tasks/$id');

      if (response.data is Map<String, dynamic>) {
        final responseData = response.data as Map<String, dynamic>;

        if (responseData['success'] == true && responseData['data'] is Map) {
          return Task.fromJson(responseData['data'] as Map<String, dynamic>);
        }
      }

      throw Exception('Invalid response format');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Update a task
  Future<Task> updateTask(String id, Map<String, dynamic> updates) async {
    try {
      print('Updating task $id with: $updates');
      final response = await _dio.patch('/api/tasks/$id', data: updates);

      if (response.data is Map<String, dynamic>) {
        final responseData = response.data as Map<String, dynamic>;

        if (responseData['success'] == true && responseData['data'] is Map) {
          return Task.fromJson(responseData['data'] as Map<String, dynamic>);
        }
      }

      throw Exception('Invalid response format');
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
      print('Health check failed: $e');
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

        // Try to extract error message from response
        if (error.response?.data is Map) {
          final data = error.response?.data as Map;
          final message =
              data['error'] ?? data['message'] ?? 'Unknown error occurred';
          return 'Error ($statusCode): $message';
        }

        return 'Server error ($statusCode). Please try again.';

      case DioExceptionType.cancel:
        return 'Request was cancelled';

      case DioExceptionType.connectionError:
        return 'Connection error. Please check if the server is running.';

      default:
        return 'Network error: ${error.message ?? "Unknown error"}';
    }
  }
}
