import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import 'package:__PKG__/core/storage/secure_storage.dart';
import 'package:__PKG__/core/storage/storage_keys.dart';

/// Attaches `Authorization: Bearer <accessToken>` from [SecureStorage] to
/// every outbound request, except the whitelisted public paths.
@lazySingleton
class AuthInterceptor extends Interceptor {
  AuthInterceptor({required SecureStorage secureStorage})
    : _secureStorage = secureStorage;

  final SecureStorage _secureStorage;

  static const _whitelist = <String>[
    '/auth/login',
    '/auth/refresh-token',
    '/auth/forgot-password',
  ];

  static bool isWhitelisted(String path) => _whitelist.any(path.contains);

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (!isWhitelisted(options.path)) {
      final token = await _secureStorage.read(StorageKey.accessToken);
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }
    handler.next(options);
  }
}
