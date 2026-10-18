import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:injectable/injectable.dart';
import 'package:__PKG__/core/config/app_environment.dart';
import 'package:__PKG__/network/interceptors/auth_interceptor.dart';
import 'package:__PKG__/network/interceptors/logging_interceptor.dart';
import 'package:__PKG__/network/interceptors/refresh_interceptor.dart';

/// Builds the two `Dio` instances the app needs:
///
/// - [client] — the main instance with auth + refresh + logging interceptors.
/// - [refreshClient] — a bare instance for the refresh-token call only (no
///   [RefreshInterceptor] attached → avoids recursion).
@lazySingleton
class DioModule {
  DioModule(this._env);

  final AppEnvironment _env;

  static const _connectTimeout = Duration(seconds: 15);
  static const _writeTimeout = Duration(seconds: 30);
  static const _readTimeout = Duration(seconds: 30);

  Dio refreshClient() => _baseClient();

  Dio client({
    required AuthInterceptor auth,
    required RefreshInterceptor refresh,
    required LoggingInterceptor logging,
  }) {
    final dio = _baseClient();
    dio.interceptors.add(auth);
    dio.interceptors.add(refresh);
    final pretty = logging.build();
    if (pretty != null) dio.interceptors.add(pretty);
    return dio;
  }

  Dio _baseClient() {
    final dio = Dio(
      BaseOptions(
        baseUrl: _env.baseUrl,
        connectTimeout: _connectTimeout,
        sendTimeout: _writeTimeout,
        receiveTimeout: _readTimeout,
        headers: {'Accept': 'application/json'},
      ),
    );
    if (!_env.isProduction) {
      // Allow self-signed certs on non-prod servers only. Never on prod.
      final adapter = dio.httpClientAdapter;
      if (adapter is IOHttpClientAdapter) {
        adapter.createHttpClient = () =>
            HttpClient()..badCertificateCallback = (_, _, _) => true;
      }
    }
    return dio;
  }
}
