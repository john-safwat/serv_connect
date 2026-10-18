import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:serv_connect_mobile/core/config/app_environment.dart';
import 'package:serv_connect_mobile/core/config/flavor_config.dart';
import 'package:serv_connect_mobile/core/event_bus/auth_event_bus.dart';
import 'package:serv_connect_mobile/core/permissions/permission_keys.dart';
import 'package:serv_connect_mobile/core/permissions/role_assignment.dart';
import 'package:serv_connect_mobile/core/permissions/scope_type.dart';
import 'package:serv_connect_mobile/core/services/auth_session.dart';
import 'package:serv_connect_mobile/core/storage/hive_storage.dart';
import 'package:serv_connect_mobile/core/storage/secure_storage.dart';
import 'package:serv_connect_mobile/core/storage/storage_keys.dart';

class _MockSecureStorage extends Mock implements SecureStorage {}

class _MockHiveStorage extends Mock implements HiveStorage {}

void main() {
  late Map<StorageKey, String> store;
  late _MockSecureStorage secureStorage;
  late _MockHiveStorage hiveStorage;
  late AuthEventBus authEventBus;
  late AuthSession session;

  const env = AppEnvironment(
    flavor: Flavor.dev,
    apiBaseUrl: 'http://localhost:8080',
    envName: 'dev',
    defaultOfflineGraceDays: 14,
    mediaCacheMaxMb: 250,
    syncBatchSize: 50,
  );

  setUpAll(() {
    registerFallbackValue(StorageKey.accessToken);
  });

  setUp(() {
    store = <StorageKey, String>{};
    secureStorage = _MockSecureStorage();
    hiveStorage = _MockHiveStorage();
    authEventBus = AuthEventBus();

    when(() => secureStorage.read(any())).thenAnswer(
      (inv) async => store[inv.positionalArguments[0] as StorageKey],
    );
    when(() => secureStorage.write(any(), any())).thenAnswer((inv) async {
      store[inv.positionalArguments[0] as StorageKey] =
          inv.positionalArguments[1] as String;
    });
    when(() => secureStorage.delete(any())).thenAnswer((inv) async {
      store.remove(inv.positionalArguments[0] as StorageKey);
    });
    when(() => hiveStorage.clearSensitiveRecords()).thenAnswer((_) async {});
    when(
      () => hiveStorage.clearUserScopePreservingOutbox(),
    ).thenAnswer((_) async {});

    session = AuthSession(secureStorage, hiveStorage, authEventBus, env);
  });

  group('AuthSession & FR-1.3 Offline Grace Window', () {
    test(
      'signIn_andOfflineRefreshWithinGraceWindow_staysMutableOffline',
      () async {
        final baseTime = DateTime.utc(2026, 10, 1, 12);
        await session.signIn(
          accessToken: 'access-1',
          refreshToken: 'refresh-1',
          userId: 'user-uuid-1',
          orgId: 'org-uuid-1',
          assignments: const <RoleAssignment>[
            RoleAssignment(
              roleCode: 'SERVANT',
              scopeType: ScopeType.group,
              scopeTargetId: 'group-1',
              permissions: <String>{PermissionKeys.attendanceRecord},
            ),
          ],
          authenticatedAtUtc: baseTime,
        );

        expect(session.status, AuthSessionStatus.authenticatedOnline);
        expect(session.canMutateOffline, isTrue);

        final statusAfter7Days = await session.handleOfflineRefreshFailure(
          nowUtc: baseTime.add(const Duration(days: 7)),
        );
        expect(statusAfter7Days, AuthSessionStatus.authenticatedOffline);
        expect(session.canMutateOffline, isTrue);
        verifyNever(() => hiveStorage.clearSensitiveRecords());
      },
    );

    test(
      'handleOfflineRefreshFailure_pastGraceWindow_transitionsToReadOnly',
      () async {
        final baseTime = DateTime.utc(2026, 10, 1, 12);
        await session.signIn(
          accessToken: 'access-1',
          refreshToken: 'refresh-1',
          userId: 'user-uuid-1',
          orgId: 'org-uuid-1',
          assignments: const <RoleAssignment>[],
          authenticatedAtUtc: baseTime,
        );

        final expiredStatus = await session.handleOfflineRefreshFailure(
          nowUtc: baseTime.add(const Duration(days: 15)),
        );
        expect(expiredStatus, AuthSessionStatus.offlineGraceExpired);
        expect(session.isGraceExpired, isTrue);
        expect(session.canMutateOffline, isFalse);
        verify(() => hiveStorage.clearSensitiveRecords()).called(1);
      },
    );

    test('signOut_forceLogout_emitsEventAndPreservesOutbox', () async {
      await session.signIn(
        accessToken: 'access-1',
        refreshToken: 'refresh-1',
        userId: 'user-uuid-1',
        orgId: 'org-uuid-1',
        assignments: const <RoleAssignment>[],
      );

      final events = <AuthBusEvent>[];
      final sub = authEventBus.stream.listen(events.add);

      await session.signOut(forceLogout: true, reason: 'expired');
      await Future<void>.delayed(Duration.zero);

      expect(session.isAuthenticated, isFalse);
      expect(events.whereType<ForceLogoutEvent>(), isNotEmpty);
      verify(() => hiveStorage.clearUserScopePreservingOutbox()).called(1);
      await sub.cancel();
    });
  });
}
