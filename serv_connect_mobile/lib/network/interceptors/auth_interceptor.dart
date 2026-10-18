import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import 'package:serv_connect_mobile/core/storage/secure_storage.dart';
import 'package:serv_connect_mobile/core/storage/storage_keys.dart';

/// Attaches `Authorization: Bearer <accessToken>` from [SecureStorage] to
/// non-public endpoints (`CLAUDE.md §15`).
@lazySingleton
class AuthInterceptor extends Interceptor {
  AuthInterceptor(this._secureStorage);

  final SecureStorage _secureStorage;

  static const List<String> _publicPaths = <String>[
    '/api/v1/auth/login',
    '/api/v1/auth/otp/verify',
    '/api/v1/auth/otp/resend',
    '/api/v1/auth/refresh',
    '/api/v1/auth/invitations/accept',
  ];

  static bool isPublicPath(String path) => _publicPaths.any(path.contains);

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (!isPublicPath(options.path)) {
      final token = await _secureStorage.read(StorageKey.accessToken);
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }
    handler.next(options);
  }
}
