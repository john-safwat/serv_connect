import 'package:auto_route/auto_route.dart';
import 'package:serv_connect_mobile/core/config/feature_flag_service.dart';
import 'package:serv_connect_mobile/core/permissions/permission_checker.dart';
import 'package:serv_connect_mobile/routing/app_router.gr.dart';

/// Route guard enforcing both [FeatureFlagService] module availability and
/// [PermissionChecker] permission keys (`CLAUDE.md §17.1`).
class ScopeGuard extends AutoRouteGuard {
  ScopeGuard({
    required this.permissionChecker,
    required this.featureFlagService,
    required this.requiredPermission,
    this.featureModule,
  });

  final PermissionChecker permissionChecker;
  final FeatureFlagService featureFlagService;
  final String requiredPermission;
  final FeatureModule? featureModule;

  @override
  void onNavigation(NavigationResolver resolver, StackRouter router) {
    final moduleEnabled =
        featureModule == null || featureFlagService.isEnabled(featureModule!);
    final permitted = permissionChecker.hasAnyScope(requiredPermission);
    if (moduleEnabled && permitted) {
      resolver.next();
      return;
    }
    resolver.redirectUntil(const HomeRoute());
  }
}
