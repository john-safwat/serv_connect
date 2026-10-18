import 'package:injectable/injectable.dart';
import 'package:__PKG__/core/services/auth_session.dart';
import 'package:__PKG__/core/storage/preferences.dart';
import 'package:__PKG__/core/storage/storage_keys.dart';
import 'package:__PKG__/features/auth/data/datasource/remote/auth_remote_data_source.dart';
import 'package:__PKG__/features/auth/data/mapper/auth_mapper.dart';
import 'package:__PKG__/features/auth/data/model/login_request.dart';
import 'package:__PKG__/features/auth/domain/entities/user_data.dart';
import 'package:__PKG__/features/auth/domain/repository/auth_repository.dart';
import 'package:__PKG__/network/results.dart';
import 'package:__PKG__/network/safe_call.dart';

/// Wraps every remote call in [safeCall] so thrown exceptions become
/// [Failure]. Owns token persistence via [AuthSession] — cubits and use cases
/// never touch storage directly.
@LazySingleton(as: AuthRepository)
class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(
    this._remote,
    this._mapper,
    this._authSession,
    this._preferences,
  );

  final AuthRemoteDataSource _remote;
  final AuthMapper _mapper;
  final AuthSession _authSession;
  final Preferences _preferences;

  @override
  Future<ApiResult<UserData>> login({
    required String email,
    required String password,
  }) {
    return safeCall(() async {
      final deviceToken = _preferences.getString(StorageKey.deviceToken);
      final response = await _remote.login(
        LoginRequest(
          email: email,
          password: password,
          deviceToken: deviceToken,
        ),
      );
      final user = _mapper.toUserData(response);
      await _authSession.signIn(
        accessToken: response.accessToken ?? '',
        refreshToken: response.refreshToken ?? '',
        userJson: _mapper.toUserJson(user),
      );
      return user;
    });
  }

  @override
  Future<void> logout() => _authSession.signOut();
}
