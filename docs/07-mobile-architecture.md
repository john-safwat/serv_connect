# 07 — Mobile Architecture (`serv_connect_mobile`)

| Field | Value |
| --- | --- |
| Project | `serv_connect_mobile/` (Flutter / Dart `^3.13.5`) |
| Targets | Android + iOS (offline-first, EN/AR + RTL) |
| Pattern | Feature-first Clean Architecture + `BaseCubit<T, A, NE>` |
| Local Store | Encrypted `HiveStorage` (AES-256 `HiveAesCipher`, JSON document maps) |
| HTTP Client | `Dio` + `Retrofit` + `ApiResult<T>` + `Resources<T>` + sealed `Errors` |

---

## 1. Architectural Spine

ServeConnect Mobile is organized by vertical feature slices under `lib/features/<feature>/` and shared cross-cutting primitives under `lib/core/` and `lib/network/`:

```text
lib/
├── main.dart / main_dev.dart / main_staging.dart / main_prod.dart
├── bootstrap.dart                  # .env.<flavor> → assertConfigured → DI → HiveStorage → AuthSession → runApp
├── app.dart                        # ServeConnectApp (MaterialApp.router + LocaleCubit + OrgLabelResolver + ForceLogout listener)
├── core/
│   ├── base/base_cubit.dart        # BaseCubit<T, A, NE> with doAction(A) and Stream<NE> navigation
│   ├── common_ui/                  # Serve* Shared UI Component Catalogue
│   ├── config/                     # Flavor, FlavorConfig, AppEnvironment, AppEnvironmentLoader, FeatureFlagService
│   ├── event_bus/                  # AppEventBus, AuthEventBus
│   ├── l10n/                       # LocaleCubit, OrgLabelResolver
│   ├── logger/                     # AppLogger (PII-scrubbing, debug-only)
│   ├── permissions/                # ScopeType, PermissionKeys, RoleAssignment, PermissionChecker
│   ├── platform/                   # ServePlatform + ServePlatformMethodChannel
│   ├── services/                   # AuthSession (with FR-1.3 offline grace window), ConnectivityService
│   ├── storage/                    # StorageKey, SecureStorage, Preferences, HiveStorage (AES-256)
│   ├── theme/                      # AppColors, AppTypography, AppTheme, ServeSpacing, ServeBreakpoints
│   └── utils/                      # AppFormatters, LocalDateValue, LocalTimeValue, Validation, IdGenerator
├── network/
│   ├── results.dart                # ApiResult<T>: Success<T> | Failure<T>
│   ├── resources.dart              # Resources<T>: initial | loading(data) | success(data) | failure(data, error)
│   ├── errors.dart                 # Sealed Errors hierarchy
│   ├── base_api_response.dart      # BaseApiResponse<T> & PagedContent<T>
│   ├── error_parser.dart           # Maps DioException / backend error codes to sealed Errors
│   ├── safe_call.dart              # Wraps async I/O into ApiResult<T>
│   ├── dio_module.dart             # Main & bare refresh Dio clients
│   └── interceptors/               # AcceptLanguageInterceptor, AuthInterceptor, RefreshInterceptor, LoggingInterceptor
├── di/                             # get_it + injectable bootstrap and modules
├── routing/                        # AppRouter (@AutoRouterConfig), AuthGuard, ScopeGuard
├── generated/                      # locale_keys.g.dart, assets.gen.dart
└── features/
    ├── splash/                     # Initial session check & routing
    └── home/                       # 5-tab editorial app shell (Home, Schedule, Attend, Word, More)
```

### 1.1 Dependency Direction & Call Chain

```text
Page (StatefulWidget)
  └─► Cubit.doAction(SealedAction)
        └─► UseCase.call(...)
              └─► Repository (abstract in domain/)
                    └─► RepositoryImpl (in data/, wrapped in safeCall)
                          ├─► LocalDataSource (HiveStorage encrypted JSON boxes)
                          ├─► RemoteDataSource (Retrofit / Dio)
                          └─► Mapper (DTO ↔ Doc ↔ Domain Entity)
```

- `lib/core/` and `lib/network/` never import `lib/features/`.
- Feature `X` never imports `data/` or `presentation/` of feature `Y`.
- Every hand-written `.dart` file is ≤ 250–300 lines, and every function, method, constructor body, or `build()` is ≤ 20–25 lines.

---

## 2. State Management (`BaseCubit<T, A, NE>`)

Every screen and feature controller extends `BaseCubit<T, A, NE>`:

- **`T` (`State`)**: Plain immutable Dart class with `final` fields, a `const` constructor, and a hand-written `copyWith` (never `freezed` or `equatable`).
- **`A` (`Action`)**: Dart 3 `sealed class` representing user intents (`doAction(A action)` switches exhaustively on `A`).
- **`NE` (`NavigationAction`)**: Dart 3 `sealed class` emitted through the broadcast `Stream<NE> navigation` for one-shot side effects (route navigation, toasts via `Toaster`, modal sheets via `BottomSheetHost`).

---

## 3. Result & Resource Envelopes

### 3.1 `ApiResult<T>` (`lib/network/results.dart`)
Returned by every `Repository` and `UseCase`:
- `Success<T>(T? data)`
- `Failure<T>({Errors? exception, required String message})`

### 3.2 `Resources<T>` (`lib/network/resources.dart`)
Held inside Cubit `State` classes to represent UI data lifecycle:
- `Resources.initial()`
- `Resources.loading({T? data})` — preserves cached `data` during background refresh so offline-first screens never flash blank or replace cached lists with a spinner.
- `Resources.success({T? data})`
- `Resources.failure({Errors? exception, String? message, T? data})` — preserves cached `data` when a background refresh fails offline.

### 3.3 Sealed `Errors` Hierarchy (`lib/network/errors.dart`)
All failures map to a subtype of `Errors` via `ErrorParser`:
- `NetworkError`, `TimeoutError`, `ParseError`
- `ServerError(statusCode, code, fieldErrors, message)`
- `ForbiddenScopeError` (`403` when out of scope)
- `FeatureDisabledError` (`403` with `code == 'ERR_FEATURE_DISABLED'`)
- `SyncConflictError` (`409` with `code == 'ERR_SYNC_CONFLICT'` and optional `serverCopy`)
- `LoginRequired` (`401`)
- `StorageError`, `PlatformError`, `JustMessage`, `Unknown`

---

## 4. Encrypted Offline Storage (`HiveStorage`)

- **AES-256 at rest (`NFR-4`, `FR-13.7`):** `HiveStorage` generates a 256-bit key once via `Hive.generateSecureKey()`, persists it in `SecureStorage` (`StorageKey.hiveEncryptionKey`), and opens every box with `HiveAesCipher`.
- **JSON Document Storage:** Boxes store `Map<String, dynamic>` documents keyed by entity UUID (`served_members`, `sensitive_records`, `outbox_mutations`, `org_config`). No `@HiveType` binary adapters or `hive_generator` are used.
- **Safeguarding Isolation (`FR-13.3`):** Sensitive records (`sensitive_records` box) are isolated from general member profiles (`served_members`) and are immediately purged via `HiveStorage.clearSensitiveRecords()` upon scope revocation, logout, or offline grace window expiry.
- **Outbox Durability (`CLAUDE.md §12.2`):** `HiveStorage.clearUserScopePreservingOutbox()` wipes user-scoped caches on logout while preserving `outbox_mutations` so offline attendance/follow-up work is never silently lost.

---

## 5. Authentication & Offline Session Grace Window (`FR-1.3`)

`AuthSession` (`lib/core/services/auth_session.dart`) and `RefreshInterceptor` (`lib/network/interceptors/refresh_interceptor.dart`) implement the `FR-1.3` offline session grace window:

1. **Serialized Token Rotation:** Concurrent HTTP `401` responses are serialized via `synchronized` `Lock`. If an earlier call already rotated the token in `SecureStorage`, queued requests immediately reuse the new token; otherwise `POST /api/v1/auth/refresh` is called on the `@Named('refresh')` `Dio` client.
2. **Offline Grace Window Evaluation:**
   - When a refresh attempt fails due to connectivity, timeout, or `5xx` server error, `RefreshInterceptor` calls `AuthSession.handleOfflineRefreshFailure()` instead of logging the user out.
   - If `nowUtc.difference(lastServerAuthAt) <= Duration(days: defaultOfflineGraceDays)` (default 14 days), `AuthSession.status` transitions to `AuthSessionStatus.authenticatedOffline` (`canMutateOffline == true`).
   - If the grace window has elapsed while offline, `AuthSession.status` transitions to `AuthSessionStatus.offlineGraceExpired` (`canMutateOffline == false`), `HiveStorage.clearSensitiveRecords()` purges cached sensitive data, and `ServeSyncBanner` displays a read-only warning until the user reconnects.
   - Only an explicit HTTP `401` from `/api/v1/auth/refresh` triggers `AuthSession.signOut(forceLogout: true)` and emits `ForceLogoutEvent` on `AuthEventBus`.
