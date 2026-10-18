import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:__PKG__/core/services/auth_session.dart';
import 'package:__PKG__/routing/app_router.gr.dart';

/// Gates auth-required routes. Reads [AuthSession] and either lets the
/// navigation through or replaces the stack with the login route.
class AuthGuard extends AutoRouteGuard {
  AuthGuard(this._session);

  final AuthSession _session;

  @override
  void onNavigation(NavigationResolver resolver, StackRouter router) {
    if (_session.isAuthenticated) {
      resolver.next();
    } else {
      unawaited(router.replace(const LoginRoute()));
    }
  }
}
