import 'package:dio/dio.dart';
import 'package:__PKG__/core/services/app_event_bus.dart';
import 'package:__PKG__/core/storage/secure_storage.dart';
import 'package:__PKG__/core/storage/storage_keys.dart';
import 'package:synchronized/synchronized.dart';

/// Token pair returned by the refresh callback.
class TokenPair {
  const TokenPair({required this.access, required this.refresh});
  final String access;
  final String refresh;
}

typedef TokenRefreshCall =
    Future<TokenPair> Function(Dio dio, String refreshToken);

/// Refreshes the access token on 401 and retries the original request, with a
/// [Lock] so N concurrent 401s trigger at most one refresh call.
///
/// 1. On 401 (only — a 403 is a business error and flows through), wait on the
///    lock.
/// 2. If another in-flight call already refreshed the token, reuse it.
/// 3. Otherwise call [refreshCall] on a bare Dio (no RefreshInterceptor →
///    no recursion), persist the new pair, and retry the original request.
/// 4. If refresh fails, wipe tokens and emit [ForceLogout] on the bus.
class RefreshInterceptor extends Interceptor {
  RefreshInterceptor({
    required Dio bareClient,
    required SecureStorage secureStorage,
    required AppEventBus eventBus,
    required TokenRefreshCall refreshCall,
  }) : _bare = bareClient,
       _secureStorage = secureStorage,
       _eventBus = eventBus,
       _refreshCall = refreshCall;

  final Dio _bare;
  final SecureStorage _secureStorage;
  final AppEventBus _eventBus;
  final TokenRefreshCall _refreshCall;
  final Lock _lock = Lock();

  static const _excludedFromRetry = <String>[
    '/auth/login',
    '/auth/refresh-token',
    '/auth/forgot-password',
    '/auth/logout',
  ];

  static bool isExcludedFromRetry(String path) =>
      _excludedFromRetry.any(path.contains);

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final status = err.response?.statusCode;
    if (status != 401 || isExcludedFromRetry(err.requestOptions.path)) {
      handler.next(err);
      return;
    }

    final tokenAtRequestTime = _bearerOf(
      err.requestOptions.headers['Authorization'],
    );

    String? newToken;
    try {
      newToken = await _lock.synchronized<String?>(() async {
        final current = await _secureStorage.read(StorageKey.accessToken);
        if (current != null &&
            current.isNotEmpty &&
            current != tokenAtRequestTime) {
          return current;
        }
        final refresh = await _secureStorage.read(StorageKey.refreshToken);
        if (refresh == null || refresh.isEmpty) {
          return null;
        }
        final pair = await _refreshCall(_bare, refresh);
        await _secureStorage.write(StorageKey.accessToken, pair.access);
        await _secureStorage.write(StorageKey.refreshToken, pair.refresh);
        return pair.access;
      });
    } on DioException {
      await _forceLogout();
      handler.next(err);
      return;
    }

    if (newToken == null || newToken.isEmpty) {
      await _forceLogout();
      handler.next(err);
      return;
    }

    try {
      final retryOptions = Options(
        method: err.requestOptions.method,
        headers: {
          ...err.requestOptions.headers,
          'Authorization': 'Bearer $newToken',
        },
      );
      final response = await _bare.request<dynamic>(
        err.requestOptions.path,
        data: err.requestOptions.data,
        queryParameters: err.requestOptions.queryParameters,
        options: retryOptions,
        cancelToken: err.requestOptions.cancelToken,
        onReceiveProgress: err.requestOptions.onReceiveProgress,
        onSendProgress: err.requestOptions.onSendProgress,
      );
      handler.resolve(response);
    } on DioException catch (retryError) {
      handler.next(retryError);
    }
  }

  String? _bearerOf(Object? header) {
    if (header is String && header.startsWith('Bearer ')) {
      return header.substring('Bearer '.length);
    }
    return null;
  }

  Future<void> _forceLogout() async {
    await _secureStorage.delete(StorageKey.accessToken);
    await _secureStorage.delete(StorageKey.refreshToken);
    _eventBus.emit(const ForceLogout());
  }
}
