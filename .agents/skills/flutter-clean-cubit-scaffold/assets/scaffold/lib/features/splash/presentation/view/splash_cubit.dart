import 'package:injectable/injectable.dart';
import 'package:__PKG__/core/base/base_cubit.dart';
import 'package:__PKG__/core/services/auth_session.dart';
import 'package:__PKG__/features/splash/presentation/view/splash_states.dart';

@injectable
class SplashCubit
    extends BaseCubit<SplashStates, SplashAction, SplashNavigationAction> {
  SplashCubit(this._session) : super(const SplashStates());

  final AuthSession _session;

  @override
  Future<void> doAction(SplashAction action) async {
    switch (action) {
      case CheckSessionAction():
        await _decide();
    }
  }

  Future<void> _decide() async {
    // A short pause so the splash doesn't flash on fast devices. Replace with
    // real bootstrap work (remote config, force-update check) as needed.
    await Future<void>.delayed(const Duration(milliseconds: 600));
    if (_session.isAuthenticated) {
      emitNavigation(GoToHome());
    } else {
      emitNavigation(GoToLogin());
    }
  }
}
