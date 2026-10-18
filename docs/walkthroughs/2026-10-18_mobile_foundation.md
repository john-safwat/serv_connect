# Walkthrough — Mobile Foundation (`M0`)

## Date
2026-10-18

## Summary
Initialized the ServeConnect Flutter mobile client (`serv_connect_mobile/`) on top of the `flutter-clean-cubit-scaffold` spine, tailored to `serv_connect_mobile/CLAUDE.md` and the shared ServeConnect warm editorial design system (`designs/main.main.svg`). This foundation delivers Clean Architecture with `BaseCubit<T, A, NE>`, `ApiResult<T>`, `Resources<T>` (preserving cached data during background refresh/failure), the sealed `Errors` hierarchy, `Dio` + `Retrofit` with `AcceptLanguageInterceptor`, `AuthInterceptor`, `RefreshInterceptor` (serialized with a mutex and implementing the `FR-1.3` offline session grace window), and a PII-safe `LoggingInterceptor`. It also delivers AES-256 encrypted `HiveStorage` (`HiveAesCipher` with key in `SecureStorage`), `PermissionChecker` & `ScopeGuard`, `FeatureFlagService`, EN/AR localization with `OrgLabelResolver` and RTL-first directional layouts, native Android/iOS flavors (`dev`, `staging`, `prod`), the initial `Serve*` Shared UI Component Catalogue (`ServeMemberAvatar` enforcing `photoConsent == true`), and the initial `SplashPage` + 5-tab `HomePage` editorial shell.

## BRD Coverage
- **Phase:** `MVP` (M0 Foundation Infrastructure)
- **Requirements implemented / groundwork laid:**
  - `FR-1.2` (Unified role-based app shell groundwork)
  - `FR-1.3` (Offline session grace window in `AuthSession` + `RefreshInterceptor`)
  - `FR-13.1`, `FR-13.3`, `FR-13.5`, `FR-13.7` (Permission/scope evaluator `PermissionChecker`, `ScopeGuard`, isolated `sensitive_records` encrypted box, `ServeMemberAvatar` `photoConsent` gate, AES-256 `HiveAesCipher`)
  - `FR-16.2`, `FR-16.5` (`OrgLabelResolver` configurable church terminology, `FeatureFlagService`)
  - `NFR-1`, `NFR-3`, `NFR-4`, `NFR-6`, `NFR-7`, `NFR-11`, `NFR-12` (Offline-first storage, TLS transport config, EN/AR + RTL directional UI, WCAG 2.1 AA contrast & 48dp touch targets)

## Files Changed
- **Configuration & Flavors:**
  - `serv_connect_mobile/pubspec.yaml`, `serv_connect_mobile/analysis_options.yaml`, `serv_connect_mobile/flavorizr.yaml`, `serv_connect_mobile/.env.example`, `serv_connect_mobile/.gitignore`
  - `serv_connect_mobile/android/app/build.gradle.kts`, `serv_connect_mobile/android/app/src/main/AndroidManifest.xml`, `serv_connect_mobile/android/app/src/dev/AndroidManifest.xml`
  - `serv_connect_mobile/android/app/src/main/kotlin/com/john/serv_connect_mobile/MainActivity.kt`, `serv_connect_mobile/android/app/src/main/kotlin/com/john/serv_connect_mobile/platform/ServeMethodChannelHandler.kt`
  - `serv_connect_mobile/ios/Flutter/{Dev,Staging,Prod}.xcconfig`, `serv_connect_mobile/ios/Runner/Info.plist`, `serv_connect_mobile/ios/Runner/Platform/ServeMethodChannelHandler.swift`
- **Entrypoints & App Shell:**
  - `serv_connect_mobile/lib/{main.dart, main_dev.dart, main_staging.dart, main_prod.dart, bootstrap.dart, app.dart}`
- **Core (`lib/core/`):**
  - `base/base_cubit.dart`
  - `config/{flavor_config.dart, app_environment.dart, app_environment_loader.dart, feature_flag_service.dart}`
  - `event_bus/{app_event_bus.dart, auth_event_bus.dart}`
  - `l10n/{locale_cubit.dart, org_label_resolver.dart}`
  - `logger/app_logger.dart`
  - `permissions/{scope_type.dart, permission_keys.dart, role_assignment.dart, permission_checker.dart}`
  - `platform/{serve_platform.dart, serve_platform.g.dart, serve_platform_method_channel.dart}`
  - `services/{auth_session.dart, connectivity_service.dart}`
  - `storage/{storage_keys.dart, secure_storage.dart, preferences.dart, hive_storage.dart}`
  - `theme/{app_colors.dart, app_typography.dart, app_theme.dart, serve_spacing.dart, serve_breakpoints.dart}`
  - `utils/{id_generator.dart, app_formatters.dart, validation.dart}`
  - `common_ui/{buttons/*, inputs/*, cards/*, badges/*, avatars/*, controls/*, feedback/*, shimmer/*}`
- **Network, DI & Routing (`lib/network/`, `lib/di/`, `lib/routing/`):**
  - `network/{results.dart, resources.dart, errors.dart, base_api_response.dart, base_api_response.g.dart, error_parser.dart, safe_call.dart, dio_module.dart}`
  - `network/interceptors/{accept_language_interceptor.dart, auth_interceptor.dart, refresh_interceptor.dart, logging_interceptor.dart}`
  - `di/{injection.dart, injection.config.dart, storage_module.dart, network_module.dart, retrofit_module.dart}`
  - `routing/{app_router.dart, app_router.gr.dart, guards/auth_guard.dart, guards/scope_guard.dart}`
- **Features & Translations:**
  - `features/splash/presentation/splash/view/{splash_states.dart, splash_cubit.dart, splash_page.dart}`
  - `features/home/presentation/home/view/{home_states.dart, home_cubit.dart, home_page.dart}`
  - `features/home/presentation/home/widgets/{home_top_bar.dart, home_bottom_nav.dart, home_overview_tab.dart, home_placeholder_tab.dart}`
  - `assets/translations/{en.json, ar.json}`, `lib/generated/{locale_keys.g.dart, assets.gen.dart}`
- **Tests (`serv_connect_mobile/test/`):**
  - `core/config/app_environment_test.dart`, `core/logger/app_logger_test.dart`, `core/permissions/permission_checker_test.dart`, `core/storage/storage_facades_test.dart`, `core/services/auth_session_test.dart`, `core/utils/utils_test.dart`, `core/platform/serve_platform_test.dart`, `core/common_ui/common_ui_widgets_test.dart`, `network/network_spine_test.dart`, `features/splash_and_home_cubit_test.dart`, `routing/guards_and_shell_widgets_test.dart`
- **Documentation (`docs/`):**
  - `docs/07-mobile-architecture.md`, `docs/08-mobile-theme-and-ui-components.md`, `docs/09-mobile-routing-and-di.md`, `docs/10-mobile-platform-native.md`

## API & Sync Usage
- Configured `BaseApiResponse<T>` and `PagedContent<T>` envelopes matching the backend `BaseResponseBody<T>` and `PageResponse<T>` contract (`plans/2026-10-18_backend_foundation.md`).
- Configured `RefreshInterceptor` to call `POST /api/v1/auth/refresh` on the bare refresh `Dio` client.
- Initialized encrypted `HiveStorage` boxes (`served_members`, `sensitive_records`, `outbox_mutations`, `org_config`).

## Security & Safeguarding Impact
- `accessToken`, `refreshToken`, and the 256-bit Hive AES key live exclusively in `SecureStorage` (`flutter_secure_storage`).
- `HiveStorage` opens all boxes with `HiveAesCipher` and isolates `sensitive_records` from `served_members`, purging `sensitive_records` on offline grace expiry or logout while preserving `outbox_mutations`.
- `ServeMemberAvatar` enforces `photoConsent == true` before mounting `CachedNetworkImage`, falling back to deterministic initials when `false` (`FR-13.5`).
- `AppLogger` redacts `authorization`, `password`, `otp`, `token`, `phone`, `email`, `medical`, and `note`, and `LoggingInterceptor` logs only HTTP method, path, and status code.

## Widgets
- Added 17 shared `Serve*` primitives under `lib/core/common_ui/` and catalogued all of them in `docs/08-mobile-theme-and-ui-components.md`: `ServeButton`, `ServeIconButton`, `ServeTextField`, `ServeCard`, `ServeBadge`, `ServeAvatar`, `ServeMemberAvatar`, `ServeSegmentedControl`, `ServeEmptyState`, `DefaultErrorView`, `ServeSyncBanner`, `Toaster`, `BottomSheetHost`, `ServeShimmerBox`, `ServeRowShimmer`, `ServeCardShimmer`, `ServeListShimmer`.

## DI & Routing
- Configured `get_it` + `injectable` in `lib/di/injection.dart` with `StorageModule`, `NetworkModule`, and `RetrofitModule`.
- Configured `AppRouter` (`@AutoRouterConfig()`) with `SplashRoute` (`/`) and `HomeRoute` (`/home`), plus `AuthGuard` and `ScopeGuard`.

## Localization
- Added `common.*`, `nav.*`, `home.*`, `identity.*`, `errors.*`, and `validation.*` keys to both `assets/translations/en.json` and `assets/translations/ar.json` and generated `lib/generated/locale_keys.g.dart`.
- Verified RTL (`Directionality.rtl`) rendering and directional layout primitives across all widgets.

## Platform / Build Config
- Configured `dev`, `staging`, and `prod` flavors in `flavorizr.yaml`, `android/app/build.gradle.kts`, and `ios/Flutter/{Dev,Staging,Prod}.xcconfig`.
- Enforced `usesCleartextTraffic="false"` on Android main manifest (with `true` only on `src/dev/AndroidManifest.xml`) and `NSAllowsArbitraryLoads = false` on iOS `Info.plist`.
- Wired native `com.john.serv_connect_mobile/device` method channel handlers in Kotlin and Swift.

## Code Generation
- Ran `dart run easy_localization:generate -S assets/translations -O lib/generated -o locale_keys.g.dart -f keys`.
- Ran `dart run build_runner build`.

## Testing
- Added 11 unit, Cubit (`bloc_test`), and widget test suites (40 tests total) under `serv_connect_mobile/test/` covering `AppEnvironment`, `AppLogger`, `PermissionChecker`, `SecureStorage`/`Preferences`/`HiveStorage`, `AuthSession` (including `FR-1.3` offline grace window), `Validation`/`AppFormatters`, `ServePlatformMethodChannel`, `ErrorParser`/`safeCall`/`Resources`/interceptors, `LocaleCubit`/`SplashCubit`/`HomeCubit`, `ServeMemberAvatar` (`photoConsent: false` vs `true`), `DefaultErrorView` (`ForbiddenScopeError`), and RTL rendering.
- All 40 tests pass (`flutter test --coverage`: `73.68%` line coverage, `1008/1368` lines), `flutter analyze` reports `No issues found!`, `dart format --set-exit-if-changed .` exits `0`, and every hand-written `.dart` file in `lib/` and `test/` is <= 199 lines (well below the 300-line ceiling).

## Known Limitations / Follow-ups
- Per user decision on the foundation plan, the `identity` / login feature slice (`LoginRoute`, `/api/v1/auth/login`, OTP verification) is deferred to the next plan (`M1`).
- The sync engine (`OutboxProcessor`, `DeltaPuller`, `SyncCubit`) lands in `M2`.
