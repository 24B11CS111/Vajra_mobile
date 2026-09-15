import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'api_endpoints.dart';
import 'network_constants.dart';
import 'interceptors/trace_interceptor.dart';
import 'interceptors/logging_interceptor.dart';
import 'interceptors/retry_interceptor.dart';
import 'interceptors/auth_interceptor.dart';
import 'interceptors/error_interceptor.dart';
import 'interceptors/connectivity_interceptor.dart';
import '../services/secure_storage_service.dart';

final apiClientProvider = Provider<ApiClient>((ref) {
  final storage = ref.watch(secureStorageProvider);
  return ApiClient(storage);
});

class ApiClient {
  late final Dio _dio;
  
  // Public getter to allow SSE implementations to reuse the configured Dio instance
  Dio get dio => _dio; 

  ApiClient(SecureStorageService storage) {
    _dio = Dio(BaseOptions(
      baseUrl: ApiEndpoints.baseUrl,
      connectTimeout: const Duration(milliseconds: NetworkConstants.connectTimeout),
      receiveTimeout: const Duration(milliseconds: NetworkConstants.receiveTimeout),
      contentType: 'application/json',
    ));

    _dio.interceptors.addAll([
      TraceInterceptor(),
      AuthInterceptor(storage),
      RetryInterceptor(dio: _dio),
      ErrorInterceptor(),
      LoggingInterceptor(),
      ConnectivityInterceptor(),
    ]);
  }

  Future<Response> get(String path, {Map<String, dynamic>? queryParameters, Options? options}) async {
    return _dio.get(path, queryParameters: queryParameters, options: options);
  }

  Future<Response> post(String path, {dynamic data, Map<String, dynamic>? queryParameters, Options? options}) async {
    return _dio.post(path, data: data, queryParameters: queryParameters, options: options);
  }

  Future<Response> put(String path, {dynamic data, Map<String, dynamic>? queryParameters, Options? options}) async {
    return _dio.put(path, data: data, queryParameters: queryParameters, options: options);
  }

  Future<Response> patch(String path, {dynamic data, Map<String, dynamic>? queryParameters, Options? options}) async {
    return _dio.patch(path, data: data, queryParameters: queryParameters, options: options);
  }

  Future<Response> delete(String path, {dynamic data, Map<String, dynamic>? queryParameters, Options? options}) async {
    return _dio.delete(path, data: data, queryParameters: queryParameters, options: options);
  }
}
