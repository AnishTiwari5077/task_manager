import 'package:dio/dio.dart';
import '../models/task.dart';

class ApiService {
  late final Dio _dio;

  static const String baseUrl = 'https://task-manager1-owu7.onrender.com';

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

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) => handler.next(options),
        onResponse: (response, handler) => handler.next(response),
        onError: (error, handler) => handler.next(error),
      ),
    );
  }

  Future<Map<String, dynamic>> createTask(Map<String, dynamic> taskData) async {
    try {
      final formattedData = _formatTaskData(taskData);
      final response = await _dio.post('/api/tasks', data: formattedData);

      if (response.data is Map<String, dynamic>) {
        final data = response.data as Map<String, dynamic>;
        if (data.containsKey('success') && data['data'] != null) {
          return data['data'] as Map<String, dynamic>;
        }
        return data;
      }
      throw Exception('Invalid response format');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<List<Task>> getTasks({
    String? status,
    String? category,
    String? priority,
    String? search,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final params = <String, dynamic>{'limit': limit, 'offset': offset};

      if (status != null) params['status'] = status;
      if (category != null) params['category'] = category;
      if (priority != null) params['priority'] = priority;
      if (search != null && search.isNotEmpty) params['search'] = search;

      final response = await _dio.get('/api/tasks', queryParameters: params);

      if (response.data is Map<String, dynamic>) {
        final data = response.data as Map<String, dynamic>;
        if (data['success'] == true && data['data'] is List) {
          return (data['data'] as List)
              .map((e) => Task.fromJson(e as Map<String, dynamic>))
              .toList();
        }
      }

      throw Exception('Invalid response format');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Task> getTask(String id) async {
    try {
      final response = await _dio.get('/api/tasks/$id');

      if (response.data is Map<String, dynamic>) {
        final data = response.data as Map<String, dynamic>;
        if (data['success'] == true && data['data'] is Map) {
          return Task.fromJson(data['data'] as Map<String, dynamic>);
        }
      }

      throw Exception('Invalid response format');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Task> updateTask(String id, Map<String, dynamic> updates) async {
    try {
      final formattedData = _formatTaskData(updates);
      final response = await _dio.patch('/api/tasks/$id', data: formattedData);

      if (response.data is Map<String, dynamic>) {
        final data = response.data as Map<String, dynamic>;
        if (data['success'] == true && data['data'] is Map) {
          return Task.fromJson(data['data'] as Map<String, dynamic>);
        }
      }

      throw Exception('Invalid response format');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> deleteTask(String id) async {
    try {
      await _dio.delete('/api/tasks/$id');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> getTaskStatistics() async {
    try {
      final response = await _dio.get('/api/tasks/statistics');

      if (response.data is Map<String, dynamic>) {
        final data = response.data as Map<String, dynamic>;
        if (data['success'] == true && data['data'] is Map) {
          return data['data'] as Map<String, dynamic>;
        }
      }

      throw Exception('Invalid response format');
    } on DioException catch (_) {
      return {};
    }
  }

  Future<bool> checkHealth() async {
    try {
      final response = await _dio.get('/health');
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Map<String, dynamic> _formatTaskData(Map<String, dynamic> taskData) {
    final formatted = Map<String, dynamic>.from(taskData);

    if (formatted['extracted_entities'] is Map) {
      formatted['extracted_entities'] = Map<String, dynamic>.from(
        formatted['extracted_entities'],
      );
    }

    if (formatted['suggested_actions'] is List) {
      formatted['suggested_actions'] = List<String>.from(
        formatted['suggested_actions'].map((e) => e.toString()),
      );
    }

    formatted.removeWhere((_, v) => v == null);
    return formatted;
  }

  String _handleError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Connection timeout. Please check your internet connection.';

      case DioExceptionType.badResponse:
        final status = error.response?.statusCode;
        if (error.response?.data is Map) {
          final data = error.response?.data as Map;
          return 'Error ($status): ${data['error'] ?? data['message'] ?? 'Unknown error'}';
        }
        return 'Server error ($status). Please try again.';

      case DioExceptionType.cancel:
        return 'Request was cancelled';

      case DioExceptionType.connectionError:
        return 'Connection error. Please check the server.';

      default:
        return 'Network error';
    }
  }
}
