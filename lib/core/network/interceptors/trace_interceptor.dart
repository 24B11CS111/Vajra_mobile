import 'dart:io';
import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';

class TraceInterceptor extends Interceptor {
  final _uuid = const Uuid();

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.headers['X-Request-ID'] = _uuid.v4();
    options.headers['X-Trace-ID'] = _uuid.v4();
    options.headers['X-Platform'] = Platform.operatingSystem;
    options.headers['X-App-Version'] = '1.0.0+1'; // In production, read from package_info
    super.onRequest(options, handler);
  }
}
