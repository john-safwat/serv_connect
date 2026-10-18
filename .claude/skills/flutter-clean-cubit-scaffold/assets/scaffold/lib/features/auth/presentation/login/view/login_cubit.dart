import 'package:injectable/injectable.dart';
import 'package:__PKG__/core/base/base_cubit.dart';
import 'package:__PKG__/features/auth/domain/entities/user_data.dart';
import 'package:__PKG__/features/auth/domain/use_case/login_use_case.dart';
import 'package:__PKG__/features/auth/presentation/login/view/login_states.dart';
import 'package:__PKG__/network/resources.dart';
import 'package:__PKG__/network/results.dart';

@injectable
class LoginCubit
    extends BaseCubit<LoginStates, LoginAction, LoginNavigationAction> {
  LoginCubit(this._loginUseCase) : super(LoginStates());

  final LoginUseCase _loginUseCase;

  @override
  Future<void> doAction(LoginAction action) async {
    switch (action) {
      case SubmitLoginAction():
        await _login(action);
    }
  }

  Future<void> _login(SubmitLoginAction action) async {
    emit(state.copyWith(loginResource: const Resources.loading()));
    final result = await _loginUseCase(
      email: action.email,
      password: action.password,
    );
    switch (result) {
      case Success<UserData>():
        emit(
          state.copyWith(loginResource: Resources.success(data: result.data)),
        );
        emitNavigation(NavigateToHome());
      case Failure<UserData>():
        emit(
          state.copyWith(
            loginResource: Resources.failure(
              exception: result.exception,
              message: result.message,
            ),
          ),
        );
        emitNavigation(ShowLoginError(result.message));
    }
  }
}
