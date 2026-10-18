import 'package:auto_route/auto_route.dart';
import 'package:injectable/injectable.dart';
import 'package:serv_connect_mobile/routing/app_router.gr.dart';

/// Root application router (`CLAUDE.md §1.1 & §26`).
///
/// In M0 foundation, routes from [SplashRoute] into the 5-tab [HomeRoute]
/// editorial shell; `LoginRoute` and protected domain routes are added in M1+.
@lazySingleton
@AutoRouterConfig()
class AppRouter extends RootStackRouter {
  @override
  List<AutoRoute> get routes => <AutoRoute>[
    AutoRoute(page: SplashRoute.page, initial: true, path: '/'),
    AutoRoute(page: HomeRoute.page, path: '/home'),
  ];
}
