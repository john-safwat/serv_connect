# Walkthroughs

| Date | Area | Walkthrough | Summary |
| --- | --- | --- | --- |
| 2026-10-18 | backend | [Backend foundation](2026-10-18_backend_foundation.md) | Build setup, profiles, envelope, errors, i18n, security skeleton, sync/audit base entities, caching, logging, Docker image |
| 2026-10-18 | mobile | [Mobile foundation (M0)](2026-10-18_mobile_foundation.md) | Flutter Clean-Architecture + `BaseCubit` scaffold, native flavors (`dev`/`staging`/`prod`), AES-256 `HiveStorage`, `Dio` interceptors + `FR-1.3` offline grace window, warm editorial theme (`designs/main.main.svg`), 17 `Serve*` components, EN/AR + RTL, 40 tests |
| 2026-10-18 | dashboard | [Dashboard foundation (D0)](2026-10-18_dashboard_foundation.md) | React 19 + TS strict + Vite 8 foundation, warm editorial `tokens.css` (`designs/main.main.svg`), in-memory `AuthSession` + `IdleLockWatcher`, `HttpClient` + `RefreshMutexInterceptor`, 20 `Serve*` components, `AppShell`, EN/AR + RTL logical CSS, 23 tests |
