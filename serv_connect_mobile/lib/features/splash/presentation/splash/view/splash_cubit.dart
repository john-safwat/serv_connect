import 'package:injectable/injectable.dart';
import 'package:serv_connect_mobile/core/base/base_cubit.dart';
import 'package:serv_connect_mobile/core/services/auth_session.dart';
import 'package:serv_connect_mobile/features/splash/presentation/splash/view/splash_states.dart';

/// Evaluates [AuthSession] on startup and routes to the initial shell
/// (`CLAUDE.md §9.2 & §15`).
@injectable
class SplashCubit
    extends BaseCubit<SplashStates, SplashAction, SplashNavigationAction> {
  SplashCubit(this._authSession) : super(const SplashStates());

  final AuthSession _authSession;

  @override
  Future<void> doAction(SplashAction action) async {
    switch (action) {
      case CheckInitialSessionAction():
        await _checkSession();
    }
  }

  Future<void> _checkSession() async {
    if (!_authSession.isInitialised) {
      await _authSession.hydrate();
    }
    emit(
      state.copyWith(
        sessionStatus: _authSession.status,
        isChecking: false,
      ),
    );
    emitNavigation(const NavigateToHomeShell());
  }
}
