import 'package:dio/dio.dart';

class ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    String userFriendlyMessage;

    switch (err.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        userFriendlyMessage = "Request timed out. Please check your internet connection and try again.";
        break;
      case DioExceptionType.connectionError:
        userFriendlyMessage = "You're offline. VAJRA can't reach the server right now. Your saved information remains available.";
        break;
      case DioExceptionType.badResponse:
        final statusCode = err.response?.statusCode;
        if (statusCode == 401) {
          userFriendlyMessage = "Session expired or invalid. Please sign in again.";
        } else if (statusCode == 403) {
          userFriendlyMessage = "You don't have permission to perform this action.";
        } else if (statusCode == 404) {
          userFriendlyMessage = "Requested resource was not found.";
        } else if (statusCode != null && statusCode >= 500) {
          userFriendlyMessage = "VAJRA service is currently undergoing maintenance. Please try again shortly.";
        } else {
          final data = err.response?.data;
          if (data is Map && data.containsKey('detail')) {
            userFriendlyMessage = data['detail'].toString();
          } else {
            userFriendlyMessage = "Something went wrong. Please try again.";
          }
        }
        break;
      case DioExceptionType.cancel:
        userFriendlyMessage = "Request was cancelled.";
        break;
      case DioExceptionType.unknown:
      default:
        userFriendlyMessage = "Network error. Please check your connection.";
        break;
    }

    final customizedError = DioException(
      requestOptions: err.requestOptions,
      response: err.response,
      type: err.type,
      error: userFriendlyMessage,
      message: userFriendlyMessage,
    );

    super.onError(customizedError, handler);
  }
}
