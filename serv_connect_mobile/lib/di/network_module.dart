import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import 'package:serv_connect_mobile/core/services/auth_session.dart';
import 'package:serv_connect_mobile/core/storage/secure_storage.dart';
import 'package:serv_connect_mobile/network/dio_module.dart';
import 'package:serv_connect_mobile/network/interceptors/accept_language_interceptor.dart';
import 'package:serv_connect_mobile/network/interceptors/auth_interceptor.dart';
import 'package:serv_connect_mobile/network/interceptors/logging_interceptor.dart';
import 'package:serv_connect_mobile/network/interceptors/refresh_interceptor.dart';

/// Wires the shared `Dio` instances (`@Named('main')` and `@Named('refresh')`)
/// and the `RefreshInterceptor` (`CLAUDE.md §15`).
@module
abstract class NetworkModule {
  @Named('refresh')
  @lazySingleton
  Dio refreshDio(
    DioModule mod,
    AcceptLanguageInterceptor acceptLanguage,
  ) => mod.refreshClient(acceptLanguage: acceptLanguage);

  @lazySingleton
  RefreshInterceptor refreshInterceptor(
    @Named('refresh') Dio bareClient,
    SecureStorage secureStorage,
    AuthSession authSession,
  ) => RefreshInterceptor(
    bareClient: bareClient,
    secureStorage: secureStorage,
    authSession: authSession,
    refreshCall: _refreshTokenOnServer,
  );

  @Named('main')
  @lazySingleton
  Dio mainDio(
    DioModule mod,
    AcceptLanguageInterceptor acceptLanguage,
    AuthInterceptor auth,
    RefreshInterceptor refresh,
    LoggingInterceptor logging,
  ) => mod.client(
    acceptLanguage: acceptLanguage,
    auth: auth,
    refresh: refresh,
    logging: logging,
  );
}

Future<TokenPair> _refreshTokenOnServer(Dio dio, String refreshToken) async {
  final response = await dio.post<Map<String, dynamic>>(
    '/api/v1/auth/refresh',
    data: <String, dynamic>{'refreshToken': refreshToken},
  );
  final envelope = response.data;
  final data = envelope?['data'] is Map<String, dynamic>
      ? envelope!['data'] as Map<String, dynamic>
      : envelope;
  final access = data?['accessToken'] as String?;
  final refresh = data?['refreshToken'] as String?;
  if (access == null || refresh == null) {
    throw DioException(
      requestOptions: response.requestOptions,
      response: response,
      message: 'Refresh response missing accessToken or refreshToken',
    );
  }
  return TokenPair(accessToken: access, refreshToken: refresh);
}
