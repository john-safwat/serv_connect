import 'package:dio/dio.dart';
import 'package:serv_connect_mobile/core/services/auth_session.dart';
import 'package:serv_connect_mobile/core/storage/secure_storage.dart';
import 'package:serv_connect_mobile/core/storage/storage_keys.dart';
import 'package:synchronized/synchronized.dart';

class TokenPair {
  const TokenPair({required this.accessToken, required this.refreshToken});
  final String accessToken;
  final String refreshToken;
}

typedef TokenRefreshCall = Future<TokenPair> Function(
  Dio bareDio,
  String refreshToken,
);

/// Serialises concurrent HTTP `401` token refreshes with a [Lock] and enforces
/// the `FR-1.3` offline session grace window (`CLAUDE.md §15`).
class RefreshInterceptor extends Interceptor {
  RefreshInterceptor({
    required Dio bareClient,
    required SecureStorage secureStorage,
    required AuthSession authSession,
    required TokenRefreshCall refreshCall,
  }) : _bare = bareClient,
       _secure = secureStorage,
       _session = authSession,
       _refresh = refreshCall;

  final Dio _bare;
  final SecureStorage _secure;
  final AuthSession _session;
  final TokenRefreshCall _refresh;
  final Lock _lock = Lock();

  static const List<String> _excludedPaths = <String>[
    '/api/v1/auth/login',
    '/api/v1/auth/refresh',
    '/api/v1/auth/logout',
  ];

  static bool isExcluded(String path) => _excludedPaths.any(path.contains);

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final status = err.response?.statusCode;
    if (status != 401 || isExcluded(err.requestOptions.path)) {
      handler.next(err);
      return;
    }
    final requestToken = _extractBearer(
      err.requestOptions.headers['Authorization'],
    );
    try {
      final rotatedToken = await _rotateOrReuseToken(requestToken);
      if (rotatedToken == null || rotatedToken.isEmpty) {
        await _session.signOut(forceLogout: true);
        handler.next(err);
        return;
      }
      final response = await _retryRequest(err.requestOptions, rotatedToken);
      handler.resolve(response);
    } on DioException catch (refreshError) {
      await _handleRefreshFailure(refreshError);
      handler.next(err);
    }
  }

  Future<String?> _rotateOrReuseToken(String? requestToken) {
    return _lock.synchronized<String?>(() async {
      final current = await _secure.read(StorageKey.accessToken);
      if (current != null && current.isNotEmpty && current != requestToken) {
        return current;
      }
      final refresh = await _secure.read(StorageKey.refreshToken);
      if (refresh == null || refresh.isEmpty) return null;
      final pair = await _refresh(_bare, refresh);
      await _session.updateTokens(
        accessToken: pair.accessToken,
        refreshToken: pair.refreshToken,
      );
      return pair.accessToken;
    });
  }

  Future<void> _handleRefreshFailure(DioException error) async {
    final statusCode = error.response?.statusCode;
    if (statusCode == 401) {
      await _session.signOut(forceLogout: true);
      return;
    }
    await _session.handleOfflineRefreshFailure();
  }

  Future<Response<dynamic>> _retryRequest(
    RequestOptions original,
    String newToken,
  ) {
    final headers = <String, dynamic>{
      ...original.headers,
      'Authorization': 'Bearer $newToken',
    };
    return _bare.request<dynamic>(
      original.path,
      data: original.data,
      queryParameters: original.queryParameters,
      options: Options(method: original.method, headers: headers),
      cancelToken: original.cancelToken,
    );
  }

  String? _extractBearer(Object? header) {
    if (header is String && header.startsWith('Bearer ')) {
      return header.substring('Bearer '.length);
    }
    return null;
  }
}
