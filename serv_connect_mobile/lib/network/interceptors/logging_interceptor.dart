import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import 'package:serv_connect_mobile/core/logger/app_logger.dart';

/// PII-safe network logging interceptor (`CLAUDE.md §7 & §16.3`).
///
/// Logs ONLY the HTTP method, request path, and status code — never request or
/// response headers, query parameters, or bodies.
@lazySingleton
class LoggingInterceptor extends Interceptor {
  LoggingInterceptor(this._logger);

  final AppLogger _logger;

  static String _safePath(String rawPath) => rawPath.split('?').first;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    _logger.d('--> ${options.method} ${_safePath(options.path)}');
    handler.next(options);
  }

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    final path = _safePath(response.requestOptions.path);
    _logger.i(
      '<-- ${response.statusCode} ${response.requestOptions.method} $path',
    );
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final status = err.response?.statusCode ?? 'NO_STATUS';
    final path = _safePath(err.requestOptions.path);
    _logger.w('<-- ERR $status ${err.requestOptions.method} $path');
    handler.next(err);
  }
}
