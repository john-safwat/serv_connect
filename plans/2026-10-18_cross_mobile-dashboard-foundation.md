# Mobile & Dashboard Foundation (M0 + D0) — Plan

| Field | Value |
| --- | --- |
| Status | Done |
| Area | cross |
| BRD | §10, §11 (groundwork), §13, NFR-1, NFR-3, NFR-4, NFR-6, NFR-7, NFR-11, NFR-12 — foundation infrastructure (M0 + D0) for MVP modules |
| Phase | MVP (infrastructure) |
| Created | 2026-10-18 |
| Approved | 2026-10-18 — "Approve plan (plans/2026-10-18_cross_mobile-dashboard-foundation.md) and start building both Mobile and Dashboard in parallel" |
| Depends on | [Backend foundation](2026-10-18_backend_foundation.md) (shared envelope & conventions) |
| Walkthrough(s) | [2026-10-18_mobile_foundation](../docs/walkthroughs/2026-10-18_mobile_foundation.md), [2026-10-18_dashboard_foundation](../docs/walkthroughs/2026-10-18_dashboard_foundation.md) |
| Blocked / abandoned reason | — |

---

## 1. Goal

Initialize both client projects in the monorepo — the Flutter mobile client (`serv_connect_mobile/`, step **M0** of `serv_connect_mobile/CLAUDE.md §23.2`) using the `flutter-clean-cubit-scaffold` skill, and the React + TypeScript web dashboard (`serv_connect_dashboard/`, step **D0** of `serv_connect_dashboard/CLAUDE.md §23.2`) — wired to the ServeConnect design system in `designs/main.main.svg` (and its source specs in `../Design/Claude Design/ServeConnect-Mobile*.html` and `../Design/ServeConnect-Dashboard*.html`). This delivers compiling, lint-clean, tested foundations with Clean Architecture, result/error envelopes matching `BaseResponseBody`, auth/refresh/locale interceptors, encrypted on-device storage (mobile) and in-memory session + idle lock (dashboard), EN/AR localization with RTL-first directional layouts, native Android/iOS flavors (`dev`/`staging`/`prod`), the shared design-system tokens, and the initial `Serve*` UI component catalogues documented in `docs/07`–`docs/10`.

## 2. Scope & Decisions

| # | Decision | Choice |
| --- | --- | --- |
| 1 | `flutter-clean-cubit-scaffold` vs. `serv_connect_mobile/CLAUDE.md` | Overlay the scaffold's spine (`BaseCubit`, `ApiResult`, `Resources`, `Errors`, `DioModule`, `SecureStorage`, `Preferences`, `HiveStorage`, `LocaleCubit`, `AppRouter`, `di`, `.env.{dev,staging,prod}`) onto `serv_connect_mobile/`, **preserving** the existing `serv_connect_mobile/CLAUDE.md` (do not overwrite it with the scaffold's generic `CLAUDE.md`) and adapting every class to `serv_connect_mobile/CLAUDE.md`: AES-256 `HiveAesCipher` key in `SecureStorage`, `AcceptLanguageInterceptor`, offline session grace window (`FR-1.3`), `BaseApiResponse<T>` / `PagedContent<T>` envelope. |
| 2 | Shared Design System (`designs/main.main.svg`) across Mobile & Dashboard | Unify both Mobile and Dashboard on the `designs/main.main.svg` warm editorial palette: typography (`Inter` + `Fraunces` for EN; `Cairo` + `Amiri` for AR), core palette (Oxblood `#8C1420`, Bold Red `#C0182A` / `#D81E2C`, Gold `#C6A15B` / `#9C7C34` / `#B0862F`, Warm Paper `#FBF6EC`, Cream `#F4EDE0`, Ivory `#FFFFFF`, Ink `#1E1913` / `#141419`, Ink-2 `#4A4139`, Muted `#8C8173`, Line `#E7DDC9`, Line-2 `#DBCFB5`, Green `#3B7A54`, Amber `#B07C13`, Blue `#34568C` and their `-soft` tints) with CSS variable aliases in `tokens.css`. |
| 3 | Feature slices in Foundation (M0 / D0) | Per user decision, build **only the initial project foundation + app shell / initial route shell** (`SplashPage` and `HomePage` editorial shell on mobile; `AppShell` sidebar+topbar and initial `OverviewPlaceholderPage` on dashboard). The `identity` / login feature is deferred to the next plan (`M1` / `D1`). |
| 4 | Mobile Hive package | Use `hive_ce` + `hive_ce_flutter` (or `hive` / `hive_flutter`) with `HiveAesCipher` 256-bit key stored in `SecureStorage`, storing JSON maps (`Map<String, dynamic>`) — no `hive_generator`. |
| 5 | Native flavorizr execution | Initialize native Android/iOS flavors (`dev`, `staging`, `prod`) with `flavorizr.yaml` and native Gradle productFlavors / Xcode `.xcconfig` & schemes (`com.john.serv_connect_mobile.{dev,staging}`, `com.john.serv_connect_mobile`). |
| 6 | Strict file & function size limits | Every hand-written `.dart`, `.ts`, and `.tsx` file is ≤ 250–300 lines, and every function / method / `build()` / component body is ≤ 20–25 lines (`serv_connect_mobile/CLAUDE.md §9.1`, `serv_connect_dashboard/CLAUDE.md §9.1`). |

### 2.1 Non-goals

- Implementing backend `/api/v1/*` endpoints (covered by backend plans).
- The `identity` / login feature slice (deferred to the next task per user decision) and domain modules M1–M7 (`members`, `groups`, `schedule`, `attendance`, `tasks`, `communication`, `curriculum`, `content`, `engagement`, `trips`, `notifications`, `safeguarding`, `audit`, `analytics`, `prayer`, `admin`) beyond foundation primitives (`PermissionChecker`, `ScopeGuard`, `ServeMemberAvatar`).
- Firebase (`google-services.json` / `GoogleService-Info.plist`) and push notification wiring (lands in M6 `notifications`).

## 3. Current State

- `designs/main.main.svg`: 2,635-line vector specification of the ServeConnect design system (swatches, typography, buttons, badges, inputs, cards, avatars, progress bars, tabs, sheets, shimmers, and screen frames). `../Design/` also holds `ServeConnect-Dashboard.html`, `ServeConnect-Dashboard-AR.html`, `Claude Design/ServeConnect-Mobile.html`, and `Claude Design/ServeConnect-Mobile-AR.html`.
- `serv_connect_mobile/`: fresh `flutter create` skeleton (`lib/main.dart` counter app, `pubspec.yaml` with `sdk: ^3.13.5` and `cupertino_icons` only, `serv_connect_mobile/CLAUDE.md`).
- `serv_connect_dashboard/`: bare Vite 8 + React 19 + TypeScript 6 + oxlint skeleton (`src/App.tsx`, `src/main.tsx`, `package.json` with `react` and `react-dom` only, `serv_connect_dashboard/CLAUDE.md`).
- `docs/`: currently contains only `00-brd.md` (and `plans/2026-10-18_backend_foundation.md` is Approved).

## 4. Design

### 4.1 Backend

N/A — client foundation only (`serv_connect_mobile/` and `serv_connect_dashboard/`). Consumes the `BaseResponseBody<T>` and `PageResponse<T>` envelope conventions defined in `plans/2026-10-18_backend_foundation.md`.

### 4.2 Mobile (`serv_connect_mobile/` — M0 Foundation)

Built from `.agents/skills/flutter-clean-cubit-scaffold` and adapted to `serv_connect_mobile/CLAUDE.md`:

- **Entrypoints & Config:**
  - `lib/main.dart`, `lib/main_dev.dart`, `lib/main_staging.dart`, `lib/main_prod.dart`
  - `lib/bootstrap.dart` (loads `.env.<flavor>`, runs `AppEnvironment.assertConfigured()`, initializes `HiveStorage`, hydrates `AuthSession`, configures `getIt`, launches `EasyLocalization` + `ServeConnectApp`)
  - `lib/app.dart` (`ServeConnectApp` with `MaterialApp.router`, `LocaleCubit`, `AuthEventBus` listener)
  - `.env.example` (tracked) + `.env.dev`, `.env.staging`, `.env.prod` (gitignored) with keys: `API_BASE_URL`, `ENV_NAME`, `DEFAULT_OFFLINE_GRACE_DAYS`, `MEDIA_CACHE_MAX_MB`, `SYNC_BATCH_SIZE`, `SENTRY_DSN`
  - `flavorizr.yaml`, `analysis_options.yaml` (strict casts/inference/raw-types + lint rules)
- **Core (`lib/core/`):**
  - `base/base_cubit.dart`: `BaseCubit<T, A, NE>` with `doAction(A)` and broadcast `Stream<NE> navigation`
  - `config/`: `app_environment.dart`, `app_environment_loader.dart`, `flavor_config.dart`, `feature_flag_service.dart`
  - `event_bus/`: `app_event_bus.dart`, `auth_event_bus.dart` (`ScopeRevokedEvent`, `SyncCompletedEvent`, `ForceLogoutEvent`)
  - `l10n/`: `locale_cubit.dart`, `org_label_resolver.dart`
  - `logger/`: `app_logger.dart` (PII-scrubbing, no-op in release)
  - `permissions/`: `permission_keys.dart`, `scope_type.dart`, `role_assignment.dart`, `permission_checker.dart`
  - `platform/`: `serve_platform.dart`, `serve_platform_method_channel.dart`
  - `services/`: `auth_session.dart` (with `AuthenticatedOnline`, `AuthenticatedOffline`, `OfflineGraceExpired`, `Unauthenticated` states per `FR-1.3`), `connectivity_service.dart`
  - `storage/`: `storage_keys.dart`, `secure_storage.dart`, `preferences.dart`, `hive_storage.dart` (AES-256 `HiveAesCipher` with key in `SecureStorage`, opening encrypted JSON document boxes)
  - `theme/`:
    - `app_colors.dart` — exact tokens from `designs/main.main.svg`:
      - `ink` (`0xFF1E1913`), `ink2` (`0xFF4A4139`), `muted` (`0xFF8C8173`)
      - `cream` (`0xFFF4EDE0`), `paper` (`0xFFFBF6EC`), `ivory` (`0xFFFFFFFF`)
      - `line` (`0xFFE7DDC9`), `line2` (`0xFFDBCFB5`)
      - `red` (`0xFFC0182A`), `oxblood` (`0xFF8C1420`), `redSoft` (`0xFFF6E5E1`)
      - `gold` (`0xFFB0862F`), `gold2` (`0xFFC6A15B`), `goldDark` (`0xFF9C7C34`), `goldSoft` (`0xFFEFE2C4`)
      - `green` (`0xFF3B7A54`), `greenSoft` (`0xFFE6F0E7`)
      - `amber` (`0xFFB07C13`), `amberSoft` (`0xFFF5E9CD`)
      - `blue` (`0xFF34568C`), `blueSoft` (`0xFFE6EBF4`)
    - `app_typography.dart` — `Fraunces` (display/serif) + `Inter` (UI sans) for `en`; `Amiri` (display/serif) + `Cairo` (UI sans) for `ar`
    - `app_theme.dart`, `serve_breakpoints.dart`, `serve_spacing.dart`
  - `utils/`: `app_formatters.dart`, `validation.dart`, `id_generator.dart`
  - `common_ui/` (`Serve*` Shared UI Component Catalogue matching `designs/main.main.svg`):
    - `buttons/serve_button.dart` (variants: `primaryRed`, `ink`, `gold`, `outline`, `soft`; 48dp min hit target; `isLoading`)
    - `buttons/serve_icon_button.dart` (48dp min hit target, required localized tooltip)
    - `inputs/serve_text_field.dart` (ivory fill, `line2` border, prefix/suffix icon, error text)
    - `cards/serve_card.dart` (ivory elevated & paper flat variants, 18px radius, `line` border)
    - `badges/serve_badge.dart` (pill badges with dot indicator: `red`, `gold`, `green`, `amber`, `blue`, `gray`, `line`)
    - `avatars/serve_avatar.dart` & `avatars/serve_member_avatar.dart` (enforces `photoConsent == true` gate; falls back to serif initials on `goldSoft`/`redSoft`/`greenSoft`/`blueSoft`)
    - `controls/serve_segmented_control.dart` (`#EAE1CF` track with ivory active pill)
    - `feedback/serve_empty_state.dart`, `feedback/default_error_view.dart`, `feedback/serve_sync_banner.dart`, `feedback/toaster.dart`, `feedback/bottom_sheet_host.dart`
    - `shimmer/serve_shimmer_box.dart`, `shimmer/serve_list_shimmer.dart`, `shimmer/serve_card_shimmer.dart`, `shimmer/serve_row_shimmer.dart` (`#ECE4D3` → `#F6F1E6` warm editorial shimmer)
- **Network (`lib/network/`):**
  - `results.dart` (`ApiResult<T>`: `Success<T>`, `Failure<T>`)
  - `resources.dart` (`Resources<T>` preserving cached `data` during loading/failure)
  - `errors.dart` (sealed `Errors`: `NetworkError`, `TimeoutError`, `ParseError`, `ServerError`, `ForbiddenScopeError`, `FeatureDisabledError`, `SyncConflictError`, `LoginRequired`, `StorageError`, `PlatformError`, `JustMessage`, `Unknown`)
  - `base_api_response.dart` (`BaseApiResponse<T>`, `PagedContent<T>`)
  - `error_parser.dart`, `safe_call.dart`, `dio_module.dart`
  - `interceptors/`: `accept_language_interceptor.dart`, `auth_interceptor.dart`, `refresh_interceptor.dart` (with `Mutex` + offline grace window check), `logging_interceptor.dart` (UUID-only path + status code, zero headers/bodies)
- **DI & Routing (`lib/di/`, `lib/routing/`):**
  - `lib/di/injection.dart`, `network_module.dart`, `storage_module.dart`, `retrofit_module.dart`
  - `lib/routing/app_router.dart` (`@AutoRouterConfig`), `guards/auth_guard.dart`, `guards/scope_guard.dart`
- **Initial Feature Slices (`lib/features/`):**
  - `splash/`: `SplashPage`, `SplashCubit`, `SplashStates` (checks `AuthSession` including offline grace window)
  - `identity/`: canonical Clean-Architecture slice from the skill (`domain/entities`, `domain/repository`, `domain/use_case`, `data/datasource/remote`, `data/datasource/local`, `data/model`, `data/mapper`, `data/repository`, `presentation/login/{view,widgets}`) styled with the `designs/main.main.svg` Frame 1 Sign-In design
  - `home/`: `HomePage` shell with the 5-tab editorial bottom navigation bar (`Home`, `Schedule`, `Attend`, `Word`, `More`) and `ServeSyncBanner`

### 4.3 Dashboard (`serv_connect_dashboard/` — D0 Foundation)

Built according to `serv_connect_dashboard/CLAUDE.md §1, §9–§23` and styled with the ServeConnect design system:

- **Dependencies & Tooling (`package.json`, `vite.config.ts`, `tsconfig*.json`, `.env.example`):**
  - Sanctioned packages: `react-router`, `@tanstack/react-query`, `zustand`, `react-hook-form`, `@hookform/resolvers`, `zod`, `i18next`, `react-i18next`, `dompurify`, `@types/dompurify`
  - Dev/Test packages: `vitest`, `@testing-library/react`, `@testing-library/user-event`, `@testing-library/jest-dom`, `jsdom`, `msw`, `@playwright/test`
  - Scripts: `dev`, `build`, `lint`, `test`, `test:coverage`, `i18n:generate`, `i18n:check`
  - `.env.example` + `.env.development` (gitignored): `VITE_API_BASE_URL`, `VITE_ENV_NAME`, `VITE_DEFAULT_LOCALE`, `VITE_IDLE_TIMEOUT_MINUTES`
- **Design Tokens & Global Styles (`src/styles/`):**
  - `tokens.css`: Unified ServeConnect CSS custom properties supporting both the warm editorial tokens from `designs/main.main.svg` and the dashboard tokens in `serv_connect_dashboard/CLAUDE.md §13.2` (`--white`, `--paper`, `--cream`, `--canvas`, `--ink`, `--ink-2`, `--muted`, `--line`, `--line-2`, `--red`, `--oxblood`, `--red-dark`, `--red-soft`, `--gold`, `--gold-2`, `--gold-dark`, `--gold-soft`, `--green`, `--green-soft`, `--amber`, `--amber-soft`, `--blue`, `--blue-soft`, `--r-sm`..`--r-xl`, `--shadow`, `--shadow-sm`, `--font`, `--serif`)
  - `global.css`: logical RTL-ready reset, Google Fonts (`Inter`, `Fraunces`, `Cairo`, `Amiri`), `[dir="rtl"]` font switching, `:focus-visible` accessibility rings, `@media (prefers-reduced-motion: reduce)`
- **Core (`src/core/`):**
  - `config/`: `app_environment.ts` (startup assertion `assertConfigured()`), `feature_flag_service.ts`
  - `event_bus/`: `app_event_bus.ts`, `auth_event_bus.ts`
  - `format/`: `app_formatters.ts` (UTC ISO-8601, `LocalDateString`, `orgTimeZone`, `Intl` date/number/relative formatters)
  - `i18n/`: `i18n.ts`, `locale_controller.ts` (sets `<html lang dir>`), `org_label_resolver.ts`, `scripts/i18n-codegen.mjs` (generates `src/generated/locale_keys.g.ts` and checks EN/AR parity)
  - `logger/`: `app_logger.ts` (PII-redacting, no-op in `prod`)
  - `permissions/`: `permission_keys.ts`, `permission_checker.ts`, `RequirePermission.tsx`, `scope_guard.tsx`
  - `session/`: `auth_session.ts` (in-memory `accessToken` only, zero browser storage of tokens/PII), `idle_lock_watcher.ts` (wall-clock inactivity timer clearing `AuthSession` + `queryClient`)
  - `validation/`: `validation.ts` (centralized Zod schemas returning localized keys)
- **Network (`src/network/`):**
  - `errors.ts` (`AppError` discriminated union), `results.ts` (`ApiResult<T>`), `resources.ts` (`Resources<T>` preserving `data` on refetch), `base_api_response.ts` (`BaseApiResponse<T>`, `PagedContent<T>`)
  - `error_parser.ts`, `safe_call.ts`, `http_client.ts` (with `AcceptLanguageInterceptor`, `AuthInterceptor`, and `RefreshMutexInterceptor` serializing concurrent `401` refreshes)
- **Shared `Serve*` UI Component Catalogue (`src/components/`):**
  - `primitives/`: `ServeButton`, `ServeIconButton`, `ServeTextField`, `ServeSelect`, `ServeBadge`, `ServeCard`, `ServeModal`, `ServeDrawer`, `ServeTabs`, `ServeTable`, `ServeAvatar`, `ServeMemberAvatar` (`photoConsent === true` gate)
  - `shimmer/`: `ServeListShimmer`, `ServeTableShimmer`, `ServeCardShimmer`, `ServeRowShimmer`
  - `feedback/`: `DefaultErrorView` (handles `ForbiddenScopeError` 403, `NotFoundError` 404, generic retry), `ServeEmptyState`, `ServeOfflineBanner`, `Toaster`
- **App Shell & Initial Feature Slice (`src/app/`, `src/features/`):**
  - `src/app/`: `AppProviders.tsx`, `AppRouter.tsx`, `AppShell.tsx` (collapsible sidebar with brand logo, grouped nav items, language switcher, user footer + topbar + offline banner matching `ServeConnect-Dashboard.html`), `RouteErrorBoundary.tsx`, `useAppShellStore.ts`
  - `src/features/identity/`: `LoginPage.tsx`, `useLoginController.ts`, `login.types.ts` (discriminated union `LoginAction` + `assertNever`)

### 4.4 API contract changes (`docs/03-api-reference.md`)

No new `/api/v1` endpoints added in this plan. Both clients configure their `BaseApiResponse<T>` / `PagedContent<T>` / `ErrorParser` envelopes to match `plans/2026-10-18_backend_foundation.md` (`data`, `message`, `code`, `fieldErrors`).

### 4.5 Sync (`docs/06-sync.md`)

| Entity | Syncable? | Conflict strategy | Scope filter |
| --- | --- | --- | --- |
| — (Encrypted `HiveStorage` foundation only) | groundwork | per entity in M2 (`sync` plan) | per entity in M2 |

## 5. Security & Safeguarding

- **Permissions added/used:** `PermissionChecker`, `ScopeType` (`ORG`, `STAGE`, `GROUP`, `SELF`, `CHILDREN`), and `<RequirePermission>` / `ScopeGuard` infrastructure built in both clients; never branches on role names.
- **Data classification:**
  - `ServeMemberAvatar` on both Mobile and Dashboard enforces `photoConsent == true` before rendering any network image URL, falling back to deterministic initials when `false`.
  - `AppLogger` on both Mobile and Dashboard scrubs `authorization`, `password`, `otp`, `token`, `phone`, `email`, `medical`, `note` and is a no-op in release/prod builds.
  - Network logging interceptors log only HTTP method, opaque path, and status code — never headers or bodies.
- **On-device / browser storage:**
  - Mobile: `accessToken`, `refreshToken`, and the 256-bit Hive encryption key live exclusively in `SecureStorage` (`flutter_secure_storage`). All Hive boxes open via `HiveStorage` with `HiveAesCipher`.
  - Dashboard: `accessToken` lives exclusively in memory (`AuthSession`); zero tokens or member/PII records in `localStorage`/`sessionStorage`/`IndexedDB`. `IdleLockWatcher` wipes `AuthSession` and `queryClient` after `VITE_IDLE_TIMEOUT_MINUTES`.

## 6. Localization

- **New keys (`en` + `ar`):**
  - `common.*`: app name, default role labels (`role_servant`, `role_served_member`, `stage`, `group`), action labels (`save`, `cancel`, `retry`, `continue_btn`, `sign_in`, `sign_out`, `search`, `loading`, `offline_banner`, `offline_mutations_disabled`, `synced`)
  - `nav.*`: mobile tabs (`home`, `schedule`, `attend`, `word`, `more`) and dashboard sidebar groups/items (`overview`, `members`, `groups`, `schedule`, `attendance`, `tasks`, `communication`, `curriculum`, `content`, `engagement`, `trips`, `prayer`, `analytics`, `safeguarding`, `users_roles`, `settings`)
  - `identity.*`: sign-in title, subtitle, email/phone label, password label, sign-in CTA, request access, idle lock message
  - `errors.*`: `generic`, `network`, `timeout`, `unauthorized`, `forbidden_scope`, `feature_disabled`, `not_found`, `conflict`, `scope_revoked`, `config_missing`
  - `validation.*`: `required`, `invalid_email`, `invalid_phone`, `password_too_short`, `invalid_otp`
- **RTL considerations:**
  - Mobile: all padding, alignment, and borders use `EdgeInsetsDirectional`, `AlignmentDirectional`, `BorderRadiusDirectional`; Arabic switches font family to `Cairo` + `Amiri`.
  - Dashboard: all CSS Modules use logical properties (`margin-inline-start`, `padding-inline`, `inset-inline-start`, `border-inline-start`, `text-align: start`); `<html lang="ar" dir="rtl">` switches `--font` to `Cairo` and `--serif` to `Amiri`.

## 7. Testing

- **Backend:** N/A.
- **Mobile (`serv_connect_mobile/test/`):**
  - Unit tests: `ErrorParser`, `safeCall`, `AppEnvironment`, `PermissionChecker` (in-scope vs. out-of-scope), `Validation`, `AppFormatters`, `AuthSession` (including offline session grace window `FR-1.3`).
  - Cubit tests (`bloc_test`): `LocaleCubit`, `SplashCubit`, `LoginCubit` (`Success` and `Failure` paths).
  - Widget tests: `ServeButton`, `ServeMemberAvatar` (verifying `photoConsent: false` never loads network image), `DefaultErrorView` (including `ForbiddenScopeError`), RTL rendering check (`Directionality.rtl`).
- **Dashboard (`serv_connect_dashboard/src/`):**
  - Unit tests (Vitest): `AppEnvironment.assertConfigured()`, `ErrorParser`, `safeCall`, `PermissionChecker`, `AppFormatters`, `Validation` schemas, `AuthSession` + `RefreshMutexInterceptor` (concurrent `401` single refresh), `IdleLockWatcher` (wall-clock expiry clears session).
  - Component & Controller tests (Vitest + RTL + MSW): `ServeButton`, `ServeMemberAvatar` (`photoConsent: false` gate), `RequirePermission`, `DefaultErrorView` (`403` `ForbiddenScopeError`), `AppShell` (LTR `en` and RTL `ar`), `useLoginController` + `LoginPage` (zero PII in URL/storage).
- **Quality gates:**
  - Mobile: `dart format --set-exit-if-changed .`, `flutter analyze`, `flutter test --coverage`, and file/method line-limit check all exit `0`.
  - Dashboard: `npm run lint`, `npm run build`, `npm run i18n:check`, `npm test`, and file/function line-limit check all exit `0`.

## 8. Docs to Update

- [x] `docs/01-project-overview.md` — create/update with monorepo overview, mobile M0 & dashboard D0 foundation status, and `.env.example` tables
- [x] `docs/04-security.md` — create/update with client security rules (`SecureStorage`, `HiveAesCipher`, in-memory `AuthSession`, `IdleLockWatcher`, `ServeMemberAvatar` photo-consent gate)
- [x] `docs/05-localization.md` — create/update with EN/AR key namespaces, codegen commands, `OrgLabelResolver`, and RTL logical layout rules
- [x] `docs/07-mobile-architecture.md` — create with Flutter Clean Architecture, `BaseCubit`, `ApiResult`, `Resources`, `Errors`, `HiveStorage`, and offline grace window
- [x] `docs/08-mobile-theme-and-ui-components.md` — create with `designs/main.main.svg` tokens (`AppColors`, `AppTypography`) and the `Serve*` Shared UI Component Catalogue
- [x] `docs/08-dashboard-architecture.md` — create with Dashboard Clean Architecture (`use<Screen>Controller`, `ApiResult`, `Resources`, `AppError`, `AuthSession`, `IdleLockWatcher`, `tokens.css`) and the Dashboard `Serve*` Shared UI Component Catalogue
- [x] `docs/09-mobile-routing-and-di.md` — create with `AppRouter`, `AuthGuard`, `ScopeGuard`, and `get_it`/`injectable` modules
- [x] `docs/10-mobile-platform-native.md` — create with Android/iOS flavors (`dev`/`staging`/`prod`) and `ServePlatform` channel architecture
- [x] `docs/README.md` — create/update index of all docs
- [x] Walkthroughs: `docs/walkthroughs/2026-10-18_mobile_foundation.md`, `docs/walkthroughs/2026-10-18_dashboard_foundation.md`, and `docs/walkthroughs/README.md`

## 9. Work Breakdown

Commit-sized steps, in order. Wave B1 (`flutter-developer`) and Wave B2 (`web-developer`) touch disjoint project directories and can execute in parallel once approved.

- [x] 1. **Mobile M0.1 — Scaffold, Dependencies, Flavors & Core Config (`flutter-developer`)** — files: `serv_connect_mobile/{pubspec.yaml, analysis_options.yaml, flavorizr.yaml, .env.example, .gitignore, lib/main*.dart, lib/bootstrap.dart, lib/core/config/*, lib/core/logger/*, lib/core/event_bus/*, lib/core/base/base_cubit.dart}` — verify: `flutter pub get` succeeds.
- [x] 2. **Mobile M0.2 — Encrypted Storage, Session, Permissions & Network Spine (`flutter-developer`)** — files: `serv_connect_mobile/lib/{core/storage/*, core/services/*, core/permissions/*, core/platform/*, core/utils/*, network/*, di/*}` — verify: `dart run build_runner build --delete-conflicting-outputs` generates `injection.config.dart` and `*.g.dart` cleanly.
- [x] 3. **Mobile M0.3 — Design System Theme, `Serve*` UI Catalogue, l10n & Initial Feature Slices (`flutter-developer`)** — files: `serv_connect_mobile/{assets/translations/{en,ar}.json, lib/generated/*, lib/core/l10n/*, lib/core/theme/*, lib/core/common_ui/**, lib/routing/*, lib/app.dart, lib/features/{splash,home}/**}` — verify: `flutter analyze` exits `0` and all files ≤ 300 lines.
- [x] 4. **Mobile M0.4 — Mobile Unit, Cubit & Widget Tests (`flutter-developer`)** — files: `serv_connect_mobile/test/**` — verify: `flutter test --coverage` passes with ≥ 70% coverage (73.68% achieved).
- [x] 5. **Dashboard D0.1 — Dependencies, Scripts, Env Config, Tokens & i18n Codegen (`web-developer`)** — files: `serv_connect_dashboard/{package.json, vite.config.ts, tsconfig*.json, .env.example, .gitignore, scripts/i18n-codegen.mjs, src/locales/{en,ar}/*.json, src/generated/locale_keys.g.ts, src/styles/{tokens.css,global.css}, src/core/config/*, src/core/logger/*, src/core/event_bus/*, src/core/format/*, src/core/validation/*, src/core/i18n/*}` — verify: `npm run i18n:generate && npm run i18n:check` and `npm run lint` pass.
- [x] 6. **Dashboard D0.2 — Session, Idle Lock, Permissions & Network Layer (`web-developer`)** — files: `serv_connect_dashboard/src/{core/session/*, core/permissions/*, network/*}` — verify: `npm run lint` and `tsc -b` pass.
- [x] 7. **Dashboard D0.3 — Dashboard `Serve*` UI Catalogue, `AppShell` & Routing (`web-developer`)** — files: `serv_connect_dashboard/src/{components/**, app/**, features/overview/**, main.tsx}` — verify: `npm run lint` and `npm run build` exit `0` and all files ≤ 300 lines.
- [x] 8. **Dashboard D0.4 — Dashboard Unit, Hook & Component Tests (`web-developer`)** — files: `serv_connect_dashboard/src/test/**`, `serv_connect_dashboard/src/**/*.test.{ts,tsx}` — verify: `npm test` passes with ≥ 70% coverage (87.56% achieved).
- [x] 9. **Shared & Project Architecture Documentation + Walkthroughs (`flutter-developer` + `web-developer`)** — files: `docs/{README.md, 01-project-overview.md, 04-security.md, 05-localization.md, 07-mobile-architecture.md, 08-mobile-theme-and-ui-components.md, 08-dashboard-architecture.md, 09-mobile-routing-and-di.md, 10-mobile-platform-native.md, walkthroughs/*}` — verify: `git status -- docs/ plans/`.

## 10. Acceptance Criteria

- [x] `serv_connect_mobile`: `dart format --set-exit-if-changed .`, `flutter analyze`, and `flutter test --coverage` exit `0` with zero warnings and ≥ 70% coverage (73.68%).
- [x] `serv_connect_dashboard`: `npm run lint`, `npm run build`, `npm run i18n:check`, and `npm test` exit `0` with zero warnings and ≥ 70% coverage (87.56%).
- [x] Every hand-written `.dart`, `.ts`, and `.tsx` file is ≤ 300 lines, and every function/method/component body is ≤ 25 lines.
- [x] Both projects use the ServeConnect design system tokens from `designs/main.main.svg` (`AppColors` / `AppTypography` in Flutter; `src/styles/tokens.css` in React) with zero hardcoded hex colors in feature widgets/components.
- [x] Both projects support `en` (LTR, Inter + Fraunces) and `ar` (RTL, Cairo + Amiri) with directional layouts only (`EdgeInsetsDirectional` in Flutter; CSS logical properties in Dashboard).
- [x] Safeguarding foundation verified by automated tests: `ServeMemberAvatar` hides photo URL when `photoConsent` is `false`; `HiveStorage` uses `HiveAesCipher` with key in `SecureStorage`; Dashboard `AuthSession` keeps `accessToken` in memory only and `IdleLockWatcher` locks on timeout; zero PII in logs or URLs.
- [x] `serv_connect_mobile/CLAUDE.md` and `serv_connect_dashboard/CLAUDE.md` remain intact; all docs in §8 and walkthroughs are created and indexed.

## 11. Open Decisions

| # | Question | Options | Answer (date) |
| --- | --- | --- | --- |
| 1 | **Design System Palette Alignment (`designs/main.main.svg`):** The SVG uses the Warm Editorial palette (Oxblood `#8C1420`, Bold Red `#C0182A` & `#D81E2C`, Gold `#C6A15B` & `#9C7C34`, Warm Paper `#FBF6EC`, Cream `#F4EDE0`, Line `#E7DDC9`). Should **both** Mobile and Dashboard use this exact warm editorial palette as their primary tokens (while keeping the `--canvas`, `--paper`, `--red`, `--gold` CSS variable names in `tokens.css`), or should Dashboard keep the slightly cooler paper (`#FBFAF8` / `#F2F1ED`) from `ServeConnect-Dashboard.html`? | (a) Unify both Mobile and Dashboard on the `designs/main.main.svg` warm editorial tokens (with aliases for all `tokens.css` variable names so both match the SVG design system) — **recommended**; (b) Use warm cream (`#FBF6EC`/`#F4EDE0`) on Mobile and neutral paper (`#FBFAF8`/`#F2F1ED`) on Dashboard | (a) Unify both Mobile and Dashboard on the `designs/main.main.svg` warm editorial palette (2026-10-18) |
| 2 | **Sample Auth/Identity Slice in Foundation:** The `flutter-clean-cubit-scaffold` skill includes a full sample `login` feature slice (`domain`, `data`, `presentation`). Since the backend `/api/v1/auth/login` endpoint lands in the next plan (`identity`), how should we include the login slice now? | (a) Include the full `features/identity/presentation/login` Clean-Architecture slice in both Mobile and Dashboard styled after the `designs/main.main.svg` Sign-In screen, wired to the real `Dio`/`HttpClient` contract path (`/api/v1/auth/login`) and verified via unit/widget/MSW tests — **recommended**; (b) Include only a static placeholder screen until the backend `identity` plan is built | (b) Initial project foundation + app shell only; login feature comes next (2026-10-18) |
| 3 | **Native Flavorizr Execution (`flutter_flavorizr`):** Should we run `flutter_flavorizr` to rewrite the native Android/iOS Gradle & Xcode Runner projects now, or keep `flavorizr.yaml` + Dart flavor entrypoints (`lib/main_{dev,staging,prod}.dart`) without modifying native Xcode/Gradle files yet? | (a) Keep `flavorizr.yaml` + `lib/main_{dev,staging,prod}.dart` without rewriting Xcode/Gradle native runners (per `scaffold.sh` default, safe and fast) — **recommended**; (b) Run `flutter_flavorizr` to rewrite native Android/iOS files now | (b) Initialize native Android/iOS flavors (`dev`, `staging`, `prod`) now (2026-10-18) |

## 12. Risks & Mitigations

| Risk | Mitigation |
| --- | --- |
| Pinned package versions in `flutter-clean-cubit-scaffold` vs. local Flutter/Dart `^3.13.5` SDK | Run `flutter pub get` (and `flutter pub upgrade --major-versions` if any constraint conflicts with Dart 3.13), then run `build_runner` and `easy_localization:generate`. |
| Strict file (≤ 300 lines) and function/method/build (≤ 25 lines) limits in both `CLAUDE.md` files | Decompose every widget, sub-widget, mapper, and controller helper into small single-responsibility files and functions; run the `awk` line-count gate before completion. |
| Parallel execution of `flutter-developer` and `web-developer` touching shared `docs/` | Assign disjoint `docs/` files to each agent (`07`, `08-mobile-*`, `09`, `10` to `flutter-developer`; `08-dashboard-*` to `web-developer`) and coordinate `01`, `04`, `05`, `README.md` after both complete. |

## 13. Progress Log

- 2026-10-18 — Plan drafted (`plans/2026-10-18_cross_mobile-dashboard-foundation.md`) covering Mobile (M0 via `flutter-clean-cubit-scaffold`) and Dashboard (D0) foundations with the shared `designs/main.main.svg` design system.
- 2026-10-18 — Approved by user: (1) unify both Mobile & Dashboard on `designs/main.main.svg` warm editorial palette; (2) scaffold initial foundation + app shell only (login feature comes next); (3) initialize native Android/iOS flavors (`dev`, `staging`, `prod`). Status set to `In progress`.
- 2026-10-18 — Completed Steps 1–4 (`serv_connect_mobile/` M0, commit `8926074`): Clean-Architecture + `BaseCubit` scaffold, native Android/iOS flavors (`dev`/`staging`/`prod`), AES-256 `HiveStorage`, `Dio` interceptors + `FR-1.3` offline grace window, warm editorial theme (`designs/main.main.svg`), 17 `Serve*` components, EN/AR + RTL, 40 passing tests (73.68% line coverage), and mobile docs (`docs/07`–`docs/10`, `docs/walkthroughs/2026-10-18_mobile_foundation.md`).
- 2026-10-18 — Completed Steps 5–9 (`serv_connect_dashboard/` D0 + shared docs, commit `f555547`): React 19 + TS strict + Vite 8 + oxlint foundation, unified warm editorial `tokens.css` (`designs/main.main.svg`), in-memory `AuthSession` + `IdleLockWatcher`, `HttpClient` + `RefreshMutexInterceptor`, 20 `Serve*` components, `AppShell`, EN/AR + RTL logical CSS, 23 passing tests (87.56% line coverage), and dashboard/shared docs (`docs/01`, `04`, `05`, `08-dashboard-architecture.md`, `docs/walkthroughs/2026-10-18_dashboard_foundation.md`). Status set to `Done`.
