import 'package:injectable/injectable.dart';
import 'package:__PKG__/features/auth/domain/entities/user_data.dart';
import 'package:__PKG__/features/auth/domain/repository/auth_repository.dart';
import 'package:__PKG__/network/results.dart';

/// One verb-noun class, one public `call` method so `useCase(...)` works.
@injectable
class LoginUseCase {
  const LoginUseCase(this._repository);

  final AuthRepository _repository;

  Future<ApiResult<UserData>> call({
    required String email,
    required String password,
  }) => _repository.login(email: email, password: password);
}
