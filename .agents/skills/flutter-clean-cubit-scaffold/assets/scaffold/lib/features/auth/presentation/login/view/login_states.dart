import 'package:__PKG__/features/auth/domain/entities/user_data.dart';
import 'package:__PKG__/network/resources.dart';

/// Plain State class with a hand-written `copyWith` — no freezed, no equatable.
/// One [Resources] field per ongoing async operation.
class LoginStates {
  LoginStates({this.loginResource = const Resources.initial()});

  final Resources<UserData> loginResource;

  LoginStates copyWith({Resources<UserData>? loginResource}) =>
      LoginStates(loginResource: loginResource ?? this.loginResource);
}

/// Dart 3 sealed union — the `switch` in `doAction` is exhaustive without a
/// `default`.
sealed class LoginAction {}

class SubmitLoginAction extends LoginAction {
  SubmitLoginAction({required this.email, required this.password});
  final String email;
  final String password;
}

/// One-shot side effects. Bridged to the router / toaster by the View.
sealed class LoginNavigationAction {}

class NavigateToHome extends LoginNavigationAction {}

class ShowLoginError extends LoginNavigationAction {
  ShowLoginError(this.message);
  final String message;
}
