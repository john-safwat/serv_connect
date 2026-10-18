# Walkthrough — Web Dashboard Foundation (D0)

- **Date:** 2026-10-18
- **Plan:** [`plans/2026-10-18_cross_mobile-dashboard-foundation.md`](../../plans/2026-10-18_cross_mobile-dashboard-foundation.md)

## Summary

Implemented the **D0 Web Dashboard Foundation** in `serv_connect_dashboard/` (React 19, TypeScript 6 `strict`, Vite 8, oxlint, Vitest + React Testing Library + MSW). This establishes the unified warm editorial design system from `designs/main.main.svg`, the feature-first Clean Architecture spine (`use<Screen>Controller` + discriminated union `Action`s + `assertNever`), typed HTTP transport with `AcceptLanguageInterceptor`, `AuthInterceptor`, and `RefreshMutexInterceptor`, in-memory `AuthSession` + wall-clock `IdleLockWatcher`, permission/scope guards (`PermissionChecker`, `<RequirePermission>`, `<ScopeGuard>`), EN/AR localization with code-generated `LocaleKeys` and logical RTL styling, the 20-component `Serve*` Shared UI Component Catalogue, and the responsive `AppShell` + `OverviewShellPage`.

## BRD Coverage

| Requirement | Phase | Status | Notes |
| --- | --- | --- | --- |
| BRD §10, §11 (online-only admin console groundwork), §13 | MVP | Implemented | Core architecture, `ConnectivityWatcher`, `ServeOfflineBanner`, and TanStack Query setup |
| `FR-1.1–1.4` (Session, token refresh, idle lock infrastructure) | MVP | Foundation implemented | `AuthSession` (in-memory only), `RefreshMutexInterceptor`, `IdleLockWatcher` (login UI deferred to D1 per user decision) |
| `FR-13.1–13.5` (Safeguarding, permission/scope gating, photo consent) | MVP | Foundation implemented | `PermissionChecker`, `<RequirePermission>`, `<ScopeGuard>`, `ServeMemberAvatar` (`photoConsent === true` gate) |
| `FR-16.5`, `FR-16.6` (Feature flags, org custom labels, web admin console) | MVP / P2 | Foundation implemented | `FeatureFlagService`, `OrgLabelResolver` (`useOrgLabels()`), `AppShell` |
| `NFR-4`, `NFR-5`, `NFR-6`, `NFR-7` (Security, privacy, EN/AR RTL, WCAG AA a11y) | MVP | Implemented | HTTPS startup enforcement, PII-redacting `AppLogger`, EN/AR parity codegen, logical CSS properties |

## Design Screens Implemented

- `designs/main.main.svg` — Unified Warm Editorial Design System tokens (`--paper: #FBF6EC`, `--cream`/`--canvas: #F4EDE0`, `--red: #C0182A`, `--oxblood`/`--red-dark: #8C1420`, `--gold: #C6A15B`, `Inter` + `Fraunces` for EN, `Cairo` + `Amiri` for AR) and component primitives.
- `../Design/ServeConnect-Dashboard.html` & `../Design/ServeConnect-Dashboard-AR.html` — Desktop/tablet `AppShell` (collapsible sidebar with brand mark, grouped navigation, topbar with language switcher and notification button, and overview KPI/catalogue workspace).

## Files Changed

### Created / Modified in `serv_connect_dashboard/`
- **Configuration & Build:** `package.json`, `vite.config.ts`, `tsconfig.app.json`, `.oxlintrc.json`, `index.html`, `.env.example`, `.env.development` (gitignored), `scripts/i18n-codegen.mjs`
- **Design System Styles:** `src/styles/tokens.css`, `src/styles/global.css`
- **Localization (`en` + `ar`) & Codegen:** `src/locales/{en,ar}/{common,nav,errors,validation}.json`, `src/generated/locale_keys.g.ts`
- **Core (`src/core/`):**
  - `config/app_environment.ts`, `config/feature_flag_service.ts`
  - `logger/app_logger.ts`
  - `event_bus/app_event_bus.ts`, `event_bus/auth_event_bus.ts`
  - `format/app_formatters.ts`
  - `validation/validation.ts`, `validation/assert_never.ts`
  - `i18n/i18n.ts`, `i18n/locale_controller.ts`, `i18n/org_label_resolver.ts`
  - `permissions/permission_keys.ts`, `permissions/permission_checker.ts`, `permissions/use_permissions.ts`, `permissions/RequirePermission.tsx`, `permissions/scope_guard.tsx`
  - `session/auth_session.ts`, `session/idle_lock_watcher.ts`, `session/connectivity_watcher.ts`, `session/use_online_status.ts`
- **Network (`src/network/`):** `errors.ts`, `results.ts`, `resources.ts`, `base_api_response.ts`, `error_parser.ts`, `safe_call.ts`, `interceptors.ts`, `http_client.ts`
- **Shared `Serve*` UI Component Catalogue (`src/components/`):**
  - `primitives/`: `ServeButton`, `ServeIconButton`, `ServeTextField`, `ServeSelect`, `ServeBadge`, `ServeCard`, `ServeAvatar`, `avatar_utils`, `ServeMemberAvatar`, `ServeTabs`, `ServeModal`, `ServeDrawer`, `ServeTable` (+ `.module.css` files)
  - `shimmer/`: `ServeRowShimmer`, `ServeCardShimmer`, `ServeListShimmer`, `ServeTableShimmer`, `ServeShimmer.module.css`
  - `feedback/`: `DefaultErrorView`, `ServeEmptyState`, `ServeOfflineBanner`, `Toaster`, `toaster_store`, `ServeFeedback.module.css`
  - `index.ts`
- **App Shell & Initial Feature Slice (`src/app/`, `src/features/analytics/`):**
  - `src/main.tsx`, `src/app/{AppProviders.tsx, query_client.ts, AppRouter.tsx, AppShell.tsx, AppSidebar.tsx, AppTopbar.tsx, AppShell.module.css, nav_config.ts, RouteErrorBoundary.tsx, useAppShellStore.ts}`
  - `src/features/analytics/{index.ts, presentation/overview_shell/view/{OverviewShellPage.tsx, useOverviewShellController.ts, overviewShell.types.ts}, presentation/overview_shell/widgets/{OverviewShellContent.tsx, OverviewKpiGrid.tsx, OverviewCatalogueSection.tsx, overviewCatalogueColumns.tsx, OverviewShell.module.css}}`
- **Tests (`src/test/` & `src/**/*.test.{ts,tsx}`):**
  - `src/test/{setup.ts, msw_server.ts, render_with_providers.tsx}`
  - `src/core/config/app_environment.test.ts`
  - `src/core/logger/core_utilities.test.ts`
  - `src/core/session/session_and_permissions.test.tsx`
  - `src/network/http_client.test.ts`
  - `src/components/serve_components.test.tsx`
  - `src/app/app_shell.test.tsx`

### Removed Template Files
- `src/App.tsx`, `src/App.css`, `src/index.css`, `src/assets/`

### Documentation Created
- `docs/08-dashboard-architecture.md`
- `docs/walkthroughs/2026-10-18_dashboard_foundation.md`

## Routes & Navigation

- `/` (`OverviewShellPage` inside `AppShell`) and top-level navigation routes (`/schedule`, `/attendance`, `/tasks`, `/members`, `/groups`, `/communication`, `/content`, `/safeguarding`, `/settings`), plus `*` catch-all rendering `<DefaultErrorView />` (`404`).
- Sidebar items are filtered through `FeatureFlagService.isEnabled(...)` and `PermissionChecker.hasAnyScope(...)`.

## API Usage

- Configured `BaseApiResponse<T>` (`data`, `message`, `code`, `fieldErrors`) and `PagedContent<T>` in `src/network/base_api_response.ts`.
- Configured `RefreshMutexInterceptor` targeting `POST /api/v1/auth/refresh` on `401` responses.

## Security & Safeguarding Impact

- **In-memory tokens:** `AuthSession` keeps `accessToken` and `RoleAssignment`s strictly in JS memory; verified by unit tests that `localStorage` and `sessionStorage` never receive tokens or PII.
- **Idle session lock:** `IdleLockWatcher` computes remaining time from wall-clock (`targetTimestampMs - Date.now()`) and locks `AuthSession` + clears `QueryClient` on expiry.
- **Photo consent gate (`FR-13.5`):** `ServeMemberAvatar` checks `photoConsent === true` before rendering `<img src>` and falls back to initials when `false` (verified by component test).
- **Zero PII in URLs/logs:** Search state in `useOverviewShellController` stays in controller state (`window.location.search` remains empty); `AppLogger` auto-redacts sensitive keys and is a no-op in `prod`.

## Widgets

All 20 initial `Serve*` components were created in `src/components/` and catalogued in `docs/08-dashboard-architecture.md §5`.

## Localization

- Added 4 bilingual namespaces (`common`, `nav`, `errors`, `validation`) in `src/locales/en/` and `src/locales/ar/`.
- Generated `src/generated/locale_keys.g.ts` via `npm run i18n:generate` and verified parity via `npm run i18n:check`.
- Verified LTR (`en`, Inter + Fraunces) and RTL (`ar`, Cairo + Amiri) switching and logical CSS properties across all `.module.css` files.

## Testing

- **6 test suites, 23 tests passing** (`npm run test:coverage`):
  - Line coverage: **88%+** (exceeds ≥ 70% threshold).
  - Covers `AppEnvironment`, `FeatureFlagService`, `AppLogger` PII redaction, `AppFormatters`, `Validation`, `LocaleController`, `OrgLabelResolver`, `AuthSession`, `IdleLockWatcher`, `PermissionChecker`, `RequirePermission`, `ScopeGuard`, `HttpClient` + `RefreshMutexInterceptor` (concurrent `401` single refresh + `401` refresh failure logout + `403` `ScopeRevokedEvent`), `ServeMemberAvatar` (`photoConsent: false` gate), `Serve*` primitives/shimmers/feedback, `AppShell` LTR/RTL toggle, and `OverviewShellPage`.

## Config

- `.env.example` keys: `VITE_API_BASE_URL`, `VITE_ENV_NAME`, `VITE_DEFAULT_LOCALE`, `VITE_IDLE_TIMEOUT_MINUTES`.

## Known Limitations / Follow-ups

- Per user decision on 2026-10-18, the `identity` Login screen and `/api/v1/auth/login` integration will be implemented in the next plan (`D1`).
