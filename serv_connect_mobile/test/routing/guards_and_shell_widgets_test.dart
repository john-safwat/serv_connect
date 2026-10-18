import 'package:auto_route/auto_route.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:serv_connect_mobile/core/common_ui/feedback/toaster.dart';
import 'package:serv_connect_mobile/core/config/app_environment.dart';
import 'package:serv_connect_mobile/core/config/feature_flag_service.dart';
import 'package:serv_connect_mobile/core/config/flavor_config.dart';
import 'package:serv_connect_mobile/core/l10n/locale_cubit.dart';
import 'package:serv_connect_mobile/core/logger/app_logger.dart';
import 'package:serv_connect_mobile/core/permissions/permission_checker.dart';
import 'package:serv_connect_mobile/core/permissions/permission_keys.dart';
import 'package:serv_connect_mobile/core/services/auth_session.dart';
import 'package:serv_connect_mobile/core/storage/secure_storage.dart';
import 'package:serv_connect_mobile/core/theme/serve_breakpoints.dart';
import 'package:serv_connect_mobile/features/home/presentation/home/view/home_states.dart';
import 'package:serv_connect_mobile/features/home/presentation/home/widgets/home_bottom_nav.dart';
import 'package:serv_connect_mobile/features/home/presentation/home/widgets/home_overview_tab.dart';
import 'package:serv_connect_mobile/features/home/presentation/home/widgets/home_placeholder_tab.dart';
import 'package:serv_connect_mobile/features/home/presentation/home/widgets/home_top_bar.dart';
import 'package:serv_connect_mobile/network/dio_module.dart';
import 'package:serv_connect_mobile/network/interceptors/accept_language_interceptor.dart';
import 'package:serv_connect_mobile/network/interceptors/auth_interceptor.dart';
import 'package:serv_connect_mobile/network/interceptors/logging_interceptor.dart';
import 'package:serv_connect_mobile/network/interceptors/refresh_interceptor.dart';
import 'package:serv_connect_mobile/routing/guards/auth_guard.dart';
import 'package:serv_connect_mobile/routing/guards/scope_guard.dart';

import '../test_helpers.dart';

class _MockAuthSession extends Mock implements AuthSession {}

class _MockPermissionChecker extends Mock implements PermissionChecker {}

class _MockNavigationResolver extends Mock implements NavigationResolver {}

class _MockStackRouter extends Mock implements StackRouter {}

class _MockLocaleCubit extends Mock implements LocaleCubit {}

class _MockSecureStorage extends Mock implements SecureStorage {}

void main() {
  setUpAll(() async {
    await ensureTestLocalizationInitialized();
    registerFallbackValue(const PageRouteInfo<void>('dummy'));
  });

  group('AuthGuard & ScopeGuard', () {
    test('authGuard_whenAuthenticated_callsNextOtherwiseRedirects', () {
      final session = _MockAuthSession();
      final resolver = _MockNavigationResolver();
      final router = _MockStackRouter();
      final guard = AuthGuard(session);

      when(() => session.isAuthenticated).thenReturn(true);
      guard.onNavigation(resolver, router);
      verify(resolver.next).called(1);

      when(() => session.isAuthenticated).thenReturn(false);
      when(() => resolver.redirectUntil(any())).thenAnswer((_) async {});
      guard.onNavigation(resolver, router);
      verify(() => resolver.redirectUntil(any())).called(1);
    });

    test('scopeGuard_checksBothFeatureFlagAndPermission', () {
      final checker = _MockPermissionChecker();
      final flags = FeatureFlagService();
      final resolver = _MockNavigationResolver();
      final router = _MockStackRouter();

      final guard = ScopeGuard(
        permissionChecker: checker,
        featureFlagService: flags,
        requiredPermission: PermissionKeys.attendanceRecord,
        featureModule: FeatureModule.attendance,
      );

      when(
        () => checker.hasAnyScope(PermissionKeys.attendanceRecord),
      ).thenReturn(true);
      guard.onNavigation(resolver, router);
      verify(resolver.next).called(1);

      when(
        () => checker.hasAnyScope(PermissionKeys.attendanceRecord),
      ).thenReturn(false);
      when(() => resolver.redirectUntil(any())).thenAnswer((_) async {});
      guard.onNavigation(resolver, router);
      verify(() => resolver.redirectUntil(any())).called(1);
    });
  });

  group('DioModule & LoggingInterceptor', () {
    test('dioModule_buildsMainAndRefreshClients', () {
      const env = AppEnvironment(
        flavor: Flavor.dev,
        apiBaseUrl: 'http://localhost:8080',
        envName: 'dev',
        defaultOfflineGraceDays: 14,
        mediaCacheMaxMb: 250,
        syncBatchSize: 50,
      );
      final mod = DioModule(env);
      final localeCubit = _MockLocaleCubit();
      final acceptLang = AcceptLanguageInterceptor(localeCubit);
      final auth = AuthInterceptor(_MockSecureStorage());
      final logging = LoggingInterceptor(AppLogger());
      final refresh = RefreshInterceptor(
        bareClient: mod.refreshClient(acceptLanguage: acceptLang),
        secureStorage: _MockSecureStorage(),
        authSession: _MockAuthSession(),
        refreshCall: (_, _) async =>
            const TokenPair(accessToken: 'a', refreshToken: 'r'),
      );

      final mainClient = mod.client(
        acceptLanguage: acceptLang,
        auth: auth,
        refresh: refresh,
        logging: logging,
      );
      expect(mainClient.options.baseUrl, 'http://localhost:8080');

      final req = RequestOptions(path: '/api/v1/health');
      logging
        ..onRequest(req, RequestInterceptorHandler())
        ..onResponse(
          Response<dynamic>(requestOptions: req, statusCode: 200),
          ResponseInterceptorHandler(),
        );
    });
  });

  group('Home Shell Sub-Widgets & Toaster', () {
    testWidgets('homeShellWidgetsAndToaster_renderAndShowSnackbars', (
      tester,
    ) async {
      final toaster = Toaster();
      var tappedTab = HomeTab.home;

      await tester.pumpWidget(
        makeTestableWidget(
          Builder(
            builder: (context) {
              expect(ServeBreakpoints.isCompact(context), isFalse);
              expect(ServeBreakpoints.isTablet(context), isTrue);
              return Column(
                children: <Widget>[
                  HomeTopBar(onToggleLanguage: () {}),
                  const Expanded(child: HomeOverviewTab()),
                  const Expanded(
                    child: HomePlaceholderTab(tab: HomeTab.schedule),
                  ),
                  HomeBottomNav(
                    activeTab: tappedTab,
                    onTabSelected: (tab) => tappedTab = tab,
                  ),
                ],
              );
            },
          ),
          messengerKey: toaster.messengerKey,
        ),
      );
      await tester.pump();

      toaster.showSuccess('Saved offline');
      await tester.pump();
      expect(find.text('Saved offline'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.fact_check_outlined));
      expect(tappedTab, HomeTab.attend);
    });
  });
}
