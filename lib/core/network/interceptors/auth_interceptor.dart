import 'package:dio/dio.dart';
import '../../services/secure_storage_service.dart';

class AuthInterceptor extends QueuedInterceptor {
  final SecureStorageService storage;

  AuthInterceptor(this.storage);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    if (options.path.contains('/auth/login') ||
        options.path.contains('/auth/social') ||
        options.path.contains('/auth/signup')) {
      return handler.next(options);
    }
    
    // Attach existing token if present
    if (!options.headers.containsKey('Authorization')) {
      final token = await storage.getToken();
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }
    handler.next(options);
  }
  
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401 && !err.requestOptions.path.contains('/auth/')) {
      // Session expired or invalid on remote backend - clear stale token
      await storage.deleteToken();
    }
    super.onError(err, handler);
  }
}
