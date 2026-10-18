import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:serv_connect_mobile/core/common_ui/feedback/serve_sync_banner.dart';
import 'package:serv_connect_mobile/core/event_bus/app_event_bus.dart';
import 'package:serv_connect_mobile/core/l10n/locale_cubit.dart';
import 'package:serv_connect_mobile/core/services/auth_session.dart';
import 'package:serv_connect_mobile/core/services/connectivity_service.dart';
import 'package:serv_connect_mobile/core/storage/preferences.dart';
import 'package:serv_connect_mobile/features/home/presentation/home/view/home_cubit.dart';
import 'package:serv_connect_mobile/features/home/presentation/home/view/home_states.dart';
import 'package:serv_connect_mobile/features/splash/presentation/splash/view/splash_cubit.dart';
import 'package:serv_connect_mobile/features/splash/presentation/splash/view/splash_states.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MockAuthSession extends Mock implements AuthSession {}

class _MockConnectivityService extends Mock implements ConnectivityService {}

void main() {
  group('LocaleCubit', () {
    late Preferences preferences;
    late AppEventBus eventBus;

    setUp(() async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final raw = await SharedPreferences.getInstance();
      preferences = Preferences(raw);
      eventBus = AppEventBus();
    });

    blocTest<LocaleCubit, Locale>(
      'toggleLocale_switchesBetweenEnglishAndArabic',
      build: () => LocaleCubit(preferences, eventBus),
      act: (cubit) async {
        await cubit.toggleLocale();
        await cubit.toggleLocale();
      },
      expect: () => const <Locale>[Locale('ar'), Locale('en')],
    );
  });

  group('SplashCubit', () {
    late _MockAuthSession authSession;

    setUp(() {
      authSession = _MockAuthSession();
      when(() => authSession.isInitialised).thenReturn(true);
      when(
        () => authSession.status,
      ).thenReturn(AuthSessionStatus.authenticatedOnline);
    });

    blocTest<SplashCubit, SplashStates>(
      'checkInitialSession_emitsSessionStatusAndNavigatesToHomeShell',
      build: () => SplashCubit(authSession),
      act: (cubit) => cubit.doAction(const CheckInitialSessionAction()),
      expect: () => <Matcher>[
        isA<SplashStates>()
            .having((s) => s.isChecking, 'isChecking', isFalse)
            .having(
              (s) => s.sessionStatus,
              'sessionStatus',
              AuthSessionStatus.authenticatedOnline,
            ),
      ],
    );
  });

  group('HomeCubit', () {
    late _MockConnectivityService connectivityService;
    late _MockAuthSession authSession;
    late LocaleCubit localeCubit;

    setUp(() async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final raw = await SharedPreferences.getInstance();
      connectivityService = _MockConnectivityService();
      authSession = _MockAuthSession();
      localeCubit = LocaleCubit(Preferences(raw), AppEventBus());
      when(() => authSession.isGraceExpired).thenReturn(false);
      when(
        () => connectivityService.isConnected(),
      ).thenAnswer((_) async => false);
    });

    blocTest<HomeCubit, HomeStates>(
      'selectTabAndRefreshOffline_updatesTabAndBannerMode',
      build: () => HomeCubit(connectivityService, authSession, localeCubit),
      act: (cubit) async {
        await cubit.doAction(const SelectHomeTabAction(HomeTab.attend));
        await cubit.doAction(const RefreshConnectivityStatusAction());
      },
      expect: () => <Matcher>[
        isA<HomeStates>().having(
          (s) => s.activeTab,
          'activeTab',
          HomeTab.attend,
        ),
        isA<HomeStates>().having(
          (s) => s.syncBannerMode,
          'syncBannerMode',
          ServeSyncBannerMode.offline,
        ),
      ],
    );
  });
}
