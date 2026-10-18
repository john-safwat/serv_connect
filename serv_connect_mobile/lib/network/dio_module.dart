import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import 'package:serv_connect_mobile/core/config/app_environment.dart';
import 'package:serv_connect_mobile/network/interceptors/accept_language_interceptor.dart';
import 'package:serv_connect_mobile/network/interceptors/auth_interceptor.dart';
import 'package:serv_connect_mobile/network/interceptors/logging_interceptor.dart';
import 'package:serv_connect_mobile/network/interceptors/refresh_interceptor.dart';

/// Factory for the shared `Dio` HTTP clients (`CLAUDE.md §11 & §15`).
@lazySingleton
class DioModule {
  DioModule(this._env);

  final AppEnvironment _env;

  static const Duration _connectTimeout = Duration(seconds: 15);
  static const Duration _sendTimeout = Duration(seconds: 30);
  static const Duration _receiveTimeout = Duration(seconds: 30);

  Dio refreshClient({required AcceptLanguageInterceptor acceptLanguage}) {
    final dio = _baseClient();
    dio.interceptors.add(acceptLanguage);
    return dio;
  }

  Dio client({
    required AcceptLanguageInterceptor acceptLanguage,
    required AuthInterceptor auth,
    required RefreshInterceptor refresh,
    required LoggingInterceptor logging,
  }) {
    final dio = _baseClient();
    dio.interceptors.addAll(<Interceptor>[
      acceptLanguage,
      auth,
      refresh,
      logging,
    ]);
    return dio;
  }

  Dio _baseClient() {
    return Dio(
      BaseOptions(
        baseUrl: _env.apiBaseUrl,
        connectTimeout: _connectTimeout,
        sendTimeout: _sendTimeout,
        receiveTimeout: _receiveTimeout,
        headers: const <String, String>{
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      ),
    );
  }
}
