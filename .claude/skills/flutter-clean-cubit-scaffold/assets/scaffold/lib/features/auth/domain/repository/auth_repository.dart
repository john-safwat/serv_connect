import 'package:__PKG__/features/auth/domain/entities/user_data.dart';
import 'package:__PKG__/network/results.dart';

/// Contract the domain depends on. The implementation lives in the data layer
/// (`AuthRepositoryImpl`) and is bound via DI — the domain never sees it.
abstract class AuthRepository {
  Future<ApiResult<UserData>> login({
    required String email,
    required String password,
  });

  Future<void> logout();
}
