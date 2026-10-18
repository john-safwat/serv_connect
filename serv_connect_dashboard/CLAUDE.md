# ServeConnect — React Web Dashboard (`serv_connect_dashboard`) — Claude Development Rules

> **Claude must read and follow every rule in this file before starting _any_ task.**
> These rules are non-negotiable and apply to **every kind of work** — a new feature, a bug fix, a refactor, a chore, a one-line hot-fix, a spike, or a question whose answer leads to a code change. "It's only a small change" is never grounds to skip a rule.
>
> A task does not end with the page rendering, `npm run lint` passing, or `npm run build` succeeding. **A task ends only when its plan file (`plans/*.md`) and the relevant `docs/*.md` files have been updated** to reflect the change (see §25 — Post-Task Documentation Updates). Any change that alters behaviour without touching the matching docs is incomplete.
>
> **Scope:** the **ServeConnect** web dashboard in `serv_connect_dashboard/` of the ServeConnect monorepo (**React 19 + TypeScript 6 (`strict`) + Vite 8, npm, oxlint**). It is the **administration and leadership console** for a church running ServeConnect (paired with the Spring Boot Kotlin backend in `sev_connect_backend/` and the Flutter mobile client in `serv_connect_mobile/`): service leaders, stage coordinators, and administrators use it on desktop/tablet to manage members, groups, schedules, attendance and follow-up oversight, tasks, content, users and roles, safeguarding/audit, analytics, and settings. Because the system holds data about **minors**, every member-identifying field is treated as **PII** and every pastoral/medical/consent field as **Sensitive** by default (see §7 & §17 — Security, Safeguarding & PII Handling).
>
> **Repo-wide rules.** The root `../CLAUDE.md` applies on top of this file (plans folder, shared docs, API contract, cross-project security, git). This file adds the dashboard-specific rules; on security/safeguarding/PII/audit the stricter of the two wins.
>
> **BRD position.** BRD §4.2 lists a *servant web client* as out of scope and calls a web/admin console a **Phase 2/3 candidate** (`FR-16.6`). The user decided on 2026-10-18 to build this dashboard. It is the **admin/leadership console**, not a web copy of the servant mobile app: the weekly servant loop (taking attendance in the room offline) stays on mobile. Every dashboard plan still cites the `FR-x.y` IDs it covers and their phase, and flags any screen that would turn the dashboard into a servant client.
>
> **Its own UI.** The dashboard has a **different UI from the mobile app**. Its design reference is the **Dashboard** design set (§11) — never the mobile screens. Shared across projects are the domain vocabulary, the API contract, and the brand identity, not layouts or components.
>
> **Monorepo layout.** Documentation is **global to the monorepo**, not per project:
>
> ```
> Serv-Connect/                     # monorepo root
> ├── CLAUDE.md                     # repo-wide rules
> ├── docs/                         # shared docs — BRD, API contract, security, localization, architecture, walkthroughs
> ├── plans/                        # living plan files
> ├── designs/                      # SVG / HTML design references (mobile/ and dashboard/)
> ├── sev_connect_backend/          # Spring Boot (Kotlin) backend (governed by sev_connect_backend/CLAUDE.md)
> ├── serv_connect_mobile/          # Flutter mobile client (governed by serv_connect_mobile/CLAUDE.md)
> └── serv_connect_dashboard/       # this project — React + TypeScript web dashboard
> ```
>
> Every `docs/...` or `plans/...` path in this file means the **monorepo-root** `docs/` and `plans/` (i.e. `../docs/` and `../plans/` from `serv_connect_dashboard/`). Never create a `docs/` folder inside `serv_connect_dashboard/`. Dashboard tasks never edit files under `sev_connect_backend/` or `serv_connect_mobile/`; if a dashboard change requires a backend API change, it becomes a `cross` plan (backend first, root `CLAUDE.md §5`).
>
> **Current state.** This is a **bare `create-vite` React + TypeScript template**: `src/App.tsx`, `src/main.tsx`, default CSS and assets. No router, no data layer, no i18n, no design tokens, no tests yet. The first approved plan builds the foundation (§23.2 — Recommended Build Order). Do not assume any folder, hook, or component mentioned in this file exists — grep first (§0). Where this file describes something not yet built, it is the **target design** the foundation must implement.

---

## 0. Pre-Task Checklist

Before writing a single line of code, Claude must:

1. Read this file and the root `../CLAUDE.md` in full.
2. Identify the **BRD module and `FR-x.y` IDs** the task touches (`docs/00-brd.md`), and their **phase tag** (`[MVP]`, `[P2]`, `[P3]`). Do not build a `[P2]`/`[P3]` requirement unless the user explicitly asked for it (§2.1).
3. Check `plans/README.md`. If a plan exists for this work, **resume it** from its first unticked step; otherwise **create a written plan in `plans/YYYY-MM-DD_dashboard_<slug>.md`** (from `plans/_TEMPLATE.md`) — listing every file/component/hook/mapper/use-case to be created or modified, the feature package it lives in, the routes, the permission keys and scopes involved (§17), the i18n keys, and any decisions made — and **wait for explicit approval** before proceeding. No code is written until the plan is approved.
4. **Find the design screen(s)** the task implements in `designs/dashboard/en/` and `designs/dashboard/ar/` (root `CLAUDE.md §13`, this file §11), and check the **Shared UI Component Catalogue** (`docs/08-dashboard-architecture.md` and `src/components/` + `src/styles/tokens.css`) before inventing any colour, text style, radius, spacing, button, input, table, card, toast, modal, or drawer. Never add a new `Serve*` primitive without confirming none covers the need. No design for a screen → record it in the plan's Open decisions and ask; don't invent one.
5. **Check the API contract** (`docs/03-api-reference.md`). If a required endpoint or field is missing from the backend contract, **stop and report exactly which** (or make it a `cross` plan with backend first) — never mock it in production code or call an undocumented route.
6. If modifying an existing feature, re-read its feature architecture section in `docs/08-dashboard-architecture.md` (and `docs/features/dashboard-<name>.md` when present).
7. Grep `src/` for existing hooks, repositories/API clients, mappers, validators, formatters, and `Serve*` components before reinventing; extend or parameterise existing code and justify any new implementation in the walkthrough.
8. State the plan and wait for approval on any destructive or irreversible action (removing a route others link to, changing the auth/token flow, `rm -rf`, deleting generated files, force-push).

---

## 1. Project Structure, Feature Map & Component Catalogue

### 1.1 Feature-first Clean Architecture layout

Organise by **feature (vertical slice)** under `src/features/<feature>/`, matching the backend (`sev_connect_backend/CLAUDE.md` §1.1) and mobile (`serv_connect_mobile/CLAUDE.md` §1.2) feature names 1-for-1:

```
serv_connect_dashboard/
├── index.html
├── vite.config.ts
├── tsconfig.json
├── .env.example                                 # every VITE_* key with placeholder values (§4)
├── public/                                      # static files served as-is (favicon, self-hosted fonts)
└── src/
    ├── main.tsx                                 # entry: calls bootstrap() (config assertion + root render)
    ├── app/                                     # app shell: AppProviders, AppRouter, AppShell (sidebar + topbar), RouteErrorBoundary
    ├── components/                              # Serve* shared design-system primitives (§1.4) — zero API/feature imports
    │   ├── primitives/                          # ServeButton, ServeTextField, ServeSelect, ServeBadge, ServeCard, ServeModal, ServeDrawer, ServeTabs, ServeTable, ServeAvatar, ServeMemberAvatar
    │   ├── shimmer/                             # ServeListShimmer, ServeTableShimmer, ServeCardShimmer, ServeRowShimmer
    │   └── feedback/                            # DefaultErrorView, ServeEmptyState, ServeOfflineBanner, Toaster
    ├── core/                                    # cross-cutting infrastructure (never imports features/)
    │   ├── config/                              # AppEnvironment (typed VITE_* reader + startup assertion), FeatureFlagService
    │   ├── event_bus/                           # AppEventBus, AuthEventBus
    │   ├── format/                              # AppFormatters (UTC ISO-8601, LocalDateValue, orgTimeZone, Intl)
    │   ├── i18n/                                # i18next setup, LocaleController, OrgLabelResolver, typed LocaleKeys
    │   ├── logger/                              # AppLogger (PII-safe, no-op in prod, auto-redacting)
    │   ├── permissions/                         # PermissionChecker, ScopeGuard, RequirePermission, PermissionKeys
    │   ├── session/                             # AuthSession (in-memory access token, idle lock timer, scopes)
    │   └── validation/                          # Centralised Validation helpers + shared Zod primitives
    ├── network/                                 # HttpClient, interceptors (Auth, RefreshMutex, AcceptLanguage), ApiResult<T>, Resources<T>, Errors, BaseApiResponse<T>, safeCall
    ├── styles/
    │   ├── tokens.css                           # design tokens from the Dashboard design (§11) as CSS variables
    │   └── global.css                           # reset, typography, logical RTL base, focus-visible rings
    ├── locales/
    │   ├── en/<namespace>.json
    │   └── ar/<namespace>.json
    ├── generated/                               # locale_keys.g.ts (typed i18n keys generated by script)
    ├── features/
    │   └── <feature>/                           # one folder per BRD module (§1.2)
    │       ├── presentation/
    │       │   ├── <screen>/
    │       │   │   ├── view/
    │       │   │   │   ├── <Screen>Page.tsx             # thin route shell (≤ 150 lines; function body ≤ 25 lines)
    │       │   │   │   ├── use<Screen>Controller.ts     # screen controller hook (state, actions, navigation/toast effects)
    │       │   │   │   └── <screen>.types.ts            # <Screen>State, <Screen>Action, <Screen>Effect types
    │       │   │   └── widgets/                         # extracted screen-local sub-components (<SubWidget>.tsx + .module.css)
    │       │   └── widgets/                             # feature-shared components & feature-specific shimmers
    │       ├── domain/
    │       │   ├── entities/                            # immutable domain entities & value objects
    │       │   ├── repository/                          # <Feature>Repository interface (when domain orchestration is non-trivial)
    │       │   └── use_case/                            # pure business rules & multi-step use cases (<verb><Noun>UseCase)
    │       ├── data/
    │       │   ├── api/                                 # typed endpoint functions + TanStack Query key factories & hooks
    │       │   ├── model/                               # Request / Response DTO interfaces matching docs/03 exactly
    │       │   ├── mapper/                              # <Feature>Mapper (DTO ↔ Domain Entity, pure & tested)
    │       │   └── repository/                          # <Feature>RepositoryImpl wrapping safeCall
    │       └── index.ts                                 # feature's public surface (routes, exported domain hooks/types)
    └── test/                                    # Vitest setup, MSW server & handlers, test builders, custom render
```

### 1.2 Planned feature packages (1:1 with BRD §7, Backend §1.1 & Mobile §1.2)

Use these exact feature directory names under `src/features/` — do not invent synonyms. Each maps to its dashboard design screen(s) in `designs/dashboard/{en,ar}/`:

| BRD Module | Feature Dir | Design Screen(s) & Purpose | Earliest Phase |
| --- | --- | --- | --- |
| 8.1 Authentication, Onboarding & Identity | `identity` | Login, invitation management, session, idle lock, role/scope context | MVP |
| 8.2 Member Directory & Records | `members` | Members Directory, Member Profile, family links, portable history, pastoral notes (P2) | MVP |
| 8.3 Groups & Assignments | `groups` | Groups & Assignments, stages, servant assignments, memberships, annual promotion flow | MVP |
| 8.4 Scheduling & Events | `schedule` | Schedule calendar/list, Event Editor (recurring series vs. single occurrence), conflict warnings | MVP |
| 8.5 Attendance & Follow-up | `attendance` | Attendance & Follow-up oversight, absentee queue, outcome tracking, absence threshold alerts | MVP |
| 8.6 Task Management | `tasks` | Tasks Kanban & list, assignee/due/priority, follow-up task oversight | MVP |
| 8.7 Communication & Collaboration | `communication` | Group/stage/org announcements (MVP), contextual threads (P2) | MVP→P2 |
| 8.8 Curriculum & Lesson Management | `curriculum` | Curriculum & Lessons, Curriculum Builder, review & approval workflow | P2 |
| 8.9 Content Library | `content` | Content Library, configurable `ContentPack` management (Bible plans, hymns, readings) | MVP→P2 |
| 8.10 Memorization & Points | `engagement` | Memorization & Points rules, badges, opt-in leaderboards | P2 |
| 8.11 Trips, Conferences & Logistics | `trips` | Trips & Conferences, registration, parent consent verification, payment tracking, rooming/bus | P2 |
| 8.12 Notifications & Reminders | `notifications` | In-app notification centre, announcement dispatch & quiet-hours defaults | MVP |
| 8.13 Safeguarding, Privacy & Audit | `safeguarding` + `audit` | Safeguarding & Audit log viewer, scope-gated views, photo-consent enforcement, DSR exports | MVP→P2 |
| 8.14 Analytics & Reporting | `analytics` | Overview dashboard, Reports & Analytics, attendance trends, at-risk & workload summaries | P2→P3 |
| 8.15 Prayer & Praise Board | `prayer` | Prayer Board moderation, praise reports | P2 |
| 8.16 Administration & Configuration | `admin` | Users, Roles & Access, Settings (org profile, stages, content packs, feature flags, custom labels) | MVP |

### 1.3 Domain vocabulary & non-negotiable business rules

Use the exact BRD glossary (`docs/00-brd.md` §16), backend entity names (`sev_connect_backend/CLAUDE.md` §1.2), and mobile entity names (`serv_connect_mobile/CLAUDE.md` §1.3) across TypeScript entities, DTOs, and hooks:
- `Person`, `Servant`, `ServedMember`, `FamilyLink`, `Stage`, `Group`, `GroupType`, `GroupAssignment`, `GroupMembership`, `Event`, `EventOccurrence`, `AttendanceRecord` (`PRESENT` / `ABSENT` / `EXCUSED`), `FollowUp`, `PastoralNote`, `Task` (`FOLLOW_UP` / `LESSON_PREP` / `LOGISTICS` / `GENERAL`), `ContentPack`, `ContentItem`, `AuditEntry`, `RoleAssignment`.
- **Denomination-neutral (BRD §8.9):** Never hard-code tradition-specific prayers, readings, feasts, saints, calendars, or hymn sets in TypeScript code or locale JSON files. All liturgical/spiritual content comes from a backend `ContentPack`. Role/group UI terminology ("Servant", "Stage", "Sunday School") supports org-level label overrides where configured.
- **Record portability (FR-2.4):** When a `ServedMember` moves group/stage, their full history stays intact; a leader/servant whose group scope changes immediately loses cached access in the session (`ScopeRevokedEvent` evicts affected TanStack Query cache entries).
- **Payments are tracking-only (FR-11.4):** Never add card inputs, payment gateway SDKs, or bank fields. Trip payment screens only record/view who paid, amount, and date.
- **Consent gates (FR-11.3, FR-13.5):** Never render a member photo if `photoConsent === false` (render the initials placeholder avatar in `ServeMemberAvatar` instead). Never allow marking a minor "cleared to travel" in UI without a valid `ConsentForm`.

### 1.4 Shared `Serve*` UI Component Catalogue

- Shared UI primitives live in `src/components/` and are prefixed `Serve*` (`ServeButton`, `ServeIconButton`, `ServeTextField`, `ServeSelect`, `ServeAvatar`, `ServeMemberAvatar`, `ServeBadge`, `ServeCard`, `ServeTable`, `ServeModal`, `ServeDrawer`, `ServeTabs`, `ServeEmptyState`, `ServeOfflineBanner`, `ServeListShimmer`, `ServeTableShimmer`, `ServeCardShimmer`, `ServeRowShimmer`, `DefaultErrorView`, `Toaster`) and are documented in `docs/08-dashboard-architecture.md`.
- Every new shared `Serve*` component gets a row in `docs/08-dashboard-architecture.md` before commit: component name, file path, full `Props` interface signature (with defaults), and one-line purpose.
- Check `docs/08-dashboard-architecture.md` and `src/components/` before building any UI primitive; extend/parameterise rather than duplicate. Update the catalogue entry whenever props change.
- Feature-specific components stay in `src/features/<feature>/presentation/<screen>/widgets/` (or `src/features/<feature>/presentation/widgets/`) and are **not** catalogued — the catalogue is for cross-feature primitives.

---

## 2. Git Commits & Phase Discipline

- Root `CLAUDE.md §2` applies. Commit after every completed, working unit (normally one plan step). Format:

  ```
  <type>(<scope>): <short description>

  <body — what & why, if non-obvious; cite FR-x.y IDs and the plan file>
  ```

- Never add a `Co-Authored-By` trailer to commit messages.

- Valid types: `feat`, `fix`, `refactor`, `test`, `docs`, `chore`, `build`, `perf`, `security`.
- Valid scopes: `dashboard/<feature>` (`dashboard/identity`, `dashboard/members`, `dashboard/groups`, `dashboard/schedule`, `dashboard/attendance`, `dashboard/tasks`, `dashboard/communication`, `dashboard/curriculum`, `dashboard/content`, `dashboard/engagement`, `dashboard/trips`, `dashboard/notifications`, `dashboard/safeguarding`, `dashboard/audit`, `dashboard/analytics`, `dashboard/prayer`, `dashboard/admin`) or dashboard infra (`dashboard/network`, `dashboard/auth`, `dashboard/routing`, `dashboard/ui`, `dashboard/i18n`, `dashboard/build`, `dashboard/test`).
- **Never commit:**
  - Secrets or local environment files (`.env`, `.env.local`, `.env.dev`, `.env.staging`, `.env.prod` — only `.env.example` is tracked).
  - Build, test, or IDE artefacts (`node_modules/`, `dist/`, `coverage/`, `playwright-report/`, `test-results/`, `.vite/`, `.idea/`, `*.iml`).
  - Failing builds, type errors, linter warnings, or failing tests (`npm run format:check`, `npm run lint`, `npm run build`, `npm run i18n:check`, and `npm test` must all exit `0`).
  - Stray `console.log`, `console.debug`, `console.info`, `console.warn`, or `console.error` in production code (use `AppLogger`, §16.2).
  - Commented-out code blocks — delete instead.
  - Real member/minor PII (real names, photos, phone numbers, emails) in tests, MSW fixtures, or seed/preview data.
  - Hand-written `.ts` / `.tsx` files exceeding **250–300 lines** or any function, hook, method, or React component body exceeding **20–25 lines** (§9.1) — split into smaller functions, sub-hooks, sub-components, or files before committing.
- Never run `--no-verify`, `git push --force` on `main`/`develop`/`release/*`, or `git reset --hard` without explicit user instruction.

### 2.1 Phase discipline

- The BRD ships in phases: **MVP → P2 → P3** (`docs/00-brd.md` §13).
- Build only what the current task's `FR-x.y` IDs require. Do not build `[P2]`/`[P3]` screens, columns, or API hooks "for later" — design cleanly so they can be added without breaking existing modules, and note follow-ups in the walkthrough.

---

## 3. Walkthrough History

- After every completed feature, fix, or significant refactor: create or update `docs/walkthroughs/YYYY-MM-DD_dashboard_<short-slug>.md` (the `dashboard_` prefix distinguishes dashboard walkthroughs from `backend_` and `mobile_` ones in the shared monorepo folder) and add a one-line entry to `docs/walkthroughs/README.md`.
- Required sections:
  - **Date**
  - **Plan** (link to the `plans/YYYY-MM-DD_dashboard_<slug>.md` file)
  - **Summary** (one paragraph)
  - **BRD coverage** (`FR-x.y` IDs + phase tag, fully/partially implemented)
  - **Design screens implemented** (file names from `designs/dashboard/{en,ar}/`)
  - **Files changed** (all created/modified; generated files noted)
  - **Routes & Navigation** (routes added/changed, guards, sidebar visibility rules)
  - **API usage** (endpoints consumed, query keys invalidated/updated, whether `docs/03-api-reference.md` was updated)
  - **Security & Safeguarding impact** (permission keys & scopes checked, PII/Sensitive handling, photo-consent or `AuditEntry` triggers, URL PII verification)
  - **Widgets** (new/updated `Serve*` primitives + `docs/08-dashboard-architecture.md` catalogue update)
  - **Localization** (new keys in both `src/locales/en/` and `src/locales/ar/` + regenerated `locale_keys.g.ts`, RTL verification)
  - **Testing** (unit, hook/controller, component, MSW, and E2E test coverage)
  - **Config** (new `VITE_*` keys in `.env.example` / `AppEnvironment`)
  - **Known limitations / follow-ups**

---

## 4. Secrets, Environment Configuration & Build Modes (`dev` / `staging` / `prod`)

- All base URLs, environment flags, and non-secret client config live in `.env.<mode>` files inside `serv_connect_dashboard/` (`.env.development`, `.env.staging`, `.env.production`) — nowhere else. All `.env*` files are gitignored except `.env.example` (which lists every required `VITE_*` key with empty/placeholder values).
- **Everything in `VITE_*` is public** — it is baked into the client JS bundle. Never put a secret, private API key, service-account credential, database URL, or token in any `VITE_*` variable or source file.
- Required keys in `.env.example`: `VITE_API_BASE_URL`, `VITE_ENV_NAME` (`dev` | `staging` | `prod`), `VITE_DEFAULT_LOCALE` (`en` | `ar`), `VITE_IDLE_TIMEOUT_MINUTES` (default `15`).
- Read environment variables exclusively through the singleton `AppEnvironment` (`src/core/config/app_environment.ts`) — **never read `import.meta.env` outside `app_environment.ts`**.
- `AppEnvironment.assertConfigured()` must run during `bootstrap()` before `createRoot(...).render(...)` and **throw/render a clear configuration error screen immediately** if any required key is missing, empty, starts with `__`, or uses a non-HTTPS `VITE_API_BASE_URL` in `staging`/`prod`. Never silently fall back to empty strings or `localhost` in staging/prod.

---

## 5. Localization (EN / AR) & RTL-First

- **Every** user-facing string is localized (NFR-6) via `react-i18next`. Supported locales: `ar` (Arabic, RTL) and `en` (English, LTR), matching the backend (`sev_connect_backend/CLAUDE.md` §18) and mobile app (`serv_connect_mobile/CLAUDE.md` §5).
- Every HTTP request sends the active locale in the `Accept-Language` header (`ar` or `en`) via `AcceptLanguageInterceptor` on the shared `HttpClient` so backend validation/error envelopes return already localized.
- Every user-facing string comes from `src/locales/{en,ar}/<namespace>.json` referenced via typed `LocaleKeys` (`src/generated/locale_keys.g.ts`) — never hard-coded in JSX or TS, including `aria-label`s, `title`s, table headers, placeholders, toast messages, empty states, and `document.title`.
  - Only literal-string exception: the language-switcher native labels (`"العربية"`, `"English"`).
- Adding a string: add to **both** `src/locales/en/<namespace>.json` and `src/locales/ar/<namespace>.json` in the same change, then run:
  ```bash
  npm run i18n:generate
  npm run i18n:check
  ```
  Commit the regenerated `src/generated/locale_keys.g.ts`. `npm run i18n:check` fails the build if any key or interpolation placeholder (`{{count}}`, etc.) differs between `en` and `ar`.
- **Configurable church labels (BRD §16):** Terms like "Servant", "Served Member", and "Stage" have default translation keys (`common.role_servant`, `common.role_served_member`, `common.stage`) that can be overridden by the organisation's cached `OrgConfig` labels. Resolve them via `useOrgLabels()` (`OrgLabelResolver`) rather than hard-coding.
- **Content packs are data, not translation keys (BRD §8.9):** Bible text, hymns, readings, prayers, and calendar entries come from `ContentPack` records returned by the API — never put liturgical content in `src/locales/`.
- **RTL-first layout:**
  - Switching locale sets `<html lang={locale} dir={locale === 'ar' ? 'rtl' : 'ltr'}>` and swaps the active font stack (Inter + Fraunces for `en`; Cairo + Amiri for `ar`, §11).
  - Always use **CSS logical properties** in CSS Modules (`margin-inline-start`, `margin-inline-end`, `padding-inline`, `padding-block`, `inset-inline-start`, `inset-inline-end`, `border-inline-start`, `text-align: start`) — **never** physical `left` / `right` for layout (`margin-left`, `padding-right`, `left:`, `right:`, `text-align: left`).
  - Directional icons (chevrons, back/forward arrows, drawer toggles) must flip automatically in `[dir="rtl"]` (`transform: scaleX(-1)`). RTL layout bugs are release blockers.

---

## 6. Timestamps, Timezones & Recurrence

- **Wire format (Backend §14, Mobile §6):** Absolute instants arrive from and are sent to the backend as UTC ISO-8601 strings (`Instant`, e.g. `2026-10-18T15:00:00Z`). Always parse and serialise in UTC via `AppFormatters`.
- **Local dates & recurring events (FR-4.1/4.2):**
  - Genuine date-only / time-of-day values (birthdates, "every Friday at 18:00") are transmitted as ISO `YYYY-MM-DD` / `HH:mm` strings and represented in domain entities as branded/value types (`LocalDateString`, `LocalTimeString`) evaluated in the organisation's IANA timezone (`orgTimeZone`, e.g. `Africa/Cairo`) via `Intl.DateTimeFormat(..., { timeZone: orgTimeZone })` — never shifted through browser-local or UTC midnight.
  - Concrete `EventOccurrence` instances carry UTC start/end ISO instants converted to `orgTimeZone` (or user zone when explicitly shown) only for display via `AppFormatters`.
- **Display formatting:** Render all dates, times, relative times (`minutesAgo`, `daysAgo`), and localized numerals exclusively through `AppFormatters` (`src/core/format/app_formatters.ts`) using `Intl.DateTimeFormat`, `Intl.RelativeTimeFormat`, and `Intl.NumberFormat` with the active locale. Never call `new Date(val).toLocaleDateString()` or `.toString()` directly inside components.
- **Timers & countdowns (e.g. idle session lock countdown):** Recompute remaining time from wall-clock (`targetTimestampMs - Date.now()`) on each interval tick inside a dedicated hook — never by decrementing a counter in `setInterval`.

---

## 7. Security, Safeguarding & PII Checklist (Run Before Every Commit)

Because ServeConnect handles records of **minors** and pastoral care (BRD §8.13, NFR-4, NFR-5), verify every item below before every commit:

- [ ] **No secrets or credentials** in source code, git history, `VITE_*` variables, or logs (`.env*` gitignored; `AppEnvironment` used everywhere).
- [ ] **Access token in memory only (`AuthSession`):** `accessToken` is held exclusively in memory inside `AuthSession` — **never** in `localStorage`, `sessionStorage`, `IndexedDB`, or JS-readable cookies. Refresh rotation uses an `HttpOnly; Secure; SameSite=Strict` cookie (or the backend-agreed refresh mechanism) via `RefreshMutexInterceptor`. Logout, 401 refresh failure, or idle lock clears `AuthSession` and calls `queryClient.clear()`.
- [ ] **Idle session lock:** Because the dashboard runs on shared church office desktops, `IdleLockWatcher` locks/ends the session after `VITE_IDLE_TIMEOUT_MINUTES` of inactivity and wipes in-memory query caches.
- [ ] **Zero browser-storage persistence of member/PII caches:** Never configure TanStack Query `persistQueryClient` or write `ServedMember`, `AttendanceRecord`, `FollowUp`, `PastoralNote`, or `ConsentForm` data into `localStorage`, `sessionStorage`, or `IndexedDB`.
- [ ] **Data classification enforced (§17.2):**
  - **PII** (member name, photo, birthdate, phone, email, address, family links) is never logged (`AppLogger`), never placed in route URLs or query strings (`/members/:memberId` uses opaque UUIDs only; search/filter text stays in React/controller state, never `?q=<name>`), never placed in `document.title`, and never sent in analytics/crash payloads.
  - **Sensitive** data (medical/emergency info, private pastoral notes FR-2.5, consent forms FR-11.3, safeguarding incidents) is fetched only through its dedicated endpoint, only when an authorized user explicitly opens the view, with `staleTime: 0` and `gcTime: 0` (wiped immediately on unmount or scope loss), and **every view/edit triggers an `AuditEntry`** (FR-13.2).
- [ ] **Photo consent respected (FR-13.5):** Every member photo renders through `ServeMemberAvatar`, which checks `member.photoConsent === true` before rendering the pre-signed URL and falls back to initials when `false`.
- [ ] **No `dangerouslySetInnerHTML` with API data:** Rich content from `ContentPack`s is rendered through structured blocks or an approved HTML sanitizer (`DOMPurify` with strict allowlist) named in the plan.
- [ ] **Audited exports:** Any CSV/PDF export of member or attendance data requires the specific export permission, is generated/audited server-side, and shows a clear confirmation dialog stating what data is exported.
- [ ] **No `console.*` in production code:** Use `AppLogger.d/i/w/e` only (no-op in production builds, with automatic redaction of `authorization`, `password`, `otp`, `token`, `phone`, `email`, `medical`, `note`). HTTP logging logs method, path (UUIDs only), and status code — **never request/response headers or bodies**.
- [ ] **HTTPS in transit (NFR-4):** `VITE_API_BASE_URL` must use `https://` in staging and production (`AppEnvironment.assertConfigured()` enforces this).
- [ ] **Client-side RBAC is UX only (NFR-4):** Hiding a button or nav item via `PermissionChecker` / `<RequirePermission>` never substitutes for server-side authorization, and every `403` from the server is handled gracefully (`ForbiddenScopeError` or `FeatureDisabledError`).
- [ ] **Dependency hygiene:** `npm audit --omit=dev` is clean of High/Critical vulnerabilities before release.

---

## 8. Testing (≥ 70 % Coverage + Safeguarding, Scope & RTL Suites)

- Every new `UseCase`, `Mapper`, `RepositoryImpl`, controller hook (`use<Screen>Controller`), `PermissionChecker` rule, `Validation` schema, and `AppFormatters` helper must have unit tests.
- Every `Page` and shared `Serve*` component must have component tests covering its **loading (shimmer), empty, error (with retry), `403` (`ForbiddenScopeError`), and success** states.
- Minimum **70 % line coverage** across `src/core/`, `src/network/`, and `src/features/*/{domain,data,presentation}`:
  ```bash
  npm run test:coverage
  ```
  Do not commit if coverage drops below 70 %.

| Layer | Location | Tools |
| --- | --- | --- |
| Unit (UseCases, Mappers, Formatters, Validators, Permissions) | `src/features/<feature>/**/*.test.ts` & `src/core/**/*.test.ts` | Vitest |
| Controller Hook & Data / Repository | `src/features/<feature>/**/*.test.ts(x)` | Vitest + `renderHook` + MSW |
| Component & Page | `src/features/<feature>/**/*.test.tsx` & `src/components/**/*.test.tsx` | Vitest + React Testing Library + `@testing-library/user-event` + MSW |
| End-to-End (Critical flows in LTR `en` + RTL `ar`) | `e2e/<feature>.spec.ts` | Playwright (runs in **both** `en` and `ar` projects) |

- **Mandatory domain test cases:**
  1. **Safeguarding & permission tests (§24):** Every screen/controller touching minor records or Sensitive fields must test: (a) authorized in-scope view, (b) out-of-scope / missing-permission block (`<RequirePermission>` hides control and `403` renders permission-denied state), (c) `photoConsent === false` never renders an `<img src>` with the photo URL, and (d) `AuditEntry` is dispatched on Sensitive view/write and sensitive query cache is cleared on unmount (`gcTime: 0`).
  2. **Zero PII in URLs & browser storage tests:** Verify that searching/filtering members or navigating to member details never writes a name, phone, email, or search query into `window.location.search`, `window.location.pathname`, `localStorage`, or `sessionStorage`.
  3. **Session & token refresh tests:** Verify that concurrent `401` responses trigger a single serialised refresh call (`RefreshMutexInterceptor`), a `401` on refresh clears `AuthSession` + `queryClient` and redirects to Login, and `IdleLockWatcher` locks the session after the configured inactivity window.
  4. **Bilingual & RTL verification:** Verify that `npm run i18n:check` passes and pages render with `<html dir="rtl" lang="ar">` without layout or missing-key regressions.
- Mock the network exclusively with **MSW** (`msw/node` in Vitest, `msw` in browser harness when needed) using response envelopes copied from `docs/03-api-reference.md` — never from guesses or ad-hoc `vi.spyOn(window, 'fetch')`.
- Naming: `it('<action>_<condition>_<expectation>', ...)`.
- Never use arbitrary `setTimeout` sleeps in tests — use `waitFor`, `findBy*`, or `vi.useFakeTimers()`. Never use real member PII in test builders (`src/test/builders/`).

---

## 9. Clean Architecture (`use<Screen>Controller` + Discriminated Union Actions)

### 9.1 Size, Complexity & Decomposition Limits (Non-Negotiable)

- **File size limit:** **≤ 250–300 lines of code** (target ≤ 250 lines; **300 lines is a hard ceiling** for every hand-written `.ts` and `.tsx` file in `src/` and `e2e/`).
- **Function / hook / component size limit:** **≤ 20–25 lines of code** (target ≤ 20 lines; **25 lines is a hard ceiling** for every function, arrow function, custom hook, method, and React component function body).
- **Mandatory decomposition when any limit is reached:**
  - **Oversized Component (> 20–25 lines) or Page file (> 250–300 lines):** Never use `renderX()` helper functions inside a component that return `JSX.Element`. Instead, extract dedicated React function components into separate files under `src/features/<feature>/presentation/<screen>/widgets/<SubWidget>.tsx` (or `src/components/` if reusable across features). Keep `<Screen>Page.tsx` as a thin shell (wires `use<Screen>Controller()`, handles one-shot navigation/toast effects, and renders top-level layout delegating to child widget files).
  - **Oversized Function / Hook (> 20–25 lines):** Split into smaller, single-responsibility helper functions or sub-hooks (`validateFilterInput`, `buildMemberQueryParams`, `useMemberTableSelection`, etc.). Pure business/mapping helpers extracted from a controller hook, `UseCase`, or `Repository` go into `domain/use_case/` or `data/mapper/` and get their own unit tests.
  - **Oversized Types / State / Controller File (> 250–300 lines):**
    - **Types:** Split `<screen>.types.ts` into `<screen>.state.ts`, `<screen>.actions.ts`, and `<screen>.effects.ts`.
    - **Controller Hook:** Move multi-step orchestration or domain calculations into dedicated `UseCase`s (`src/features/<feature>/domain/use_case/`) and split sub-concerns into focused hooks (`use<Screen>Filters`, `use<Screen>Mutations`) so each hook/function stays ≤ 20–25 lines.
    - **Repository / Mapper / API:** Split large mappers or API modules by sub-aggregate (e.g. `MemberProfileMapper` + `FamilyLinkMapper`).

### 9.2 Screen Controller Hook (`use<Screen>Controller`) & Discriminated Union `Action`s

Mirroring the mobile project's `BaseCubit<State, Action, NavigationAction>` discipline in idiomatic React + TypeScript:
- Every screen has a dedicated controller hook `use<Screen>Controller` in `src/features/<feature>/presentation/<screen>/view/use<Screen>Controller.ts`.
- User intents enter via a single `doAction(action: <Screen>Action)` dispatcher switching exhaustively (`switch (action.type)` with an `assertNever(action)` exhaustiveness check) on a TypeScript discriminated union `<Screen>Action`.
- One-shot side effects (navigation, opening modals/drawers, showing `Toaster` alerts) are emitted via `Toaster` / router callbacks or a typed `<Screen>Effect` — never by stuffing `errorMessage` or `shouldNavigate: true` flags into React state with a manual "clear" action.
- Pages and presentational components **never** call `useQuery`, `useMutation`, `HttpClient`, or `fetch` directly — all server/client state orchestration lives inside `use<Screen>Controller` (and the domain/data hooks it composes).

```ts
// membersDirectory.types.ts
export interface MembersDirectoryState {
  readonly membersResource: Resources<PagedResult<MemberSummaryEntity>>;
  readonly searchQuery: string;
  readonly selectedStageId: string | null;
  readonly page: number;
  readonly canCreateMember: boolean;
}

export type MembersDirectoryAction =
  | { readonly type: 'CHANGE_SEARCH'; readonly query: string }
  | { readonly type: 'SELECT_STAGE'; readonly stageId: string | null }
  | { readonly type: 'CHANGE_PAGE'; readonly page: number }
  | { readonly type: 'OPEN_MEMBER_DETAIL'; readonly memberId: string }
  | { readonly type: 'RETRY_LOAD' };
```

### 9.3 Page (View) Wiring

Every screen `<Screen>Page.tsx` is a thin presentational shell (≤ 20–25 lines in its component body) that calls `use<Screen>Controller()`, switches on `Resources<T>` states (`ServeTableShimmer` / `DefaultErrorView` / `ServeEmptyState`), and passes `state` slices and `doAction` down to extracted sub-widgets:

```tsx
export function MembersDirectoryPage(): React.JSX.Element {
  const { state, doAction } = useMembersDirectoryController();

  return (
    <MembersDirectoryShell
      state={state}
      onAction={doAction}
    />
  );
}
```

- Pages hold zero business logic, zero direct `fetch`/`useQuery` calls, and zero inline style objects.

### 9.4 `UseCase` & Business Rule Functions

- Domain calculations and multi-step workflows (e.g. determining which actions an `EventOccurrence` allows for the caller's scope, computing absence alert thresholds, validating stage promotion eligibility) live in `src/features/<feature>/domain/use_case/<verb><Noun>UseCase.ts` as pure functions or injectable classes returning `ApiResult<T>` (or domain values).
- Never embed business rules inside JSX conditionals or inline event handlers.

### 9.5 Naming Conventions

| Artefact | Convention | Example |
| --- | --- | --- |
| Shared UI Component | `Serve<Name>` (`Serve<Name>.tsx`) | `ServeButton`, `ServeTable`, `ServeMemberAvatar` |
| Screen Page | `<Screen>Page` (`<Screen>Page.tsx`) | `MembersDirectoryPage`, `AttendanceOversightPage` |
| Screen Controller Hook | `use<Screen>Controller` (`use<Screen>Controller.ts`) | `useMembersDirectoryController` |
| State / Action / Effect types | `<Screen>State` / `<Screen>Action` / `<Screen>Effect` | `MembersDirectoryState`, `MembersDirectoryAction` |
| Domain Entity | `<Name>Entity` (or exact BRD glossary name) | `ServedMemberEntity`, `AttendanceRecordEntity` |
| UseCase | `<verb><Noun>UseCase` | `evaluateOccurrenceActionsUseCase`, `recordSensitiveAccessUseCase` |
| Repository interface / impl | `<Feature>Repository` / `<Feature>RepositoryImpl` | `MembersRepository`, `MembersRepositoryImpl` |
| Mapper | `<Feature>Mapper` (`<feature>Mapper.ts`) | `MembersMapper` |
| TanStack Query Key Factory | `<feature>Keys` | `memberKeys.list(filters)`, `memberKeys.detail(id)` |
| Request / Response DTO | `<Name>Request` / `<Name>Response` | `CreateMemberRequest`, `MemberRecordResponse` |
| CSS Module | `<Component>.module.css` | `ServeButton.module.css`, `MembersTable.module.css` |

### 9.6 Linting, Formatting & Pre-Commit Quality Gates

- `tsconfig.json` enforces `"strict": true`, `"noImplicitAny": true`, `"strictNullChecks": true`, `"noUncheckedIndexedAccess": true`, `"noUnusedLocals": true`, `"noUnusedParameters": true`, `"noImplicitReturns": true`, `"noFallthroughCasesInSwitch": true`.
- `oxlint` enforces strict React, TypeScript, JSX-a11y, and import boundary rules: no `any`, no non-null assertion `!` on API data, no `console.*`, no unused vars/imports, exhaustive switch checks (`assertNever`), and hooks rules.
- Before every commit run all quality gates:
  ```bash
  npm run lint
  npm run build
  npm run i18n:check
  npm test
  find src e2e \( -name '*.ts' -o -name '*.tsx' \) ! -name '*.g.ts' -exec awk 'END { if (NR > 300) print FILENAME ": " NR " lines (exceeds 250-300 limit)" }' {} +
  ```
  Every command must exit `0` with zero warnings, and the line-count check must produce **no output** (target ≤ 250 lines per file, hard max 300; target ≤ 20 lines per function/hook/component body, hard max 25). No `// oxlint-disable` or `// @ts-expect-error` without a brief rationale comment.

---

## 10. Separation of Concerns & Module Boundaries

- **Call chain:** `<Screen>Page` → `use<Screen>Controller` (`doAction`) → `UseCase` / feature query hooks → `<Feature>RepositoryImpl` (`safeCall`) → feature API functions (`HttpClient`) + `<Feature>Mapper` (`DTO ↔ Domain Entity`).
- **Views (`*Page.tsx`, `widgets/*.tsx`)** never import `HttpClient`, `fetch`, DTOs (`data/model/`), `Mapper`s, or `RepositoryImpl`. They receive immutable domain entities and `Resources<T>` via props/controller state and emit user intents via `onAction` / callbacks.
- **Mappers** convert `DTO ↔ Domain Entity` with zero side effects and protect the UI from unknown enum values or optional fields (additive API contract, root `CLAUDE.md §5`).
- **Cross-feature boundaries:**
  - `src/components/`, `src/core/`, and `src/network/` **never** import from `src/features/`.
  - `src/features/<X>/` **never** imports from `src/features/<Y>/data/` or `src/features/<Y>/presentation/`. If feature `X` needs domain types, hooks, or use cases owned by feature `Y` (e.g. `attendance` reading stage/group summaries from `groups`), it imports **only** from `src/features/<Y>/index.ts` and documents the dependency in `docs/08-dashboard-architecture.md`.
  - No root-level grab-bag folders (`src/pages/`, `src/hooks/`, `src/services/`, `src/utils/`).

---

## 11. API Integration (`HttpClient` + `ApiResult<T>` + `Resources<T>`)

- **Contract source of truth:** `docs/03-api-reference.md`. All REST calls target `/api/v1/<resource>` via the shared `HttpClient` in `src/network/http_client.ts`. Features never call `window.fetch` directly.
- **JSON conventions (Backend §7, Mobile §11):** The Spring Boot Kotlin backend uses **camelCase** JSON keys (`orgId`, `createdAt`, `updatedAt`, `changeSeq`, `deletedAt`) and `UUID` strings for IDs.
- **Response envelope (Backend §8, §10):**
  - Backend never returns `204 No Content`; every endpoint returns `BaseResponseBody<T>` (`data`, `message`, `code`, `fieldErrors` on failure), and paginated endpoints return Spring `Page<T>` metadata (`content`, `page`, `size`, `totalElements`, `totalPages`).
  - Model this in `src/network/base_api_response.ts` (`BaseApiResponse<T>` and `PagedContent<T>`).
- **Idempotency (Backend §8):** Every create/mutation request carries a client-generated `UUID` v4 (`IdGenerator.newUuid()` via `crypto.randomUUID()`) as the entity `id` or in the `Idempotency-Key` header so retries never duplicate records.
- **Safe invocation (`safeCall`):** Every repository/API call wraps network I/O in `safeCall(...)` (`src/network/safe_call.ts`), converting HTTP failures, network drops, timeouts, and schema parse errors into `Failure<T>(error: AppError, message: string)`. No raw exception ever escapes `data/`.

### 11.1 `ApiResult<T>` (Domain / Data Envelope)

```ts
export type ApiResult<T> =
  | { readonly kind: 'success'; readonly data: T }
  | { readonly kind: 'failure'; readonly error: AppError; readonly message: string };

export const ApiResult = {
  success: <T>(data: T): ApiResult<T> => ({ kind: 'success', data }),
  failure: <T = never>(error: AppError, message: string): ApiResult<T> => ({
    kind: 'failure',
    error,
    message,
  }),
} as const;
```

### 11.2 `Resources<T>` (Presentation State Envelope)

Mirroring `serv_connect_mobile` §11.2 so every screen handles loading, background refresh, empty, error, and `403` states uniformly:

```ts
export type ResourceStatus = 'initial' | 'loading' | 'success' | 'error';

export interface Resources<T> {
  readonly status: ResourceStatus;
  readonly data?: T;
  readonly error?: AppError;
  readonly message?: string;
  readonly isInitial: boolean;
  readonly isLoading: boolean;
  readonly isSuccess: boolean;
  readonly isError: boolean;
}
```

- Notice that `Resources.loading(currentData)` and `Resources.failure(error, message, currentData)` preserve existing `data` during background refetches or pagination transitions so the table/screen keeps showing current records with a subtle non-blocking top progress bar rather than wiping the screen back to a full-page skeleton!

---

## 12. Server State, Online-Only Discipline & Cache Eviction

- **Online-only console (BRD §11, §12.5):** Unlike the mobile servant client, admin configuration, analytics, and the full audit log are **online-only**. The dashboard does not maintain an offline mutation outbox:
  1. `ConnectivityWatcher` monitors network reachability and server heartbeat.
  2. When offline, `ServeOfflineBanner` renders at the top of the app shell, and mutation buttons/forms disable cleanly with a localized tooltip (`LocaleKeys.common_offline_mutations_disabled`) — never silently drop a submit.
- **TanStack Query discipline:**
  - Query keys are strictly typed arrays built by a per-feature key factory (`memberKeys.all`, `memberKeys.list(filters)`, `memberKeys.detail(memberId)`).
  - Never copy server data from TanStack Query into Zustand or React state.
  - **Sensitive query rules (FR-13.3):** Queries for Sensitive records (`PastoralNote`, medical/emergency info, `ConsentForm`, safeguarding incidents) MUST set `staleTime: 0`, `gcTime: 0`, `refetchOnWindowFocus: false`, and `retry: false`, ensuring Sensitive data is never prefetched and is purged from memory the instant the component unmounts.
  - **Scope revocation (`ScopeRevokedEvent`):** If an API call returns `403 ERR_FORBIDDEN_SCOPE` or permissions refresh removes a scope, emit `ScopeRevokedEvent` on `AppEventBus`, purge affected query keys immediately, and navigate away with `Toaster.showWarning(...)`.

---

## 13. Loading States — Shimmer Skeletons & Design System (Dashboard UI)

### 13.1 Shimmer Skeletons (Never Centered Spinners)

- All initial table, list, grid, and detail loading states (`resource.isLoading && !resource.data`) use **shimmer skeletons** — never a centered spinner or blank screen.
- When `resource.data` is already present and a background refetch/filter update is in flight, keep rendering the existing data and show a subtle top progress bar.
- Spinners are allowed **only** inside an action button (`<ServeButton isLoading>`) or a blocking confirmation modal (e.g. executing annual stage promotion).
- Shared shimmer primitives live in `src/components/shimmer/` (`ServeTableShimmer`, `ServeListShimmer`, `ServeCardShimmer`, `ServeRowShimmer`). Feature-specific shimmers live in `src/features/<feature>/presentation/widgets/<Screen>Shimmer.tsx`.
- When an initial load fails with no data (`resource.isError && !resource.data`), render `<DefaultErrorView error={resource.error} onRetry={...} />` from `src/components/feedback/` (which automatically renders the dedicated permission-denied state on `ForbiddenScopeError` and not-found state on `404`).

### 13.2 Dashboard Design System & Tokens

- **Reference:** the SVG/HTML screens in `designs/dashboard/en/` and `designs/dashboard/ar/` (same file name for both languages, one file per screen or state), plus `designs/design-system.html` when provided (root `CLAUDE.md §13`). `designs/mobile/` is **not** a reference for the dashboard. Code never imports from `designs/`; assets are copied into `src/assets/` or `public/`.
  - *Temporary bootstrap note:* While `designs/dashboard/` is being populated from `../Design/` (`ServeConnect-Dashboard.html`, `ServeConnect-Dashboard-AR.html`, and `Dashboard En UI/` / `Dashboard Ar UI/`), a plan may cite those files as a temporary reference and must record that in the plan.
- **Tokens (`src/styles/tokens.css`):** Define all colours (`--paper`, `--canvas`, `--ink`, `--ink-2`, `--muted`, `--line`, `--red`, `--gold`, `--green`, `--amber`, `--blue` and their `-soft`/`-dark` variants), spacing, radii (`--r-sm` … `--r-xl`), shadows (`--shadow`, `--shadow-sm`), breakpoints, and fonts (`--font`, `--serif`) solely in `src/styles/tokens.css`. **Never hard-code raw `#hex` colours, pixel radii, or font families in feature CSS Modules or JSX.**
- **Fonts:** `en` uses Inter (UI) + Fraunces (display); `ar` uses Cairo (UI) + Amiri (display).
- **Layout:** Desktop-first `AppShell` (collapsible sidebar navigation + top header bar + scrollable main workspace) usable down to tablet landscape/portrait (`≥ 768px`).
- **Styling:** CSS Modules (`*.module.css`) consuming `tokens.css` variables + logical properties. No inline `style={{ ... }}` objects (except dynamic runtime coordinates like drag-and-drop or chart widths), and no external CSS/UI framework without an approved plan.

---

## 14. Optimistic UI vs. Server-Confirmed Mutations

- **Low-risk interactive mutations** (e.g. moving a task card across Kanban columns, toggling a personal notification preference) may use TanStack Query optimistic updates only when specified in the plan, saving a snapshot in `onMutate` and rolling back in `onError` with a `Toaster.showError(message)` notification.
- **Critical admin & safeguarding mutations** (user/role assignments, permission/scope changes, annual stage promotion, consent verification/revocation, member creation/deletion, pastoral notes) **never** use optimistic UI: set `<ServeButton isLoading={isSubmitting}>`, await the server response, invalidate the affected query keys on `Success`, and show a localized toast via `Toaster`.

---

## 15. Token Management, Auth Interceptors & Idle Session Lock (FR-1.x)

1. **Interceptors on shared `HttpClient` (`src/network/http_client.ts`):**
   - `AcceptLanguageInterceptor`: attaches `Accept-Language: <ar|en>` to every request.
   - `AuthInterceptor`: attaches `Authorization: Bearer <accessToken>` from `AuthSession` (in-memory), skipping public auth endpoints (`/api/v1/auth/login`, `/api/v1/auth/otp/verify`, `/api/v1/auth/otp/resend`, `/api/v1/auth/refresh`, `/api/v1/auth/invitations/accept`).
   - `RefreshMutexInterceptor`: triggers **only on HTTP `401`** (never on `403` — `403` means insufficient permission/scope or disabled feature flag). Excluded from retry: `/api/v1/auth/login`, `/api/v1/auth/refresh`, `/api/v1/auth/logout`.
2. **Serialised single-use refresh rotation:**
   - A shared promise mutex serialises concurrent `401` responses: if a refresh is already in flight, queued callers await the same promise; otherwise call `POST /api/v1/auth/refresh` (sending the `HttpOnly; Secure; SameSite=Strict` refresh cookie).
   - On `200`, store the new `accessToken` in `AuthSession` memory and retry the original request.
   - On `401` from `/api/v1/auth/refresh` (expired, revoked, or reuse detected), emit `LoginRequired` on `AuthEventBus`, clear `AuthSession`, call `queryClient.clear()`, and redirect to `/login`.
3. **Idle Session Lock (`IdleLockWatcher`):**
   - Tracks user interaction events (`pointerdown`, `keydown`, `scroll`, throttled) and locks/terminates the session after `VITE_IDLE_TIMEOUT_MINUTES` of inactivity, wiping in-memory caches so an unattended church office computer never exposes minor/member records.

---

## 16. Error Handling, Toasts & Logging

### 16.1 Discriminated Union `AppError` Hierarchy (`src/network/errors.ts`)

Every error in the dashboard is represented as a member of the discriminated union `AppError` — never raw `Error`, `Response`, or `unknown`:

```ts
export type AppError =
  | { readonly kind: 'NetworkError'; readonly message: string }
  | { readonly kind: 'TimeoutError'; readonly message: string }
  | { readonly kind: 'ParseError'; readonly message: string; readonly cause?: unknown }
  | {
      readonly kind: 'ServerError';
      readonly statusCode: number;
      readonly code?: string;
      readonly fieldErrors: Readonly<Record<string, string>>;
      readonly message: string;
    }
  | { readonly kind: 'ForbiddenScopeError'; readonly message: string }
  | { readonly kind: 'FeatureDisabledError'; readonly featureKey?: string; readonly message: string }
  | { readonly kind: 'ConflictError'; readonly serverCopy?: Record<string, unknown>; readonly message: string }
  | { readonly kind: 'NotFoundError'; readonly message: string }
  | { readonly kind: 'LoginRequired'; readonly forceLogout: boolean; readonly message: string }
  | { readonly kind: 'UnknownError'; readonly message: string; readonly cause?: unknown };
```

- `ErrorParser.parse` maps backend `BaseResponseBody` failures (`400` with `fieldErrors`, `401` → `LoginRequired`, `403` → `ForbiddenScopeError` or `FeatureDisabledError`, `404` → `NotFoundError`, `409` → `ConflictError` or `ServerError`, `429`, `500`) using the server's already-localized `message` when present, falling back to `LocaleKeys.errors_*`.
- User feedback goes exclusively through `Toaster` (`Toaster.showSuccess / showError / showWarning`). Never call `window.alert` or third-party toast functions directly from feature pages.
- A route-level `RouteErrorBoundary` catches unexpected render errors, logs only non-PII diagnostic metadata via `AppLogger.e`, and renders `<DefaultErrorView />` with a retry button.

### 16.2 Logging (`AppLogger`)

- Log only through `AppLogger.d/i/w/e` (`src/core/logger/app_logger.ts`), which is a no-op in production builds (`VITE_ENV_NAME === 'prod'`) and automatically scrubs sensitive keys.
- Never log a `Person`, `ServedMember`, `PastoralNote`, `ConsentForm`, DTO object, or request/response JSON body. Log only opaque UUIDs (`memberId`, `occurrenceId`, `taskId`) and counts.

---

## 17. Permission-Gated, Scope-Aware UI & Safeguarding (BRD §6, FR-13.x)

ServeConnect is a **role-based, multi-scope platform** (`docs/00-brd.md` §6) backed by **permission-based, scope-aware authorization** (`sev_connect_backend/CLAUDE.md` §11, `serv_connect_mobile/CLAUDE.md` §17).

### 17.1 Permission & Scope Rules (Never Branch on Role Names)

1. **Roles are data, permissions are code:** A signed-in user holds one or more `RoleAssignment`s, each granting a set of **permission keys** (`<feature>.<action>[.<qualifier>]`, e.g. `members.read.full`, `members.notes.read`, `groups.assign-servants`, `lessons.approve`, `audit.read`, `admin.roles.manage`) within a **scope** (`ORG`, `STAGE`, `GROUP`, `SELF`, `CHILDREN`).
2. **Never write `if (user.role === 'ADMIN')` or `if (user.isCoord)`:** Always query `PermissionChecker` (`src/core/permissions/permission_checker.ts`) via `usePermissions()`:
   - Coarse check (for sidebar navigation items & route guards): `permissionChecker.hasAnyScope('audit.read')`
   - Scoped check (for a specific stage, group, or member action): `permissionChecker.hasPermission('members.notes.read', { scopeType: 'GROUP', targetId: member.groupId })`
   - Declarative wrapper: `<RequirePermission perm="groups.assign-servants" scopeType="STAGE" targetId={stageId}>...</RequirePermission>`
3. **Feature flags (FR-16.5):** Every module is also gated by `FeatureFlagService.isEnabled(FeatureModule.<name>)` from the cached `OrgConfig`. Both route guards (`ScopeGuard`) and sidebar navigation hide disabled modules automatically.

### 17.2 Safeguarding & Audit Rules on the Dashboard (FR-13.1–13.5)

1. **Audited Sensitive reads (FR-13.2):** Opening a drawer, tab, or modal that displays a **Sensitive** record (`PastoralNote`, medical/emergency info on a `ServedMember`, `ConsentForm`, safeguarding incident) must dispatch `recordSensitiveAccessUseCase` (and/or hit the dedicated backend endpoint that records an `AuditEntry` with `action: VIEW`, `targetType`, `targetId`, `scopeUsed`, `occurredAt`).
2. **Data minimization in tables & lists (FR-13.3):** Directory, group roster, and attendance tables use `MemberSummaryEntity` (id, display name, photo + `photoConsent`, stage/group badge) — never load Sensitive fields into list/table states.
3. **Immediate scope revocation:** If an API response or session refresh signals that a scope was revoked (`ScopeRevokedEvent`), purge affected query caches and redirect the user back to the dashboard home with a localized toast (`LocaleKeys.errors_scope_revoked`).

---

## 18. Form State (React Hook Form + Zod + Centralised Validators)

- Use **React Hook Form + Zod** (or controller-owned state for multi-step wizard flows) with schemas defined in `src/features/<feature>/presentation/<screen>/` composed from centralized primitives in `src/core/validation/validation.ts` (`Validation.emailSchema`, `Validation.phoneSchema`, `Validation.passwordSchema`, `Validation.requiredTextSchema`, `Validation.uuidSchema`, etc.).
- Never scatter raw regexes across components; all validation rules live in `src/core/validation/validation.ts` and return localized error keys (`LocaleKeys.validation_*`).
- Map backend `400` `ServerError.fieldErrors` directly onto form fields via `setError(field, { message })` inside the controller hook.
- Submit buttons bind `isLoading={isSubmitting}` and `disabled={isSubmitting || isOffline}`.

---

## 19. Performance, Large Tables & Re-render Discipline

- **Code splitting:** Lazy-load feature route bundles at the feature boundary (`React.lazy`) wrapped in a shell-level `<Suspense fallback={<ServeTableShimmer />}>` so `main.tsx` stays small and initial load is fast.
- **Large tables & rosters:** Tables or lists that can exceed 50 rows (member directory, audit log viewer, attendance history) use server-side pagination (Spring `Page<T>`) and/or row virtualization, with stable `key={item.id}` — never array index keys (`key={index}`).
- **Re-render discipline:** Keep component props flat and immutable; extract row components (`<MemberTableRow member={member} onSelect={onSelect} />`) so changing one row's selection does not rebuild the entire table chrome.
- **Member avatars:** Render exclusively via `<ServeMemberAvatar />`, which checks `member.photoConsent === true` before rendering `<img loading="lazy" ... />` and falls back to deterministic initials when `false`.

---

## 20. State Management Boundaries

| State Type | Lives In |
| --- | --- |
| Ephemeral UI widget state (dropdown open, local hover/focus, uncontrolled input ref) | Local component `useState` / `useRef` |
| Screen orchestration, filters (including PII search text), pagination, modal state, form submission | Screen controller hook `use<Screen>Controller` |
| Server data & caching | TanStack Query (wrapped inside `features/<feature>/data/api/` + controller hook; never copied to Zustand) |
| Authenticated session, in-memory `accessToken`, active `RoleAssignment`s / scopes, idle lock state | `AuthSession` (`src/core/session/auth_session.ts`) |
| Organisation config, custom role labels, active feature flags | `OrgConfigController` / query (`src/core/config/`) |
| Active locale (`ar` / `en`) & layout direction (`rtl` / `ltr`) | `LocaleController` (`src/core/i18n/`, persisted in `localStorage` under non-sensitive key `serve_locale`) |
| Cross-page UI shell state (sidebar collapsed) | Small Zustand store (`useAppShellStore`) — UI booleans only, zero server/PII data |
| Cross-feature one-shot events (login required, scope revoked, idle lock triggered) | `AppEventBus` / `AuthEventBus` |
| Route parameters | React Router params — **opaque UUIDs only** (`/members/:memberId`), never PII |

---

## 21. Accessibility (NFR-7)

- Target **WCAG 2.1 AA**: contrast ≥ 4.5:1 for normal text and ≥ 3:1 for large text/UI components, defined solely through `src/styles/tokens.css`.
- **Keyboard & Focus:** Every interactive control reachable and operable via keyboard (`Tab`, `Enter`, `Space`, `Escape`, arrow keys in `ServeTabs`/`ServeSelect`); visible `:focus-visible` ring using token variables; focus trapped inside open `ServeModal` / `ServeDrawer` and restored to the trigger element on close.
- **Semantics & Screen Readers:** Proper landmark regions (`<nav>`, `<header>`, `<main>`), `<table role="table">` with `<th scope="col">`, `<label htmlFor>` on every form control, localized `aria-label` on every `ServeIconButton`, and `aria-live="polite"` for `Toaster` and async status regions.
- **Motion:** Respect `@media (prefers-reduced-motion: reduce)` across all transitions and shimmers.

---

## 22. Dead Code, Module Boundaries & Sanctioned Package Stack

- Remove unused imports, private helpers, unused template assets, and dead files immediately — never comment them out.
- **Sanctioned package stack** (any addition requires explicit user approval in the task plan):
  - **Core & Build:** `react`, `react-dom`, `typescript`, `vite`, `@vitejs/plugin-react`, `oxlint`
  - **Routing & State:** `react-router`, `@tanstack/react-query`, `zustand` (UI shell state only)
  - **Forms & Validation:** `react-hook-form`, `@hookform/resolvers`, `zod`
  - **Localization:** `i18next`, `react-i18next`
  - **Sanitization (when rendering rich ContentPack HTML):** `dompurify`, `@types/dompurify`
  - **Testing:** `vitest`, `@testing-library/react`, `@testing-library/user-event`, `@testing-library/jest-dom`, `jsdom`, `msw`, `@playwright/test`
- **Forbidden packages & patterns (release blocker):**
  - Redux / MobX / Recoil / Jotai (use TanStack Query + `use<Screen>Controller` + minimal Zustand UI shell store)
  - Axios (use the typed `fetch`-based `HttpClient` in `src/network/http_client.ts`)
  - Heavy third-party component kits (`@mui/*`, `antd`, `chakra-ui`, `bootstrap`) that override the ServeConnect Dashboard design system (§13.2)
  - `localStorage` / `IndexedDB` query cache persisters (`@tanstack/query-sync-storage-persister`, `localforage`) — PII/Sensitive member data must never be persisted to browser storage (§7)

---

## 23. Check Before Building & Recommended Build Order

### 23.1 Check before building
1. Read `docs/00-brd.md` for the module and `FR-x.y` being implemented.
2. Read `docs/01-project-overview.md` for the monorepo architecture baseline.
3. Read `docs/03-api-reference.md` for the REST endpoints, request/response envelopes, and error codes.
4. Read `docs/04-security.md` for the required permission keys, scopes, and PII/Sensitive rules.
5. Read `docs/08-dashboard-architecture.md` for the dashboard structure, routing, auth flow, and the `Serve*` Shared UI Component Catalogue.
6. Read the matching design files in `designs/dashboard/en/` and `designs/dashboard/ar/`.
7. Grep `src/` for existing `UseCase`s, `Repository`s, `Mapper`s, controller hooks, and `Serve*` components; extend/reuse before creating new ones.

### 23.2 Recommended build order (aligned with Backend & Mobile §23.2; each step is its own approved plan)

0. **Foundation (D0)** — strip Vite template; sanctioned `package.json` dependencies + scripts (`lint`, `build`, `test`, `test:coverage`, `i18n:generate`, `i18n:check`); `.env.example`; `src/styles/tokens.css` + `global.css` + fonts (Inter, Fraunces, Cairo, Amiri); `src/core/` (`AppEnvironment`, `AppLogger`, `AuthSession`, `IdleLockWatcher`, `PermissionChecker`, `RequirePermission`, `AppEventBus`, `AppFormatters`, `Validation`, `i18n` with EN/AR + RTL switching + typed `locale_keys.g.ts`); `src/network/` (`HttpClient`, `ApiResult`, `Resources`, `AppError`, `safeCall`, `AuthInterceptor`, `RefreshMutexInterceptor`, `AcceptLanguageInterceptor`); initial `Serve*` component catalogue (`ServeButton`, `ServeTextField`, `ServeSelect`, `ServeTable`, `ServeCard`, `ServeBadge`, `ServeModal`, `ServeDrawer`, `ServeTabs`, `ServeMemberAvatar`, `ServeEmptyState`, `ServeOfflineBanner`, `ServeTableShimmer`, `DefaultErrorView`, `Toaster`); `AppShell` (sidebar + topbar from mockups) + `AppRouter`; Vitest + RTL + MSW setup; and initial `docs/08-dashboard-architecture.md`.
1. **`identity` + `admin` basics (D1)** — Login, invitation acceptance, session refresh & logout, idle lock screen, `PermissionChecker` & scope gating, `OrgConfig` (org profile, stages, feature flags, custom role labels — FR-1.1–1.4, FR-16.1–16.5).
2. **`members` + `safeguarding` / `audit` basics (D2)** — `ServedMember` & `Servant` directory, Member Profile, family links, portable history (FR-2.1–2.4), `ServeMemberAvatar` with `photoConsent` gate, audited Sensitive reads (`AuditEntry`), and Safeguarding & Audit log viewer (FR-13.1–13.5).
3. **`groups` (D3)** — Stages, groups, servant assignments, member rosters, and annual stage promotion workflow (FR-3.1–3.4).
4. **`schedule` → `attendance` → `tasks` leadership oversight (D4)** — Recurring schedule & Event Editor (FR-4.1–4.4), attendance & absentee follow-up oversight + absence threshold alerts (FR-5.1–5.4), and Tasks Kanban/list management (FR-6.1–6.3).
5. **`admin` users/roles + `communication` + `content` MVP (D5)** — User & role/scope provisioning (FR-16.3), announcements (FR-7.1), and `ContentPack` library management (FR-9.1–9.3).
6. **Phase 2 modules (D6+)** — Built only on explicit user request (`curriculum` builder & approval, `engagement` memorization/points, `trips` + consent verification, `PastoralNote`s, `analytics` & reporting, `prayer` board moderation).

A dashboard step never gets ahead of the backend: each screen waits until its endpoints are documented in `docs/03-api-reference.md` and implemented in `sev_connect_backend/`.

---

## 24. Definition of Done for Safeguarding-Relevant Work

Any dashboard task touching a minor's record (`ServedMember`), a Sensitive field (`PastoralNote`, medical/emergency info, `ConsentForm`, safeguarding incident), a permission/scope check, or member data display/export is done **only** when:

- [ ] Every route, screen, and action is gated by `PermissionChecker` + `ScopeGuard` / `<RequirePermission>` (matching `docs/04-security.md`) and tested for both in-scope and out-of-scope (`403`) states.
- [ ] Every view, edit, or export of a Sensitive record dispatches/triggers an `AuditEntry` (and a unit/controller test asserts it).
- [ ] Member photos render exclusively through `ServeMemberAvatar` and respect `photoConsent === false` (tested).
- [ ] Sensitive queries use `staleTime: 0` and `gcTime: 0`, are never prefetched in list/table queries, and are purged immediately on unmount, scope revocation, idle lock, or logout (tested).
- [ ] Zero PII appears in `AppLogger` calls, route URLs/query strings (`window.location`), `document.title`, `localStorage`/`sessionStorage`/`IndexedDB`, or analytics/error payloads (tested).

---

## 25. Post-Task Documentation Updates

**Every task ends with a documentation + plan update** in the monorepo-root `docs/` and `plans/` folders. "Code compiles and tests pass" is not "done".

### 25.1 Shared & Dashboard Documentation Map (`../docs/` & `../plans/`)

| Document | Scope & When to Update |
| --- | --- |
| `plans/YYYY-MM-DD_dashboard_<slug>.md` + `plans/README.md` | Tick completed steps, append dated progress log with commit hash, keep status & index row current |
| `docs/00-brd.md` | Business Requirements Document (read-only unless user explicitly changes requirements) |
| `docs/01-project-overview.md` | Monorepo overview, module status matrix (MVP/P2/P3), `.env.example` keys |
| `docs/02-database-schema.md` | Backend PostgreSQL schema (backend tasks) |
| `docs/03-api-reference.md` | REST endpoints consumed/added, request/response shapes, required permission + scope + feature flag |
| `docs/04-security.md` | Permission keys, default roles, scope rules, PII/Sensitive handling, client/server audited actions |
| `docs/05-localization.md` | Supported locales (`ar`, `en`), translation key namespaces, configurable org labels, RTL rules |
| `docs/08-dashboard-architecture.md` | Dashboard Clean Architecture (`use<Screen>Controller`, `ApiResult`, `Resources`, `AppError`, `AuthSession`, idle lock, routing, and the **`Serve*` Shared UI Component Catalogue**) |
| `docs/features/dashboard-<name>.md` | Per-feature dashboard doc (when created): screens, controllers, states/actions, UseCases, endpoints, permissions, and cross-feature dependencies |
| `docs/walkthroughs/YYYY-MM-DD_dashboard_<slug>.md` | Per-task walkthrough (§3) + one-line index entry in `docs/walkthroughs/README.md` |

Verify before committing (from the monorepo root):

```bash
grep -rn "<renamed-symbol-or-obsolete-term>" docs/   # no stale references
git status -- docs/ plans/                            # expect changes matching the task
git diff -- docs/ plans/
```

If `git status -- docs/ plans/` shows no changes after a code change, stop and ask whether a docs update was really not needed (default: it was).

---

## 26. Code Generation Hygiene (`locale_keys.g.ts`)

Generated files are **committed** to git so fresh checkouts type-check immediately and PR diffs show exact generated changes.

| Source Input | Generated Output | Purpose |
| --- | --- | --- |
| `src/locales/{en,ar}/*.json` | `src/generated/locale_keys.g.ts` | Strongly-typed translation keys & namespace parity verification |

Rules:
- Never hand-edit a file in `src/generated/`.
- After changing any file in `src/locales/en/` or `src/locales/ar/`, run `npm run i18n:generate && npm run i18n:check` and commit `src/generated/locale_keys.g.ts` in the same commit.

---

## Quick Reference — Mandatory Actions Per Task

All task types require **Plan & Approval (`plans/*.md`)**, **FR-x.y IDs cited**, a **Commit**, a **Walkthrough** (`docs/walkthroughs/YYYY-MM-DD_dashboard_<slug>.md`), and a **Docs Update** in `../docs/`. The table below covers conditional requirements:

| Task Type | Design + Tokens + a11y + RTL | API Contract (`docs/03`) | Catalogue (`docs/08`) | Shimmer / States (`Resources<T>`) | Permission / Scope / Safeguarding (§24) | Codegen (`i18n`) | Tests (≥ 70 %) |
| --- | --- | --- | --- | --- | --- | --- | --- |
| New feature / screen | ✅ (`en` + `ar` designs) | ✅ | ✅ If new `Serve*` primitive | ✅ Shimmer + empty/error/403 | ✅ `PermissionChecker` + `ScopeGuard` | If new strings | ✅ Controller + Component + Scope + RTL |
| New shared `Serve*` widget | ✅ | — | ✅ Add row in `docs/08` | If data-loading | If rendering member data/avatar | If labels | ✅ Component + a11y + RTL |
| Modified shared `Serve*` widget | ✅ | — | ✅ Update row in `docs/08` | If affected | If rendering member data/avatar | — | ✅ Regression |
| New UseCase / Mapper / Repo | — | ✅ If new endpoint/DTO | — | ✅ `ApiResult<T>` + `safeCall` | ✅ Scope & PII check | — | ✅ Unit + MSW |
| Sensitive / Minor data screen | ✅ | ✅ Separate endpoint | — | ✅ `staleTime: 0, gcTime: 0` | ✅ Full §24 checklist + `AuditEntry` | If strings | ✅ Audit + Consent + 403 + Cache wipe |
| New form | ✅ | ✅ Validation alignment | ✅ If new input widget | ✅ Loading + field error map | ✅ Scope check | If validation keys | ✅ Validation + Submit + Error mapping |
| New translation key | ✅ RTL check | — | — | — | — | ✅ `i18n:generate` + `i18n:check` | — |
| New route | — | — | — | — | ✅ `AuthGuard` + `ScopeGuard` + UUID-only URL | — | ✅ Guard + No-PII-in-URL test |
| Bug fix | If UI | If API | If changed | If affected | If safeguarding-related | If strings changed | ✅ Regression test |
| Refactor | If UI | — | If changed | — | Preserve all guards | — | ✅ Coverage ≥ 70 % + line limits |
| Config / `VITE_*` change | — | — | — | — | ✅ §4 + §7 checklist | — | ✅ `AppEnvironment` startup test |
