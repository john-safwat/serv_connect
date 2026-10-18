import 'package:auto_route/auto_route.dart';
import 'package:injectable/injectable.dart';
import 'package:__PKG__/core/services/auth_session.dart';
import 'package:__PKG__/routing/app_router.gr.dart';
import 'package:__PKG__/routing/guards/auth_guard.dart';

/// The app's route graph. Run `dart run build_runner build` after editing to
/// regenerate `app_router.gr.dart`. Every page class is annotated with
/// `@RoutePage()`.
@LazySingleton()
@AutoRouterConfig()
class AppRouter extends RootStackRouter {
  AppRouter(this._session);

  final AuthSession _session;

  @override
  List<AutoRoute> get routes => [
    AutoRoute(page: SplashRoute.page, initial: true, path: '/'),
    AutoRoute(page: LoginRoute.page, path: '/login'),
    AutoRoute(
      page: HomeRoute.page,
      path: '/home',
      guards: [AuthGuard(_session)],
    ),
  ];
}
