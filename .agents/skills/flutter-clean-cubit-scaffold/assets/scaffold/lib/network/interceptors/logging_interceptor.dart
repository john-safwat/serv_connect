import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import 'package:__PKG__/core/config/app_environment.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';

/// Pretty request/response logging on non-production flavors only. Returns
/// `null` on prod so the interceptor is never attached (see [DioModule]).
@lazySingleton
class LoggingInterceptor {
  LoggingInterceptor(this._env);

  final AppEnvironment _env;

  Interceptor? build() {
    if (_env.isProduction) return null;
    return PrettyDioLogger(
      requestHeader: true,
      requestBody: true,
      responseBody: true,
      compact: true,
    );
  }
}
