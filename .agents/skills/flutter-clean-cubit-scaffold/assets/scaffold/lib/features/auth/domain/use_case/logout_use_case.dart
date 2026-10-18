import 'package:injectable/injectable.dart';
import 'package:__PKG__/features/auth/domain/repository/auth_repository.dart';

/// Registered in DI so other features (e.g. home) can inject it through their
/// constructor — the sanctioned way to share behaviour across features.
@injectable
class LogoutUseCase {
  const LogoutUseCase(this._repository);

  final AuthRepository _repository;

  Future<void> call() => _repository.logout();
}
