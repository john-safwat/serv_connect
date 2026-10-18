import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import 'package:__PKG__/core/services/app_event_bus.dart';
import 'package:__PKG__/core/storage/secure_storage.dart';
import 'package:__PKG__/network/dio_module.dart';
import 'package:__PKG__/network/interceptors/auth_interceptor.dart';
import 'package:__PKG__/network/interceptors/logging_interceptor.dart';
import 'package:__PKG__/network/interceptors/refresh_interceptor.dart';

/// Wires the two `Dio` instances + [RefreshInterceptor]. The refresh callback
/// hits `POST /auth/refresh-token` on the bare client directly (no
/// [RefreshInterceptor] attached → no recursion). It deliberately does not
/// depend on any repository, to avoid a dependency cycle.
@module
abstract class NetworkModule {
  @Named('refresh')
  @lazySingleton
  Dio refreshDio(DioModule mod) => mod.refreshClient();

  @lazySingleton
  RefreshInterceptor refreshInterceptor(
    @Named('refresh') Dio bare,
    SecureStorage secureStorage,
    AppEventBus eventBus,
  ) => RefreshInterceptor(
    bareClient: bare,
    secureStorage: secureStorage,
    eventBus: eventBus,
    refreshCall: _refreshCall,
  );

  @Named('main')
  @lazySingleton
  Dio mainDio(
    DioModule mod,
    AuthInterceptor auth,
    RefreshInterceptor refresh,
    LoggingInterceptor logging,
  ) => mod.client(auth: auth, refresh: refresh, logging: logging);
}

/// Direct `POST /auth/refresh-token` call. Returns the new token pair or
/// throws — [RefreshInterceptor] wraps the throw into a `ForceLogout` event.
Future<TokenPair> _refreshCall(Dio dio, String refreshToken) async {
  final response = await dio.post<Map<String, dynamic>>(
    '/auth/refresh-token',
    data: {'refreshToken': refreshToken},
  );
  final data = response.data;
  final access = data?['accessToken'] as String?;
  final refresh = data?['refreshToken'] as String?;
  if (access == null || refresh == null) {
    throw DioException(
      requestOptions: response.requestOptions,
      response: response,
      message: 'Refresh response missing accessToken/refreshToken',
    );
  }
  return TokenPair(access: access, refresh: refresh);
}
