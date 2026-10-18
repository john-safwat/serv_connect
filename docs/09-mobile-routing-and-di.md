# 09 — Mobile Routing & Dependency Injection (`serv_connect_mobile`)

| Field | Value |
| --- | --- |
| Router | `auto_route` (`@AutoRouterConfig()` in `lib/routing/app_router.dart`) |
| Guards | `AuthGuard` (`lib/routing/guards/auth_guard.dart`), `ScopeGuard` (`lib/routing/guards/scope_guard.dart`) |
| DI Container | `get_it` + `injectable` (`lib/di/injection.dart` + `lib/di/injection.config.dart`) |

---

## 1. Route Graph (`AppRouter`)

Defined in `lib/routing/app_router.dart` and generated to `lib/routing/app_router.gr.dart`:

| Route Name | Path | Page Class | Guards | Purpose |
| --- | --- | --- | --- | --- |
| `SplashRoute` | `/` | `SplashPage` | — | Initial startup route; hydrates and checks `AuthSession` before navigating to the shell. |
| `HomeRoute` | `/home` | `HomePage` | — (M0 shell; `AuthGuard` attaches in M1 when `LoginRoute` lands) | 5-tab editorial app shell (`Home`, `Schedule`, `Attend`, `Word`, `More`) with `ServeSyncBanner` and language toggle. |

### 1.1 Route Guards

- **`AuthGuard` (`lib/routing/guards/auth_guard.dart`):**
  Checks `AuthSession.isAuthenticated` (which returns `true` for `authenticatedOnline`, `authenticatedOffline`, and read-only `offlineGraceExpired` states per `FR-1.3`). Redirects unauthenticated users to `SplashRoute` (and `LoginRoute` once M1 lands).
- **`ScopeGuard` (`lib/routing/guards/scope_guard.dart`):**
  Enforces both `FeatureFlagService.isEnabled(featureModule)` (`FR-16.5`) and `PermissionChecker.hasAnyScope(requiredPermission)` (`FR-13.1`). Redirects unauthorized navigation attempts back to `HomeRoute`.
- **Global Force-Logout Listener (`lib/app.dart`):**
  `ServeConnectApp` subscribes to `AuthEventBus.on<ForceLogoutEvent>()` and resets the router stack when the server explicitly rejects token refresh with HTTP `401`.

---

## 2. Dependency Injection (`get_it` + `injectable`)

Configured in `lib/di/injection.dart` via `configureDependencies({required AppEnvironment env})`.

### 2.1 Lifecycle Scopes (`CLAUDE.md §19`)

| Annotation | Scope | Registered Classes |
| --- | --- | --- |
| Manual `registerSingleton` | Boot-time flavor config | `AppEnvironment` (registered in `configureDependencies` before `$initGetIt`) |
| `@singleton` | Eager boot essentials | `AppLogger`, `HiveStorage` |
| `@lazySingleton` | On-demand singletons | `SecureStorage`, `Preferences`, `AuthSession`, `ConnectivityService`, `PermissionChecker`, `FeatureFlagService`, `AppEventBus`, `AuthEventBus`, `LocaleCubit`, `DioModule`, `AcceptLanguageInterceptor`, `AuthInterceptor`, `RefreshInterceptor`, `LoggingInterceptor`, `Dio` (`@Named('main')`, `@Named('refresh')`), `ServePlatformMethodChannel` (`as: ServePlatform`), `AppRouter`, `Toaster`, `BottomSheetHost` |
| `@injectable` | Factory per screen/call | `SplashCubit`, `HomeCubit` (and all future feature `Cubit`s and `UseCase`s) |

### 2.2 DI Modules (`lib/di/`)

- **`StorageModule` (`lib/di/storage_module.dart`):** `@preResolve` `SharedPreferences` and `Preferences` facade.
- **`NetworkModule` (`lib/di/network_module.dart`):** Wires `@Named('refresh') Dio`, `RefreshInterceptor` (with `/api/v1/auth/refresh` callback), and `@Named('main') Dio`.
- **`RetrofitModule` (`lib/di/retrofit_module.dart`):** Hosts `@RestApi()` remote data source bindings as domain features (`M1`–`M7`) are added.
