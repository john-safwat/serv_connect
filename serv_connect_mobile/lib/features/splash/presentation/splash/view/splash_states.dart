import 'package:serv_connect_mobile/core/services/auth_session.dart';

class SplashStates {
  const SplashStates({
    this.sessionStatus = AuthSessionStatus.unauthenticated,
    this.isChecking = true,
  });

  final AuthSessionStatus sessionStatus;
  final bool isChecking;

  SplashStates copyWith({
    AuthSessionStatus? sessionStatus,
    bool? isChecking,
  }) {
    return SplashStates(
      sessionStatus: sessionStatus ?? this.sessionStatus,
      isChecking: isChecking ?? this.isChecking,
    );
  }
}

sealed class SplashAction {
  const SplashAction();
}

class CheckInitialSessionAction extends SplashAction {
  const CheckInitialSessionAction();
}

sealed class SplashNavigationAction {
  const SplashNavigationAction();
}

class NavigateToHomeShell extends SplashNavigationAction {
  const NavigateToHomeShell();
}
