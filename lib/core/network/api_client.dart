import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'api_endpoints.dart';
import 'network_constants.dart';
import 'interceptors/trace_interceptor.dart';
import 'interceptors/logging_interceptor.dart';
import 'interceptors/retry_interceptor.dart';
import 'interceptors/auth_interceptor.dart';
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
      LoggingInterceptor(),
      ConnectivityInterceptor(),
    ]);
  }

  Future<Response> get(String path, {Map<String, dynamic>? queryParameters}) async {
    return _dio.get(path, queryParameters: queryParameters);
  }

  Future<Response> post(String path, {dynamic data}) async {
    return _dio.post(path, data: data);
  }
}
