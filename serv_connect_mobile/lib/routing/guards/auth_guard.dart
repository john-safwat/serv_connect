import 'package:auto_route/auto_route.dart';
import 'package:serv_connect_mobile/core/services/auth_session.dart';
import 'package:serv_connect_mobile/routing/app_router.gr.dart';

/// Route guard checking [AuthSession] authentication status (`CLAUDE.md §15`).
class AuthGuard extends AutoRouteGuard {
  AuthGuard(this._authSession);

  final AuthSession _authSession;

  @override
  void onNavigation(NavigationResolver resolver, StackRouter router) {
    if (_authSession.isAuthenticated) {
      resolver.next();
      return;
    }
    resolver.redirectUntil(const SplashRoute());
  }
}
