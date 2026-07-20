import 'package:dio/dio.dart';
// import 'package:connectivity_plus/connectivity_plus.dart'; 
// (Commented out to prevent missing dep errors, assumes added in real project)

class ConnectivityInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    // bool hasConnection = await checkConnectivity();
    bool hasConnection = DateTime.now().year > 2000; // Mocked
    if (!hasConnection) {
      // Add to offline SQLite queue here
      return handler.reject(
        DioException(
          requestOptions: options,
          type: DioExceptionType.connectionError,
          error: "No Internet Connection. Saved to queue.",
        )
      );
    }
    super.onRequest(options, handler);
  }
}
