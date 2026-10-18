# ServeConnect — Flutter Mobile Client (`serv_connect_mobile`) — Claude Development Rules

> **Claude must read and follow every rule in this file before starting _any_ task.**
> These rules are non-negotiable and apply to **every kind of work** — a new feature, a bug fix, a refactor, a chore, a one-line hot-fix, a spike, or a question whose answer leads to a code change. "It's only a small change" is never grounds to skip a rule.
>
> A task does not end with the code compiling or `flutter analyze` passing. **A task ends only when the relevant `docs/*.md` files have been updated** to reflect the change (see §25 — Post-Task Documentation Updates). Any change that alters behaviour without touching the matching docs is incomplete.
>
> **Scope:** the **ServeConnect** Flutter application in `serv_connect_mobile/` of the ServeConnect monorepo (Dart SDK `^3.13.5`, targets **Android + iOS**; macOS/Windows/Linux/Web folders exist from `flutter create` for local dev harness only unless promoted by an approved plan). It is the **offline-first, single role-based mobile client** for the ServeConnect platform (paired with the Spring Boot Kotlin backend in `sev_connect_backend/`) used by churches to connect **servants** (volunteers, teachers, mentors, leaders) with the **served** (members, children, youth, families). Because the system holds data about **minors**, every member-identifying field is treated as **PII** and every pastoral/medical/consent field as **Sensitive** by default (see §7 & §17 — Security, Safeguarding & PII Handling).
>
> **Architecture note vs. BRD draft:** `docs/00-brd.md` §4/§10 originally drafted KMP/SQLDelight as a candidate stack; **this Flutter project (`serv_connect_mobile/`) is the chosen mobile implementation.** All functional requirements (`FR-x.y`), non-functional requirements (`NFR-1`..`NFR-13`), RBAC/scope rules (§6), and offline-first sync semantics (§11) in `docs/00-brd.md` apply in full, implemented here with **Flutter Clean Architecture + `BaseCubit` + encrypted `HiveStorage` + `Dio`/`Retrofit`**.
>
> **Monorepo layout.** Documentation is **global to the monorepo**, not per project:
>
> ```
> Serv-Connect/                  # monorepo root
> ├── docs/                      # shared docs — BRD, API contract, sync protocol, security, mobile docs, walkthroughs
> ├── sev_connect_backend/       # Spring Boot (Kotlin) backend (governed by sev_connect_backend/CLAUDE.md)
> └── serv_connect_mobile/       # this project — Flutter mobile client
> ```
>
> Every `docs/...` path in this file means the **monorepo-root** `docs/` (i.e. `../docs/` from `serv_connect_mobile/`). Never create a `docs/` folder inside `serv_connect_mobile/`. Mobile tasks never edit files under `sev_connect_backend/`; if a mobile change requires a backend API or sync change, state it in the plan and walkthrough instead.
>
> **Business source of truth.** The Business Requirements Document — `docs/00-brd.md` — defines the modules, roles, phases, and functional requirements (`FR-x.y`). Every plan, commit, and walkthrough cites the `FR-x.y` IDs it implements. If a request contradicts the BRD, flag it before building.
>
> **Current state.** This is a **fresh `flutter create` skeleton**: only the default counter `lib/main.dart`, `pubspec.yaml` (`sdk: ^3.13.5`), and default platform runners exist. **Nothing in `lib/core/`, no DI, no routing, no network/sync layer, no `docs/01+` exist yet.** The first approved tasks build the foundation (§23.2 — Recommended Build Order). Do not assume any class, package, or doc mentioned in this file exists — grep first (§0). Where this file describes something not yet built, it is the **target design** the foundation must implement.

---

## 0. Pre-Task Checklist

Before writing a single line of code, Claude must:

1. Read this file in full.
2. Identify the **BRD module and `FR-x.y` IDs** the task touches (`docs/00-brd.md`), and their **phase tag** (`[MVP]`, `[P2]`, `[P3]`). Do not build a `[P2]`/`[P3]` requirement unless the user explicitly asked for it (§2.1).
3. **Create a written plan** for the task — listing every file/class to be created or modified, the feature package it lives in, the Cubit states/actions/nav effects, the permission keys and scopes involved (§17), the offline/sync & conflict strategy for any cached/mutated entity (§12), and any decisions made — and **wait for explicit approval** before proceeding. No code is written until the plan is approved.
4. **Check the theme & UI catalogue** (`docs/08-mobile-theme-and-ui-components.md` and `lib/core/theme/` + `lib/core/common_ui/`) before inventing any colour, text style, radius, spacing, button, input, card, toast, or bottom sheet. Never add a new `Serve*` primitive without confirming none covers the need.
5. **Check the API & Sync contract** (`docs/03-api-reference.md`, `docs/06-sync.md`, `docs/postman-collection.json`). If a required endpoint or sync entity is missing from the backend contract, **stop and report exactly which** — never invent undocumented paths or workarounds.
6. If modifying an existing feature, re-read its feature doc (`docs/features/13-feature-<name>.md`).
7. Grep `lib/` for existing `UseCase`s, `Repository` implementations, `Mapper`s, `Cubit`s, widgets, and validators before reinventing; extend or parameterise existing code and justify any new implementation in the walkthrough.
8. State the plan and wait for approval on any destructive action (`flutter clean` on a busy build, `rm -rf`, keystore overwrite, force-push, Hive schema/box migration that drops cached data, deleting generated files).

---

## 1. Project Structure, Feature Map & Component Catalogue

### 1.1 Feature-first Clean Architecture layout

Organise by **feature (vertical slice)** under `lib/features/<feature>/`, matching the backend feature names (`sev_connect_backend/CLAUDE.md` §1.1) 1-for-1:

```
lib/
├── main.dart                                # never run directly; delegates to bootstrap
├── main_dev.dart                            # dev flavor entry
├── main_staging.dart                        # staging flavor entry
├── main_prod.dart                           # prod flavor entry
├── app.dart                                 # root ServeConnectApp widget, global listeners
├── core/                                    # cross-cutting primitives (never imports features/)
│   ├── base/                                # BaseCubit<T, A, NE>
│   ├── common_ui/                           # Serve* shared widgets, shimmers, DefaultErrorView, Toaster, BottomSheetHost
│   ├── config/                              # AppEnvironment, FlavorConfig, FeatureFlagService
│   ├── event_bus/                           # AppEventBus, AuthEventBus
│   ├── l10n/                                # AppLocale, LocaleCubit
│   ├── logger/                              # AppLogger (PII-safe, no-op in release)
│   ├── permissions/                         # PermissionChecker, ScopeGuard, PermissionKeys
│   ├── platform/                            # ServePlatform abstract + MethodChannel impl
│   ├── services/                            # ConnectivityService, LocalNotificationScheduler, MediaCacheManager
│   ├── storage/                             # SecureStorage, Preferences, HiveStorage (AES-256 encrypted)
│   ├── sync/                                # SyncEngine, OutboxProcessor, DeltaPuller, ConflictResolver
│   ├── theme/                               # AppColors, AppTypography, AppTheme, ServeBreakpoints
│   └── utils/                               # AppFormatters, Validation, IdGenerator (UUID v4)
├── network/                                 # DioModule, interceptors, ApiResult<T>, Resources<T>, Errors, BaseApiResponse<T>, _safeCall
├── di/                                      # get_it + injectable bootstrap (injection.dart, injection.config.dart)
├── routing/                                 # AppRouter (@AutoRouterConfig), AuthGuard, ScopeGuard, DeepLinkRoutes
├── generated/                               # locale_keys.g.dart, assets.gen.dart
└── features/
    └── <feature>/
        ├── presentation/
        │   ├── <screen>/
        │   │   ├── view/
        │   │   │   ├── <screen>_cubit.dart
        │   │   │   ├── <screen>_states.dart
        │   │   │   └── <screen>_page.dart
        │   │   └── widgets/                 # screen-local sub-widgets
        │   └── widgets/                     # feature-shared widgets & shimmers
        ├── domain/
        │   ├── entities/
        │   ├── repository/
        │   └── use_case/
        └── data/
            ├── datasource/
            │   ├── remote/                  # Retrofit <Feature>RemoteDataSource
            │   └── local/                   # <Feature>LocalDataSource (HiveStorage)
            ├── model/                       # @JsonSerializable DTOs & cached documents
            ├── mapper/                      # <Feature>Mapper (DTO/Doc ↔ Domain Entity)
            └── repository/                  # <Feature>RepositoryImpl
```

### 1.2 Planned feature packages (1:1 with BRD §7 & Backend §1.1)

Use these exact feature directory names under `lib/features/` — do not invent synonyms:

| BRD Module | Feature Dir | Purpose | Earliest Phase |
| --- | --- | --- | --- |
| 8.1 Authentication, Onboarding & Identity | `identity` | Sign-in (phone/email + password, OTP), invitations, role/scope session, offline grace window | MVP |
| 8.2 Member Directory & Records | `members` | Served & servant profiles, family links, portable history, pastoral notes (P2) | MVP |
| 8.3 Groups & Assignments | `groups` | Stages, groups, servant assignments, memberships, annual promotion flow | MVP |
| 8.4 Scheduling & Events | `schedule` | Recurring meetings, single vs. series edits, personalised schedule, conflict warnings | MVP |
| 8.5 Attendance & Follow-up | `attendance` | Offline attendance marking, absentee follow-up queue, outcome logging, absence alerts | MVP |
| 8.6 Task Management | `tasks` | Kanban/list tasks, assignee/due/priority, My Tasks, auto-created follow-up tasks | MVP |
| 8.7 Communication & Collaboration | `communication` | Group/stage/org announcements (MVP), contextual threads & DMs (P2) | MVP→P2 |
| 8.8 Curriculum & Lesson Management | `curriculum` | Prepare → submit → approve → offline "Deliver mode" | P2 |
| 8.9 Content Library | `content` | Configurable ContentPacks: Bible reading & tracking, daily verse, hymns, readings, prayers, liturgical calendar | MVP→P2 |
| 8.10 Memorization & Points | `engagement` | Memorization tracker, points ledger, badges, opt-in leaderboards | P2 |
| 8.11 Trips, Conferences & Logistics | `trips` | Registration, digital parent consent + e-signature, payment tracking, rooming/bus | P2 |
| 8.12 Notifications & Reminders | `notifications` | Push notifications, on-device local meeting/task reminders, quiet hours & preferences | MVP |
| 8.13 Safeguarding, Privacy & Audit | `safeguarding` + `audit` | Scope-gated views, photo-consent enforcement, sensitive-access audit log viewer | MVP→P2 |
| 8.14 Analytics & Reporting | `analytics` | Attendance trends, at-risk dashboards, servant workload summaries | P2→P3 |
| 8.15 Prayer & Praise Board | `prayer` | Moderated prayer requests, "praying" counter, praise reports | P2 |
| 8.16 Administration & Configuration | `admin` | Org profile, stages, content-pack selection, feature flags, role/scope provisioning | MVP |
| §11 Data & Sync Strategy | `sync` | Sync status banner/sheet, manual "Sync now", pending outbox inspector, conflict resolution UI | MVP |

### 1.3 Domain vocabulary & non-negotiable business rules

Use the exact BRD glossary (`docs/00-brd.md` §16) and backend entity names (`sev_connect_backend/CLAUDE.md` §1.2) across Dart entities, DTOs, and Cubits:
- `Person`, `Servant`, `ServedMember`, `FamilyLink`, `Stage`, `Group`, `GroupType`, `GroupAssignment`, `GroupMembership`, `Event`, `EventOccurrence`, `AttendanceRecord` (`PRESENT` / `ABSENT` / `EXCUSED`), `FollowUp`, `PastoralNote`, `Task` (`FOLLOW_UP` / `LESSON_PREP` / `LOGISTICS` / `GENERAL`), `ContentPack`, `ContentItem`, `AuditEntry`, `RoleAssignment`.
- **Denomination-neutral (BRD §8.9):** Never hard-code tradition-specific prayers, readings, feasts, saints, calendars, or hymn sets in Dart code or translation files. All liturgical/spiritual content comes from a downloaded `ContentPack`. Role/group UI terminology ("Servant", "Stage", "Sunday School") supports org-level label overrides where configured.
- **Record portability (FR-2.4):** When a `ServedMember` moves group/stage, their full history stays intact; a servant who loses group scope immediately loses cached access via sync revocation (§12.4).
- **Payments are tracking-only (FR-11.4):** Never add card inputs, payment gateway SDKs, or bank fields. Trip payment screens only record/view who paid, amount, and date.
- **Consent gates (FR-11.3, FR-13.5):** Never render a member photo if `photoConsent == false` (render the initials placeholder avatar in `ServeAvatar` instead). Never allow marking a minor "cleared to travel" in UI without a valid `ConsentForm`.

### 1.4 Shared UI Component Catalogue

- Shared-UI catalogue lives in `lib/core/common_ui/` (prefixed `Serve*`: `ServeButton`, `ServeTextField`, `ServeAvatar`, `ServeBadge`, `ServeCard`, `ServeEmptyState`, `ServeSyncBanner`, …) and is documented in `docs/08-mobile-theme-and-ui-components.md`.
- Every new shared widget gets a row in `docs/08-mobile-theme-and-ui-components.md` before commit: class name, file path, full constructor signature (named params + defaults), and one-line purpose.
- Check `docs/08` before building any UI primitive; extend/parameterise rather than duplicate. Update the entry whenever parameters change.
- Feature-specific widgets stay in `lib/features/<feature>/presentation/<screen>/widgets/` (or `lib/features/<feature>/presentation/widgets/`) and are **not** catalogued — the catalogue is for cross-feature primitives.

---

## 2. Git Commits & Phase Discipline

- Commit after every completed, working unit. Format:

  ```
  <type>(<scope>): <short description>

  <body — what & why, if non-obvious; cite FR-x.y IDs>
  ```

- Never add a `Co-Authored-By` trailer to commit messages.

- Valid types: `feat`, `fix`, `refactor`, `test`, `docs`, `chore`, `build`, `perf`, `security`.
- Valid scopes: feature package names (`identity`, `members`, `groups`, `schedule`, `attendance`, `tasks`, `communication`, `curriculum`, `content`, `engagement`, `trips`, `notifications`, `safeguarding`, `audit`, `analytics`, `prayer`, `admin`, `sync`) or mobile infra (`network`, `storage`, `di`, `routing`, `theme`, `l10n`, `ci`, `android`, `ios`).
- **Never commit:**
  - Secrets/signing files (`.env`, `.env.dev`, `.env.staging`, `.env.prod`, `key.properties`, `keystore.properties`, `google-services.json`, `GoogleService-Info.plist`, `*.jks`, `*.p8`, `*.p12`, `*.mobileprovision`).
  - Build/IDE artefacts (`build/`, `.dart_tool/`, `.flutter-plugins*`, `ios/Pods/`, `ios/.symlinks/`, `ios/Flutter/Flutter.framework`, `ios/DerivedData/`, `android/.gradle/`, `android/app/release/`, `android/local.properties`, `*.iml`, `.idea/`).
  - Failing tests or analyzer warnings (`dart format --set-exit-if-changed .`, `flutter analyze`, and `flutter test` must exit `0`).
  - Stray `print`/`debugPrint`/`log` in production code (use `AppLogger`, §16).
  - Commented-out code blocks — delete instead.
  - Real member/minor PII (real names, photos, phone numbers) in tests, golden fixtures, or preview data.
  - Hand-written `.dart` files exceeding **250–300 lines** or any function/method/`build()` exceeding **20–25 lines** (§9.1) — split into smaller functions, sub-widgets, or files before committing.
  - Modified source annotations (`@JsonSerializable`, `@RestApi`, `@injectable`, `@AutoRouterConfig`, `assets/translations/*.json`) without committing the regenerated `*.g.dart` / `*.gr.dart` / `injection.config.dart` / `locale_keys.g.dart` (§26).
- Never run `--no-verify`, `git push --force` on `main`/`develop`/`release/*`, or `git reset --hard` without explicit user instruction.

### 2.1 Phase discipline

- The BRD ships in phases: **MVP → P2 → P3** (`docs/00-brd.md` §13). MVP is the daily loop: **schedule → attend → follow up → assign tasks**, plus essential content, all offline-first.
- Build only what the current task's `FR-x.y` IDs require. Do not build `[P2]`/`[P3]` screens, fields, or boxes "for later" — design cleanly so they can be added without breaking cached data, and note follow-ups in the walkthrough.

---

## 3. Walkthrough History

- After every completed feature, fix, or significant refactor: create or update `docs/walkthroughs/YYYY-MM-DD_mobile_<short-slug>.md` (the `mobile_` prefix distinguishes mobile walkthroughs from `backend_` ones in the shared monorepo folder) and add a one-line entry to `docs/walkthroughs/README.md`.
- Required sections:
  - **Date**
  - **Summary** (one paragraph)
  - **BRD coverage** (`FR-x.y` IDs + phase tag, fully/partially implemented)
  - **Files changed** (all created/modified; generated files noted when source annotations changed)
  - **API & Sync usage** (endpoints consumed, sync entities cached/queued, conflict strategy, whether `docs/03-api-reference.md` or `docs/06-sync.md` was updated)
  - **Security & Safeguarding impact** (permission keys checked, scopes enforced, PII/Sensitive handling, photo-consent or audit triggers)
  - **Widgets** (new/updated `Serve*` primitives + `docs/08` catalogue update)
  - **DI & Routing** (new registrations/modules, routes, deep links, guards)
  - **Localization** (new keys in both `en.json` and `ar.json` + regenerated `locale_keys.g.dart`, RTL verification)
  - **Platform / Build config** (flavors, native channels, permissions in `AndroidManifest.xml` / `Info.plist`)
  - **Code generation** (generators re-run)
  - **Testing** (unit/widget/cubit/sync test coverage)
  - **Known limitations / follow-ups**

---

## 4. Secrets & Environment Configuration

- All base URLs, environment flags, and client SDK keys live in `.env.<flavor>` inside `serv_connect_mobile/` (`.env.dev`, `.env.staging`, `.env.prod`) — nowhere else. All `.env*` files are gitignored except `.env.example` (which lists every required key with empty/placeholder values).
- Load at startup via `flutter_dotenv` (`lib/core/config/app_environment.dart`) and expose through a typed `@singleton AppEnvironment` — never call `dotenv.env['KEY']` outside `AppEnvironment`.
- Required keys in `.env.example`: `API_BASE_URL`, `ENV_NAME`, `DEFAULT_OFFLINE_GRACE_DAYS`, `MEDIA_CACHE_MAX_MB`, `SYNC_BATCH_SIZE`, `SENTRY_DSN` (optional/when configured).
- `.env.dev`, `.env.staging`, and `.env.prod` are declared as assets in `pubspec.yaml`; in CI, copy `.env.example` to `.env.{dev,staging,prod}` and inject secrets before running `flutter test` or `flutter build`.
- `AppEnvironment.assertConfigured()` must run during bootstrap and **throw immediately** if any required key is missing, empty, or starts with `__` — never silently fall back to empty strings or localhost in staging/prod.
- Firebase (`firebase_messaging` for push, FR-12.1): Android `android/app/src/{dev,staging,prod}/google-services.json`; iOS `ios/Runner/Firebase/{Dev,Staging,Prod}/GoogleService-Info.plist` — all gitignored, wired per flavor via `lib/firebase/firebase_options_<flavor>.dart`. Never commit production Firebase configs or signing keys (`key.properties`, `*.jks`, `*.p12`, `*.mobileprovision`).

---

## 5. Localisation (EN / AR) & RTL-First

- **Every** user-facing string is localised (NFR-6). Supported locales: `ar` (Arabic, RTL) and `en` (English, LTR), matching the backend (`sev_connect_backend/CLAUDE.md` §18). Choice is persisted in `Preferences` (`StorageKey.appLanguage`, non-sensitive) and managed by `LocaleCubit`.
- Every HTTP request sends the active locale in the `Accept-Language` header (`ar` or `en`) via `AcceptLanguageInterceptor` on the shared `Dio` client so backend validation/error envelopes return already localised.
- In widgets, call `LocaleKeys.<scope>_<key>.tr(context: context)` (typed) or `'<prefix>.${value}'.tr(context: context)` (dynamic). **Always pass `context: context` from widget code** — bare `.tr()` freezes `const`/helper widgets on the initial language. Helper methods that compute display strings take `BuildContext` as their first parameter.
  - Sanctioned bare-`.tr()` exceptions: validators in `lib/core/utils/validation.dart`, post-`await` toast strings, and code without `BuildContext` (Cubits, mappers, background notification builders).
  - Only literal-string exception: the language-picker labels (`"العربية"`, `"English"`).
- Translation files live at `assets/translations/en.json` and `assets/translations/ar.json`, organised by feature (`identity.*`, `members.*`, `groups.*`, `schedule.*`, `attendance.*`, `tasks.*`, `content.*`, `sync.*`, `errors.*`, `common.*`). Typed keys are generated to `lib/generated/locale_keys.g.dart`.
- Adding a string: add to **both** `en.json` and `ar.json` in the same change, then regenerate:
  ```bash
  dart run easy_localization:generate -S assets/translations -O lib/generated -o locale_keys.g.dart -f keys
  ```
  Commit the regenerated `locale_keys.g.dart`.
- **Configurable church labels (BRD §16):** Terms like "Servant", "Served Member", and "Stage" have default translation keys (`common.role_servant`, `common.role_served_member`, `common.stage`) that can be overridden by the organisation's cached `OrgConfig` labels. Resolve them via `OrgLabelResolver.of(context).servantLabel` rather than hard-coding.
- **Content packs are data, not translation keys (BRD §8.9):** Bible text, hymns, readings, prayers, and calendar entries come from cached `ContentPack` records per language — never put liturgical content in `en.json`/`ar.json`.
- **RTL-first layout:** Always use `EdgeInsetsDirectional`, `AlignmentDirectional`, `BorderRadiusDirectional`, and ` PositionedDirectional` — **never** `EdgeInsets.only(left:/right:)` or `Alignment.centerLeft/Right`. Custom painters and directional icons must read `Directionality.of(context)`. RTL layout bugs are release blockers.

---

## 6. Timestamps, Timezones & Recurrence

- **Wire format (Backend §14):** Absolute instants arrive from and are sent to the backend as UTC ISO-8601 strings (`Instant`, e.g. `2026-10-18T15:00:00Z`). Always parse with `DateTime.parse(value).toUtc()` and serialise with `dt.toUtc().toIso8601String()`.
- **Offline client timestamps:** When recording an offline mutation (e.g. marking attendance or logging a follow-up), capture `clientRecordedAt = DateTime.now().toUtc()` for display/audit metadata, while relying on the server's monotonic `changeSeq` — **never** the device clock — for sync ordering (§12).
- **Local dates & recurring events (FR-4.1/4.2):**
  - Genuine date-only / time-of-day values (birthdates, "every Friday at 18:00") are transmitted as ISO `YYYY-MM-DD` / `HH:mm` strings and represented in domain entities as value objects (`LocalDateValue`, `LocalTimeValue`) plus the organisation's IANA timezone (`orgTimeZone`, e.g. `Africa/Cairo`) via the `timezone` package — never shifted through UTC midnight.
  - Concrete `EventOccurrence` instances carry UTC start/end `DateTime` instants converted to the organisation/device zone only for display via `AppFormatters`.
- **Display formatting:** Render all dates, times, relative times (`minutesAgo`, `daysAgo`), and localized numerals via `AppFormatters` (`lib/core/utils/app_formatters.dart`) using `intl` `DateFormat` with `context.locale.languageCode`. Never call `DateTime.toString()` or construct raw `DateFormat` inside widgets.
- **Countdowns & timers:** Recompute from wall-clock on each tick (`target.difference(DateTime.now())`) driven by a `Stream.periodic` subscription inside the Cubit — never by decrementing an integer counter.

---

## 7. Security, Safeguarding & PII Checklist (Run Before Every Commit)

Because ServeConnect handles records of **minors** and pastoral care (BRD §8.13, NFR-4, NFR-5), verify every item below before every commit:

- [ ] **No secrets or credentials** in source code, git history, or logs (`.env*` gitignored; `AppEnvironment` used everywhere).
- [ ] **Tokens in `SecureStorage` only:** `accessToken`, `refreshToken`, and the Hive AES-256 encryption key live exclusively in `flutter_secure_storage` via the `SecureStorage` facade — never in `SharedPreferences`, plain Hive boxes, URLs, or logs.
- [ ] **Encrypted local database (NFR-4, FR-13.7):** All Hive boxes holding operational, PII, or Sensitive data are opened through `HiveStorage` using `HiveAesCipher` (key stored in `SecureStorage`). No raw `Hive.openBox` calls outside `HiveStorage`.
- [ ] **Data classification enforced (§17.2):**
  - **PII** (member name, photo, birthdate, phone, email, address, family links) is never logged (`AppLogger`), never placed in URL paths/query params, never sent in analytics/crash breadcrumbs, and never shown in lock-screen local notifications.
  - **Sensitive** data (medical/emergency info, private pastoral notes FR-2.5, consent forms FR-11.3, safeguarding incidents) is stored only in the isolated `sensitive_records` encrypted box (or fetched live), wiped immediately on scope loss or offline grace expiry, and **every view/edit triggers an `AuditEntry`** (FR-13.2).
- [ ] **Photo consent respected (FR-13.5):** Every member photo renders through `ServeMemberAvatar`, which checks `member.photoConsent == true` before loading the pre-signed URL and falls back to initials when `false`.
- [ ] **Pre-signed media URLs:** Never cache or log raw S3 pre-signed URLs beyond their short TTL; cache downloaded media files in the managed `MediaCacheManager` directory and wipe restricted media when scope is revoked.
- [ ] **No `print` / `debugPrint`:** Use `AppLogger.d/i/w/e` only (gated on `kDebugMode`, with automatic redaction of `Authorization`, `password`, `otp`, `token`, `phone`, `email`, `medical`, `note`). `LoggingInterceptor` logs HTTP method, path (UUIDs only), and status code — **never request/response headers or bodies**.
- [ ] **TLS in transit (NFR-4):** Cleartext HTTP is disabled in release builds (`android:usesCleartextTraffic="false"`, iOS `NSAllowsArbitraryLoads = false`). Dev/staging cleartext is permitted only for local dev IPs via flavor-specific network security config.
- [ ] **Client-side RBAC is UX only (NFR-4):** Hiding a button via `PermissionChecker` never substitutes for server-side authorization, and every `403` from the server is handled gracefully (either `ERR_FORBIDDEN_SCOPE` or `ERR_FEATURE_DISABLED`).

---

## 8. Testing (≥ 70 % Coverage + Safeguarding & Sync Suites)

- Every new `UseCase`, `Mapper`, `RepositoryImpl`, `Cubit`, `SyncEngine` component, and `PermissionChecker` rule must have unit tests.
- Minimum **70 % line coverage** (`lcov.info`):
  ```bash
  flutter test --coverage
  ```
  Do not commit if coverage drops.

| Layer | Location | Tools |
| --- | --- | --- |
| Unit (UseCases, Mappers, Repos, Sync, Permissions) | `test/features/<feature>/...` & `test/core/...` | `flutter_test`, `mocktail` |
| Cubit | `test/features/<feature>/presentation/...` | `bloc_test`, `mocktail` |
| Network / DataSource | `test/features/<feature>/data/...` | `mocktail` over `Dio` / `HiveStorage` |
| Widget | `test/features/<feature>/presentation/...` | `flutter_test` (`pumpWidget`, `makeTestableWidget`) |
| Golden | `test/features/<feature>/golden/` | `alchemist` / `golden_toolkit` (both LTR `en` and RTL `ar`) |
| Integration | `integration_test/` | `integration_test` (`dev` flavor) |

- **Mandatory domain test cases:**
  1. **Sync conflict resolution tests (BRD R1):** Every syncable entity must have tests covering its conflict strategy (§12.3) — e.g. concurrent offline `AttendanceRecord` marks merging per `(occurrenceId, memberId)`, append-only `FollowUp`/`PastoralNote` preservation, LWW `CONFLICT` surfacing server copy, and tombstone/scope-revocation eviction from `HiveStorage`.
  2. **Safeguarding & permission tests (§24):** Every screen/Cubit touching minor records or Sensitive fields must test: (a) authorized in-scope view, (b) out-of-scope / missing-permission block, (c) `photoConsent == false` hiding photo URL, and (d) `AuditEntry` queued on Sensitive view/write.
  3. **Offline grace window tests (FR-1.3):** Verify that network failure on token refresh keeps the user signed in while within `offlineGraceDays`, transitions to read-only `OfflineGraceExpired` when expired offline, and never wipes the outbox.
- Mirror `lib/` paths 1-for-1 in `test/`: `lib/features/attendance/domain/use_case/record_attendance_use_case.dart` → `test/features/attendance/domain/use_case/record_attendance_use_case_test.dart`.
- Naming: `test('<action>_<condition>_<expectation>', ...)` and `blocTest('<action>_<expectation>', ...)`.
- Build mocks per test in `setUp`; register fallback values in `test/test_setup.dart`. Never use `Future.delayed` in tests — use `pump`, `pumpAndSettle`, or `FakeAsync`. Never use real member PII in test builders (`test/utils/builders/`).

---

## 9. Clean Architecture (`BaseCubit` + Sealed Actions)

### 9.1 Size, Complexity & Decomposition Limits (Non-Negotiable)

- **File size limit:** **≤ 250–300 lines of code** (target ≤ 250 lines; **300 lines is a hard ceiling** for every hand-written `.dart` file in `lib/` and `test/`).
- **Function / method size limit:** **≤ 20–25 lines of code** (target ≤ 20 lines; **25 lines is a hard ceiling** for every function, method, constructor body, and widget `build()` method).
- **Mandatory decomposition when any limit is reached:**
  - **Oversized Widget / `build()` (> 20–25 lines) or Page file (> 250–300 lines):** Never use `_buildX()` helper methods that return a `Widget`. Instead, extract dedicated `StatelessWidget` / `StatefulWidget` classes into separate files under `lib/features/<feature>/presentation/<screen>/widgets/<sub_widget>.dart` (or `lib/core/common_ui/` if reusable across features). Keep `<screen>_page.dart` as a thin shell (`BlocProvider.value` + navigation listener + top-level scaffold delegating to child widget files).
  - **Oversized Function / Method (> 20–25 lines):** Split into smaller, single-responsibility private helper methods (`_validateInput`, `_buildOutboxMutation`, `_mergeAttendanceRow`, etc.). Pure business/mapping helpers extracted from a Cubit, UseCase, or Repository get their own unit tests.
  - **Oversized Class / File (> 250–300 lines):**
    - **State / Actions / Navigation:** Split `<screen>_states.dart` into `<screen>_states.dart`, `<screen>_actions.dart`, and `<screen>_navigation.dart` (or extract sub-state classes into their own files).
    - **Cubit:** Move multi-step orchestration or domain calculations into dedicated `UseCase`s (`lib/features/<feature>/domain/use_case/`) so each Cubit handler stays ≤ 20–25 lines.
    - **Repository / Mapper / Service:** Split large mappers or repositories by sub-aggregate (e.g. `MemberProfileMapper` + `FamilyLinkMapper`) or delegate complex sync/conflict logic to a dedicated helper class.

### 9.2 `BaseCubit<T, A, NE>`
Use `Cubit` (never `Bloc`) for every screen and shared controller. User intents enter via `doAction(A action)` switching exhaustively on a Dart 3 `sealed class`; one-shot UI effects (navigation, toasts, bottom sheets, dialogs) emit through `Stream<NE> navigation`.

```dart
abstract class BaseCubit<T, A, NE> extends Cubit<T> {
  BaseCubit(super.initialState);

  Future<void> doAction(A action);

  final StreamController<NE> _navigationStream = StreamController<NE>.broadcast();
  Stream<NE> get navigation => _navigationStream.stream;

  void emitNavigation(NE effect) {
    if (!_navigationStream.isClosed) {
      _navigationStream.add(effect);
    }
  }

  @override
  Future<void> close() {
    _navigationStream.close();
    return super.close();
  }
}
```

- Every screen Cubit extends `BaseCubit<<Screen>States, <Screen>Action, <Screen>NavigationAction>`. No `Bloc`, no `on<Event>`, no event transformers.
- Mutate state only via `emit(state.copyWith(...))` (never mutate collections in place).
- One-shot side effects flow **only** through `emitNavigation(...)` — never put `errorMessage` or `shouldNavigate: true` flags in `State` with a "clear/consume" action.
- Cubits never hold a `BuildContext`, never import `flutter/material.dart` (except `immutable` from `meta` if needed), and never touch `AppRouter` or `Toaster` directly.

### 9.3 Page (View) Wiring

Every screen `Page` is a `StatefulWidget` that resolves its Cubit from `getIt()`, listens to `cubit.navigation` in `initState`, cancels the subscription in `dispose`, wraps its subtree in `BlocProvider.value(value: cubit, ...)`, and dispatches user intents strictly via `cubit.doAction(...)`:

```dart
class _AttendanceSheetPageState extends State<AttendanceSheetPage> {
  late final AttendanceSheetCubit cubit = getIt<AttendanceSheetCubit>();
  StreamSubscription<AttendanceSheetNavigationAction>? _navSub;

  @override
  void initState() {
    super.initState();
    _navSub = cubit.navigation.listen(_handleNavigation);
    cubit.doAction(LoadAttendanceSheetAction(widget.occurrenceId));
  }

  void _handleNavigation(AttendanceSheetNavigationAction effect) {
    switch (effect) {
      case NavigateToMemberDetail(:final memberId):
        context.router.push(MemberDetailRoute(memberId: memberId));
      case ShowAttendanceSavedToast():
        getIt<Toaster>().showSuccess(
          LocaleKeys.attendance_saved_offline_ready.tr(context: context),
        );
      case ShowAttendanceErrorToast(:final message):
        getIt<Toaster>().showError(message);
    }
  }

  @override
  void dispose() {
    _navSub?.cancel();
    cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<AttendanceSheetCubit>.value(
      value: cubit,
      child: const _AttendanceSheetBody(),
    );
  }
}
```

- Pages hold zero business logic.
- Use `BlocSelector` or narrow `BlocBuilder`s around specific state slices — never wrap an entire `Scaffold` in a single top-level `BlocBuilder`.

### 9.4 `State`, `Action`, and `NavigationAction` (No `freezed` / No `equatable`)

```dart
class AttendanceSheetStates {
  final Resources<EventOccurrence> occurrenceResource;
  final Resources<List<AttendanceEntryItem>> entriesResource;
  final Map<String, AttendanceStatus> pendingMarks;
  final bool isSyncing;

  const AttendanceSheetStates({
    this.occurrenceResource = const Resources.initial(),
    this.entriesResource = const Resources.initial(),
    this.pendingMarks = const {},
    this.isSyncing = false,
  });

  AttendanceSheetStates copyWith({
    Resources<EventOccurrence>? occurrenceResource,
    Resources<List<AttendanceEntryItem>>? entriesResource,
    Map<String, AttendanceStatus>? pendingMarks,
    bool? isSyncing,
  }) {
    return AttendanceSheetStates(
      occurrenceResource: occurrenceResource ?? this.occurrenceResource,
      entriesResource: entriesResource ?? this.entriesResource,
      pendingMarks: pendingMarks ?? this.pendingMarks,
      isSyncing: isSyncing ?? this.isSyncing,
    );
  }
}

sealed class AttendanceSheetAction {}
class LoadAttendanceSheetAction extends AttendanceSheetAction {
  final String occurrenceId;
  LoadAttendanceSheetAction(this.occurrenceId);
}
class MarkMemberAttendanceAction extends AttendanceSheetAction {
  final String memberId;
  final AttendanceStatus status;
  MarkMemberAttendanceAction({required this.memberId, required this.status});
}

sealed class AttendanceSheetNavigationAction {}
class NavigateToMemberDetail extends AttendanceSheetNavigationAction {
  final String memberId;
  NavigateToMemberDetail(this.memberId);
}
class ShowAttendanceSavedToast extends AttendanceSheetNavigationAction {}
class ShowAttendanceErrorToast extends AttendanceSheetNavigationAction {
  final String message;
  ShowAttendanceErrorToast(this.message);
}
```

- **Forbidden packages (release blocker):** `freezed`, `freezed_annotation`, `equatable`, `dartz`, `fpdart`, or any `Either` type.
- `State` is a plain Dart class with `final` fields, a `const` constructor with sensible defaults, and a hand-written `copyWith`. If a state grows past ~12 fields, group related fields into plain immutable sub-state classes with their own `copyWith`.
- `Action` and `NavigationAction` are always Dart 3 `sealed class` hierarchies switched on exhaustively (no `default:` branch, so the compiler catches unhandled cases).

### 9.5 Cubit Template

```dart
@injectable
class LoginCubit extends BaseCubit<LoginStates, LoginAction, LoginNavigationAction> {
  final LoginUseCase _loginUseCase;

  LoginCubit(this._loginUseCase) : super(const LoginStates());

  @override
  Future<void> doAction(LoginAction action) async {
    switch (action) {
      case SubmitLoginAction():
        await _login(action);
      case NavigateToInviteRedeemAction():
        emitNavigation(NavigateToInviteRedeemScreen());
    }
  }

  Future<void> _login(SubmitLoginAction action) async {
    emit(state.copyWith(loginResource: const Resources.loading()));
    final result = await _loginUseCase(
      LoginParams(identifier: action.identifier, password: action.password),
    );
    switch (result) {
      case Success<AuthUserSession>(:final data):
        emit(state.copyWith(loginResource: Resources.success(data: data)));
        emitNavigation(NavigateToRoleHomeScreen());
      case Failure<AuthUserSession>(:final exception, :final message):
        emit(
          state.copyWith(
            loginResource: Resources.failure(exception: exception, message: message),
          ),
        );
        emitNavigation(ShowLoginErrorToast(message));
    }
  }
}
```

- Screen Cubits are `@injectable` (fresh instance per screen mount).
- `doAction` is a thin dispatcher delegating each case to a dedicated private method (`_login`, `_markAttendance`, etc.).
- Cubits never `try/catch` storage or network exceptions — repositories wrap all I/O in `_safeCall` and return `ApiResult<T>`.

### 9.6 UseCase Rules
- `class <Verb><Noun>UseCase` with a single public method `Future<ApiResult<T>> call(...)` (or `Stream<ApiResult<T>> watch(...)` for reactive local-store streams).
- Positional parameters for 1–2 inputs; a typed `<Verb><Noun>Params` class for 3+ inputs.
- May compose other injected `UseCase`s or `Repository` interfaces; never instantiates collaborators with `new`.

### 9.7 Naming Conventions

| Artefact | Convention | Example |
| --- | --- | --- |
| Shared Widget | `Serve<Name>` | `ServeButton`, `ServeTextField`, `ServeMemberAvatar` |
| Screen Page | `<Screen>Page` | `AttendanceSheetPage`, `MemberRecordPage` |
| Cubit | `<Screen>Cubit` | `AttendanceSheetCubit` |
| State / Action / Nav | `<Screen>States` / `<Screen>Action` / `<Screen>NavigationAction` | `AttendanceSheetStates` |
| Action subclass | `<Verb><Noun>Action` | `MarkMemberAttendanceAction` |
| Nav subclass | `NavigateTo<Dest>` / `Show<Noun><Effect>` | `NavigateToMemberDetail`, `ShowAttendanceSavedToast` |
| UseCase | `<Verb><Noun>UseCase` | `RecordAttendanceUseCase`, `WatchGroupScheduleUseCase` |
| Repository interface / impl | `<Feature>Repository` / `<Feature>RepositoryImpl` | `AttendanceRepository`, `AttendanceRepositoryImpl` |
| Mapper | `<Feature>Mapper` | `AttendanceMapper` |
| Remote / Local DataSource | `<Feature>RemoteDataSource` / `<Feature>LocalDataSource` | `AttendanceRemoteDataSource`, `AttendanceLocalDataSource` |
| Request / Response DTO | `<Name>Request` / `<Name>Response` | `RecordAttendanceRequest`, `MemberRecordResponse` |
| Hive Document Model | `<Name>Doc` | `ServedMemberDoc`, `AttendanceRecordDoc`, `OutboxMutationDoc` |

### 9.8 Linting & Formatting
- `analysis_options.yaml` extends `flutter_lints` + strict analyzer rules (`strict-casts: true`, `strict-inference: true`, `strict-raw-types: true`).
- Never disable: `prefer_const_constructors`, `prefer_const_literals_to_create_immutables`, `avoid_print`, `avoid_dynamic_calls`, `use_build_context_synchronously`, `require_trailing_commas`, `prefer_single_quotes`, `unnecessary_lambdas`, `unused_import`, `unused_element`, `unused_field`, `unused_local_variable`.
- Before every commit run:
  ```bash
  dart format --set-exit-if-changed .
  flutter analyze
  find lib test -name '*.dart' ! -name '*.g.dart' ! -name '*.gr.dart' ! -name '*.config.dart' ! -name '*.gen.dart' -exec awk 'END { if (NR > 300) print FILENAME ": " NR " lines (exceeds 250-300 limit)" }' {} +
  ```
  `dart format` and `flutter analyze` must exit `0` with zero warnings, and the line-count check must produce no output (target ≤ 250 lines per file, hard max 300; target ≤ 20 lines per function/method/`build()`, hard max 25). No `// ignore:` without a brief rationale comment.

---

## 10. Separation of Concerns & Module Boundaries

- **Call chain:** `Page (View)` → `Cubit.doAction(...)` → `UseCase` → `Repository` (interface in `domain/`) → `RepositoryImpl` (in `data/`) → `LocalDataSource` (`HiveStorage`) + `RemoteDataSource` (`Retrofit`/`Dio`) + `OutboxProcessor` + `Mapper`.
- **Views** never touch `UseCase`s, `Repository`s, `HiveStorage`, `SecureStorage`, or `Dio`.
- **Cubits** only call `UseCase`s (and core read-only session/permission facades like `PermissionChecker` or `AppEventBus`), never `Repository`s or data sources.
- **Mappers** convert `DTO ↔ Doc ↔ Domain Entity` with zero side effects.
- **Cross-feature boundaries:**
  - `lib/core/` and `lib/network/` **never** import from `lib/features/`.
  - `lib/features/<X>/` **never** imports from `lib/features/<Y>/data/` or `lib/features/<Y>/presentation/`. If feature `X` needs domain data owned by feature `Y` (e.g. `attendance` reading group members from `members`/`groups`), it injects `Y`'s **domain `UseCase`** via DI and documents the dependency in both feature docs (`docs/features/13-feature-*.md`).
  - `lib/di/` and `lib/routing/` wire all features together by design.

---

## 11. API Integration (`Dio` + `Retrofit` + `ApiResult<T>` + `Resources<T>`)

- **Base path & versioning (Backend §8):** All REST calls target `/api/v1/<resource>` via Retrofit abstract classes (`@RestApi()`). `@RestApi(baseUrl:)` stays empty so the runtime `Dio` instance from `DioModule` supplies `AppEnvironment.apiBaseUrl`.
- **JSON conventions (Backend §7):** The Spring Boot Kotlin backend uses **camelCase** JSON keys (`orgId`, `createdAt`, `updatedAt`, `changeSeq`, `deletedAt`, `clientRecordedAt`) and `UUID` strings for IDs. Use `@JsonSerializable()` (default camelCase — **never** `FieldRename.snake`).
- **Response envelope (Backend §8, §10):**
  - Backend never returns `204 No Content`; every endpoint returns `BaseResponseBody<T>` (`data`, `message`, `code`, `fieldErrors` on failure), and paginated endpoints return Spring `Page<T>` metadata (`content`, `page`, `size`, `totalElements`, `totalPages`).
  - Model this in `lib/network/base_api_response.dart` (`BaseApiResponse<T>` and `PagedContent<T>`).
- **Idempotency (Backend §8, §12.2):** Every create/mutation request carries a client-generated `UUID` v4 (`IdGenerator.newUuid()`) as the entity `id` or in the `Idempotency-Key` header so retries never duplicate records.
- **Safe invocation:** Every repository call wraps I/O in `_safeCall(...)` (`lib/network/safe_call.dart`), converting `DioException`, `FormatException`, `TimeoutException`, and `HiveError` into `Failure<T>(exception: Errors, message: String)`. No raw exception ever escapes `data/`.

### 11.1 `ApiResult<T>` (Domain / Data Envelope)

```dart
sealed class ApiResult<T extends Object?> {
  const ApiResult();
}

class Success<T extends Object?> extends ApiResult<T> {
  final T? data;
  const Success(this.data);
}

class Failure<T extends Object?> extends ApiResult<T> {
  final Errors? exception;
  final String message;
  const Failure({this.exception, required this.message});
}
```

### 11.2 `Resources<T>` (Presentation State Envelope)

```dart
enum Status { initial, loading, success, error }

class Resources<T> {
  final Status status;
  final T? data;
  final Errors? error;
  final String? message;

  const Resources._({required this.status, this.data, this.error, this.message});
  const Resources.initial() : this._(status: Status.initial);
  const Resources.loading({T? data}) : this._(status: Status.loading, data: data);
  const Resources.success({T? data}) : this._(status: Status.success, data: data);
  const Resources.failure({Errors? exception, String? message, T? data})
      : this._(status: Status.error, error: exception, message: message, data: data);

  bool get isInitial => status == Status.initial;
  bool get isLoading => status == Status.loading;
  bool get isSuccess => status == Status.success;
  bool get isError => status == Status.error;
}
```

- Notice that `Resources.loading({T? data})` and `Resources.failure({..., T? data})` preserve cached `data`: in an offline-first app, when cached data is already present and a background refresh is running or fails, pass `data: currentCachedData` so the UI keeps showing the cached records with a subtle sync indicator rather than wiping the screen!

---

## 12. Offline-First Storage & Sync Engine (Core Architectural Rule)

Offline-first is mandatory (`docs/00-brd.md` §11, `NFR-1`, `NFR-3`; `sev_connect_backend/CLAUDE.md` §12). Core workflows — viewing schedules, taking attendance, managing follow-ups, managing tasks, reading member records in scope, and using downloaded content packs — **must work with zero connectivity**.

### 12.1 Encrypted Local Store (`HiveStorage`)

1. **Reads come from local storage first:** Repositories read from `HiveStorage` (and/or expose a reactive stream of local changes) and trigger delta sync in the background when online. Never make an MVP operational screen depend on a live HTTP GET when cached data exists.
2. **AES-256 encryption at rest (NFR-4, FR-13.7):** Every box is opened exclusively through `HiveStorage` (`lib/core/storage/hive_storage.dart`) encrypted with `HiveAesCipher` using a 256-bit key generated once and stored in `SecureStorage`.
3. **JSON document storage (no `hive_generator`):** Store `@JsonSerializable()` `Map<String, dynamic>` documents (`*Doc`) keyed by entity `UUID`. Do **not** use `hive_generator` or numbered `@HiveType` binary adapters (they are brittle across schema evolutions).
4. **Sync metadata on every cached document:** Every syncable `*Doc` mirrors the backend's `SyncableEntity` (`sev_connect_backend/CLAUDE.md` §12.1):
   - `id` (`String` UUID, client-suppliable on create)
   - `orgId` (`String` UUID)
   - `version` (`int`, optimistic locking version from server)
   - `changeSeq` (`int`, server-assigned monotonic sequence)
   - `deletedAt` (`String?` UTC ISO-8601 tombstone)
   - `syncStatus` (`SYNCED` / `PENDING_CREATE` / `PENDING_UPDATE` / `PENDING_DELETE` / `CONFLICT`)
5. **Sensitive data separation (FR-13.3, Backend §11.2):**
   - General member profiles (`ServedMemberDoc`) live in the `served_members` box and **never** contain medical info, pastoral notes, or consent records.
   - Sensitive records fetched for authorized offline use (e.g. trip emergency info for an authorized trip lead) live in a dedicated `sensitive_records` box that is immediately purged on scope revocation, logout, or offline grace window expiry.

### 12.2 Outbox Pattern (`POST /api/v1/sync/mutations`)

1. **Atomic local write + outbox append:** Every offline-capable mutation (create/update/delete) updates the local entity box and appends an `OutboxMutationDoc` to the `outbox_mutations` box in the same repository operation:
   - `mutationId`: client-generated `UUID` v4 (idempotency key)
   - `entityType`: backend sync entity name (e.g. `ATTENDANCE_RECORD`, `FOLLOW_UP`, `TASK`, `EVENT_OCCURRENCE`)
   - `op`: `CREATE` | `UPDATE` | `DELETE`
   - `entityId`: target entity `UUID`
   - `baseVersion`: `int?` (`version` of the entity when edited)
   - `payload`: `Map<String, dynamic>`
   - `actorId`: authenticated user's `UUID`
   - `orgId`: authenticated user's `orgId`
   - `clientRecordedAt`: UTC ISO-8601 timestamp
   - `retryCount`, `status` (`QUEUED`, `IN_FLIGHT`, `CONFLICT`, `REJECTED`), `lastErrorMessage`
2. **Draining the outbox (`OutboxProcessor`):**
   - Pushes batches (`SYNC_BATCH_SIZE`) to `POST /api/v1/sync/mutations` when connectivity is available.
   - Processes the backend's **per-item result** (`sev_connect_backend/CLAUDE.md` §12.2):
     - `APPLIED` / `DUPLICATE` / `MERGED`: update local entity with canonical server `version` and `changeSeq`, mark `SYNCED`, and remove from outbox.
     - `CONFLICT` (carries server copy): store the server copy alongside the local copy, mark the item `CONFLICT`, and surface it in the Sync Conflict Banner/Sheet so the user can review or accept the server version — never silently drop!
     - `REJECTED` (carries localized reason): mark `REJECTED` in the "Needs Attention" queue (`SyncCubit`) and notify the user via `Toaster` / sync badge.
3. **Outbox durability on logout:** Never silently wipe `outbox_mutations` on token expiry or force-logout. If a user initiates manual logout while `outbox_mutations` has pending items for their `actorId`, show a confirmation dialog warning how many offline changes have not synced yet and offering "Sync Now" before signing out.

### 12.3 Delta Pull (`GET /api/v1/sync/changes`) & Scope Revocation

1. **Cursor is server `changeSeq`:** `DeltaPuller` calls `GET /api/v1/sync/changes?since=<lastChangeSeq>&entities=<list>&limit=<n>` until `hasMore == false`, advancing `lastChangeSeq` in `Preferences` only after each page is durably written to `HiveStorage`.
2. **Tombstones (`deletedAt != null`):** When the delta feed returns a tombstone for an entity `id`, delete that document from the local box (unless it has an unresolved local conflict, which is flagged).
3. **Scope revocation (`sev_connect_backend/CLAUDE.md` §12.4, FR-13.1):** When the delta feed returns a **revocation** event (because a servant's assignment to a group ended or a member moved out of the caller's stage/group), `DeltaPuller` **immediately purges** the revoked member/group records and any associated cached media or sensitive records from local storage.

### 12.4 Per-Entity Conflict Resolution Rules (BRD §11.3, Backend §12.3)

| Data Type | Client + Server Strategy |
| --- | --- |
| **Attendance (`AttendanceRecord`)** | **Merge per `(occurrenceId, memberId)`**: Local key is `${occurrenceId}_${memberId}`. Each mark is an individual record upsert, never a full-list overwrite, so two servants marking the same session offline merge without clobbering each other. |
| **Follow-ups (`FollowUp`) & Pastoral Notes (`PastoralNote`)** | **Append-only**: Never expose an in-place edit or delete mutation on an existing entry; a correction or follow-up update appends a new entry with its own `UUID` referencing the previous entry. |
| **Tasks (`Task`)** | **Field-level merge + deterministic status transitions**: Outbox payload carries changed fields + `baseVersion`; local state reconciles with server merged result on response. |
| **Schedules (`Event`, `EventOccurrence`), Curriculum (`Lesson`), Groups (`Group`), Config** | **Server-authoritative LWW on `version`**: If the server responds `CONFLICT` (stale `baseVersion`), display a clear edit-conflict prompt showing the server's updated fields. |
| **Personal state (Bible reading progress, favourites, notification prefs, points)** | **Per-user LWW**: Keyed by user + item, reconciled automatically. |

### 12.5 Data Classification for Offline Caching (BRD §11.4)

- **Must be pre-fetched & always offline:** My groups' schedules, my in-scope `ServedMember` records, my assigned `Group`s, taken/recent `AttendanceRecord`s, `FollowUp`s, my `Task`s, and selected `ContentPack`s (Bible reading plan, daily verse pool, hymn texts).
- **Opportunistically cached:** Wider servant directory, other stages' schedules (when in scope), downloaded hymn audio / lesson PDFs (Wi-Fi-gated by default with LRU size cap via `MediaCacheManager`, NFR-12).
- **Online-only (fail clearly when offline, never queue in outbox):** Full audit log viewer (`audit.read`), analytics/reporting exports, admin user/role provisioning, annual stage promotion (`POST /api/v1/groups/{id}/promotion`), and DSR export/deletion workflows.

---

## 13. Loading States — Shimmer Skeletons

- All list, grid, and detail initial loading states use **shimmer skeletons** — never a centered `CircularProgressIndicator` or blank screen.
- Remember offline-first (§11.2, §12.1): show shimmer **only** when local cache has no data yet (`state.resource.isLoading && state.resource.data == null`). When cached data is already displayed and a background sync/refresh is running, keep rendering the list and show a non-blocking top indicator (`ServeSyncProgressBar` or pull-to-refresh header).
- Circular progress indicators are allowed only inside an action button (`ServeButton(isLoading: true)`) or a modal blocking action (e.g. running annual promotion online).
- Shared shimmer primitives live in `lib/core/common_ui/shimmer/` (`ServeListShimmer`, `ServeCardShimmer`, `ServeRowShimmer`). Feature-specific shimmers live in `lib/features/<feature>/presentation/widgets/<screen>_shimmer.dart`.
- When an initial load fails with no cached data (`state.resource.isError && state.resource.data == null`), render `DefaultErrorView(error: state.resource.error, onRetry: ...)` from `lib/core/common_ui/defaults/`.

---

## 14. Optimistic UI & Offline Feedback

- **Offline-capable mutations** (marking attendance, logging a follow-up, creating/moving a task, toggling Bible reading progress, saving a draft lesson) update local `HiveStorage` and the Cubit's `State` **immediately**, then enqueue an `OutboxMutationDoc` (§12.2):
  1. Write updated document + outbox entry to `HiveStorage`.
  2. Emit updated `State` immediately (with `syncStatus: SyncStatus.pending` badge on the row/card).
  3. Trigger `SyncEngine.nudge()` in the background (non-blocking).
- **Online-only critical mutations** (admin role changes, stage promotion, invitation creation, consent revocation) **do not** use optimistic UI: set `ServeButton(isLoading: true)`, await the server response, and update state on `Success` or show an error toast on `Failure`.
- Per-item mutation status in lists uses `Map<String, Resources<void>>` in `State` (always copying the map in `copyWith`).

---

## 15. Token Management, Auth Interceptors & Offline Session Grace Window (FR-1.3)

ServeConnect's authentication lifecycle must never lock a servant out mid-meeting when internet drops (`docs/00-brd.md` FR-1.3; `sev_connect_backend/CLAUDE.md` §11.1).

1. **Interceptors on shared `Dio` (`lib/network/dio_module.dart`):**
   - `AcceptLanguageInterceptor`: attaches `Accept-Language: <ar|en>` to every request.
   - `AuthInterceptor`: attaches `Authorization: Bearer <accessToken>` from `SecureStorage`, skipping public paths (`/api/v1/auth/login`, `/api/v1/auth/otp/verify`, `/api/v1/auth/otp/resend`, `/api/v1/auth/refresh`, `/api/v1/auth/invitations/accept`).
   - `RefreshInterceptor`: triggers **only on HTTP `401`** (never on `403` — `403` means insufficient permission/scope or disabled feature flag). Excluded from retry: `/api/v1/auth/login`, `/api/v1/auth/refresh`, `/api/v1/auth/logout`.
2. **Serialised single-use refresh rotation:**
   - A `Mutex` (`synchronized`) serialises concurrent `401` refreshes: re-read `accessToken` from `SecureStorage` (if already rotated by an earlier call, retry the request immediately); otherwise call `POST /api/v1/auth/refresh` on a **separate `Dio` instance** without `RefreshInterceptor`.
   - On `200`, persist the new `(accessToken, refreshToken)` pair, update `lastServerAuthAt = DateTime.now().toUtc()` in `SecureStorage`, and retry the original request.
3. **Offline Session Grace Window (FR-1.3 — Critical Rule):**
   - If token refresh fails because of a **network/timeout/5xx error** (`NetworkError`, `TimeoutError`, or `ServerError` ≥ 500), **DO NOT emit `LoginRequired(forceLogout: true)`**!
   - Instead, `AuthSession` checks `DateTime.now().toUtc().difference(lastServerAuthAt) <= Duration(days: offlineGraceDays)` (configured by `OFFLINE_GRACE_DAYS`, default 14–30 days):
     - **Within grace window:** keep `AuthSession` in `AuthenticatedOffline` state; the user accesses all cached role screens and queues offline mutations normally.
     - **Past grace window while offline:** transition `AuthSession` to `OfflineGraceExpired`; allow read-only access to cached non-sensitive content (schedules, ContentPacks), block sensitive reads (`ServedMember` full records, `PastoralNote`s) and new mutations, and display a banner prompting re-authentication when back online.
   - **Only when the server explicitly responds `401` to `/api/v1/auth/refresh`** (token expired on server, revoked, or token-reuse detected) does `RefreshInterceptor` emit `LoginRequired(forceLogout: true)` on `AuthEventBus`, clearing user credentials/scopes in `AuthSession` and redirecting to `LoginRoute` (while preserving unsynced `outbox_mutations` on device, §12.2).

---

## 16. Error Handling, Notifications & Logging

### 16.1 Sealed `Errors` Hierarchy (`lib/network/errors.dart`)

Every error in the app is represented as a subclass of `Errors` — never raw `Exception`, `DioException`, or `Object`:

```dart
sealed class Errors {
  final String? message;
  const Errors({this.message});
}

class NetworkError extends Errors {
  const NetworkError({super.message});
}

class TimeoutError extends Errors {
  const TimeoutError({super.message});
}

class ParseError extends Errors {
  final Object? cause;
  const ParseError({super.message, this.cause});
}

class ServerError extends Errors {
  final int statusCode;
  final String? code;
  final Map<String, String> fieldErrors;
  const ServerError({
    required this.statusCode,
    this.code,
    this.fieldErrors = const {},
    super.message,
  });
}

class ForbiddenScopeError extends Errors {
  const ForbiddenScopeError({super.message});
}

class FeatureDisabledError extends Errors {
  final String? featureKey;
  const FeatureDisabledError({this.featureKey, super.message});
}

class SyncConflictError extends Errors {
  final Map<String, dynamic>? serverCopy;
  const SyncConflictError({this.serverCopy, super.message});
}

class LoginRequired extends Errors {
  final bool forceLogout;
  const LoginRequired({this.forceLogout = false, super.message});
}

class StorageError extends Errors {
  final Object? cause;
  const StorageError({super.message, this.cause});
}

class PlatformError extends Errors {
  final String? code;
  const PlatformError({this.code, super.message});
}

class JustMessage extends Errors {
  const JustMessage(String message) : super(message: message);
}

class Unknown extends Errors {
  final Object? cause;
  const Unknown({super.message, this.cause});
}
```

- `ErrorParser.parse` maps backend `BaseResponseBody.Fail` (`400` with `fieldErrors`, `401` → `LoginRequired`, `403` → `ForbiddenScopeError` or `FeatureDisabledError`, `404`, `409` → `SyncConflictError` or `ServerError`, `429`, `500`) using the server's already-localised `message` when present, falling back to `LocaleKeys.errors_*`.
- User feedback goes exclusively through `Toaster` (`getIt<Toaster>().showSuccess/showError/showWarning`) or `BottomSheetHost` (`getIt<BottomSheetHost>().show(...)`). Never call `ScaffoldMessenger.of(context)` or `showModalBottomSheet` directly from feature pages.

### 16.2 Push & On-Device Local Notifications (FR-12.1–12.3, Backend §17)

1. **Push notifications (`firebase_messaging`):**
   - Server push payloads contain only opaque entity IDs (`occurrenceId`, `taskId`, `announcementId`) and a generic localized alert — **never a minor's name, note text, or medical info** (they appear on lock screens).
   - Tapping a push notification routes through validated `DeepLinkRoutes` after checking `AuthGuard` and `ScopeGuard`.
2. **On-device scheduled local notifications (`LocalNotificationScheduler`, FR-12.2):**
   - Whenever `schedule` or `tasks` sync (or are edited offline), `LocalNotificationScheduler` computes upcoming meeting/task reminders from cached local occurrences and schedules them via `flutter_local_notifications` respecting the user's cached quiet hours and category preferences (FR-12.3).
   - Local notification text must also be **PII-free** on the lock screen (e.g. *"Upcoming meeting for Grade 6 in 30 minutes"* or *"You have 2 pending follow-up tasks"* — never *"Call [Minor's Full Name] at [Phone]"*).
   - When an occurrence time changes on sync, cancel or reschedule its local notification deterministically (keyed by deterministic hash of `occurrenceId`).

### 16.3 Logging (`AppLogger`)
- Log only through `AppLogger.d/i/w/e` (`lib/core/logger/app_logger.dart`), which is a no-op in release builds and scrubs sensitive keys.
- Never log a `Person`, `ServedMember`, `PastoralNote`, `ConsentForm`, DTO `.toString()`, or request/response JSON body. Log only opaque UUIDs (`memberId`, `occurrenceId`, `mutationId`) and counts.

---

## 17. Permission-Gated, Scope-Aware UI & Safeguarding (BRD §6, FR-13.x)

Unlike simple single-role apps, ServeConnect is a **single role-based, multi-role application** (`docs/00-brd.md` §6) backed by **permission-based, scope-aware authorization** (`sev_connect_backend/CLAUDE.md` §11).

### 17.1 Permission & Scope Rules (Never Branch on Role Names)

1. **Roles are data, permissions are code:** A signed-in user holds one or more `RoleAssignment`s, each granting a set of **permission keys** (`<feature>.<action>[.<qualifier>]`, e.g. `attendance.record`, `members.read.full`, `members.notes.read`, `groups.assign-servants`, `lessons.approve`, `audit.read`) within a **scope** (`ORG`, `STAGE`, `GROUP`, `SELF`, `CHILDREN`).
2. **Never write `if (user.role == 'SERVANT')` or `if (user.isLeader)`:** Always query `PermissionChecker` (`lib/core/permissions/permission_checker.dart`):
   - Coarse check (for navigation tabs/drawers): `permissionChecker.hasAnyScope('attendance.record')`
   - Scoped check (for a specific group, stage, or member): `permissionChecker.hasPermission('members.notes.read', scopeType: ScopeType.group, targetId: member.groupId)`
3. **Multi-role navigation shell (FR-1.2):** A user who is both a **Servant** (for Grade 6) and a **Parent** (of two children) sees a unified navigation shell with sections/tabs enabled by the union of their granted permissions + a quick Scope/Context switcher where relevant (e.g. *"My Service Groups"* vs *"My Children"*).
4. **Feature flags (FR-16.5):** Every module is also gated by `FeatureFlagService.isEnabled(FeatureModule.<name>)` from the cached `OrgConfig`. Both route guards (`ScopeGuard`) and navigation menus hide disabled modules automatically.

### 17.2 Safeguarding & Audit Rules on the Client (FR-13.1–13.5)

1. **Audited Sensitive reads (FR-13.2):** Opening a screen or sheet that displays a **Sensitive** record (`PastoralNote`, medical/emergency info on a `ServedMember` or `ConsentForm`) must dispatch a `RecordSensitiveAccessUseCase` call (which sends or queues an `AuditEntry` with `action: VIEW`, `targetType`, `targetId`, `scopeUsed`, `occurredAt`).
2. **Data minimization in lists (FR-13.3):** Directory and attendance list items use `MemberSummaryEntity` (id, display name, photo + `photoConsent`, group badge) — never load Sensitive fields into list states.
3. **Immediate scope revocation (§12.3):** If a user is viewing a member/group screen when `AppEventBus` fires a `ScopeRevokedEvent` for that target, the screen Cubit immediately emits a navigation action popping back to the home screen with a toast (`LocaleKeys.errors_scope_revoked`).

---

## 18. Form State (Cubit + Centralised Validators)

Pick one pattern per screen and stay consistent:

- **Pattern A — `Form` + `TextFormField` + `validator` (short forms: login, OTP, quick task create):** `GlobalKey<FormState>` and `TextEditingController`s owned by the `StatefulWidget` View (disposed in `dispose()`); `validator: Validation.validateEmail` etc.; on submit `if (formKey.currentState!.validate()) cubit.doAction(...)`.
- **Pattern B — Cubit-controlled state (complex/cross-field forms: recurring event editor, member profile with family links, trip consent form):** `State` holds field values + `<field>Error: String?` + `bool get isValid`; View dispatches `<Field>ChangedAction(value)`; Cubit validates and emits updated state.

Shared rules:
- Centralise all validators in `lib/core/utils/validation.dart` (`Validation.validateEmail`, `Validation.validatePhone`, `Validation.validatePassword`, `Validation.validateRequiredText`, `Validation.validateOtp`, …), returning localised `String?`. Never scatter regexes across widgets.
- Buttons bind `isLoading: state.submitResource.isLoading` and `isEnabled: !state.submitResource.isLoading`.
- Do **not** add `reactive_forms` or `formz`.

---

## 19. Performance, Media Caching & Recomposition

- **Lazy DI (`get_it` + `injectable`):**
  - `@injectable`: screen Cubits and UseCases (new instance on demand).
  - `@lazySingleton`: Repositories, DataSources, Mappers, `SyncEngine`, `PermissionChecker`, `Toaster`, `BottomSheetHost`, `AppEventBus`, `AuthSession`, `LocaleCubit`.
  - `@singleton`: boot-time essentials (`AppEnvironment`, `AppLogger`, `HiveStorage`).
  - Never edit `injection.config.dart` by hand.
- **Large lists:** Lists with > 20 items (member directories, attendance rosters, hymn libraries, task boards) must use `ListView.builder` / `SliverList.builder` with a stable `ValueKey(item.id)` — never index keys or `.map(...).toList()` inside a `Column`.
- **Recomposition discipline:** Use `BlocSelector<C, S, Slice>` so marking one member's attendance only rebuilds that member's row, not the entire 40-member roster! Use `const` constructors everywhere possible.
- **Media caching & Wi-Fi gating (`MediaCacheManager`, NFR-12, NFR-13):**
  - Hymn audio, lesson PDFs, and attachment downloads check `ConnectivityService` and respect the user's *"Download media on Wi-Fi only"* preference (default `true`) and size cap (`MEDIA_CACHE_MAX_MB`) with LRU eviction.
  - Member avatars use `ServeMemberAvatar` (which wraps `cached_network_image` only when `photoConsent == true` and keys cache entries by `memberId + photoChecksum`, not the expiring pre-signed query string).

---

## 20. State Management Boundaries

| State Type | Lives In |
| --- | --- |
| Ephemeral widget state (scroll offset, expansion panel, text controller cursor, local tab index) | `StatefulWidget` field |
| Single-screen data & async operations | Screen `@injectable` Cubit (`BaseCubit`) with `Resources<T>` |
| Cross-feature sync state (pending outbox count, last synced time, active conflicts, online/offline status) | `@lazySingleton SyncCubit` in `lib/features/sync/` |
| Authenticated session, active roles/permissions/scopes, offline grace state | `@lazySingleton AuthSession` (`SecureStorage`-backed) |
| Organisation config, custom role labels, active feature flags | `@lazySingleton OrgConfigCubit` (`HiveStorage`-backed) |
| Active language (`ar` / `en`) | `@lazySingleton LocaleCubit` (`Preferences`-backed) |
| Cross-feature one-shot signals (scope revoked, sync batch completed, language changed, push received) | `@lazySingleton AppEventBus` (`StreamController.broadcast`) |
| Cross-screen route arguments | Typed `auto_route` route parameters (primitive IDs / small immutable args) |

- Never pass full mutable entities or Cubit instances through route arguments when an entity `UUID` read from `HiveStorage` suffices.

---

## 21. Accessibility (NFR-7)

- Target **WCAG 2.1 AA**: contrast ≥ 4.5:1 for normal text and ≥ 3:1 for large text/UI components, defined solely through `AppColors` (`lib/core/theme/app_colors.dart`). Never hard-code `Color(0xFF...)` in feature widgets.
- **Touch targets:** Every interactive control (buttons, attendance status toggles `Present`/`Absent`/`Excused`, icon buttons, checkboxes) must have a minimum hit target of **48 × 48 dp** (`ServeButton` and `ServeIconButton` enforce this).
- **Screen readers:** Every `IconButton`, status badge, and custom control must provide a localised `tooltip` or `Semantics(label: ...)`.
- **Scalable text:** Never hard-code `fontSize` in feature widgets; always use `Theme.of(context).textTheme.*` from `AppTypography` and honour `MediaQuery.textScalerOf(context)`.

---

## 22. Dead Code, Module Boundaries & Sanctioned Package Stack

- Remove unused imports, private helpers, and dead files immediately — never comment them out.
- **Sanctioned package stack** (additions require explicit user approval in the task plan):
  - **Architecture & State:** `flutter_bloc` (Cubit only), `get_it`, `injectable`, `auto_route`
  - **Networking & Serialization:** `dio`, `retrofit`, `json_annotation`
  - **Offline Storage & Security:** `hive_ce` (or `hive` with `HiveAesCipher`), `flutter_secure_storage`, `shared_preferences`, `path_provider`, `crypto`
  - **Sync, Connectivity & Time:** `connectivity_plus`, `synchronized`, `uuid`, `intl`, `timezone`
  - **Localisation & UI:** `easy_localization`, `cached_network_image`, `flutter_svg`, `shimmer`, `cherry_toast` (wrapped behind `Toaster`)
  - **Notifications:** `firebase_core`, `firebase_messaging`, `flutter_local_notifications`
  - **Codegen & Dev / Test:** `build_runner`, `injectable_generator`, `auto_route_generator`, `retrofit_generator`, `json_serializable`, `flutter_gen_runner`, `flutter_flavorizr`, `flutter_test`, `bloc_test`, `mocktail`, `very_good_analysis`
- **Forbidden packages (release blocker):** `freezed`, `freezed_annotation`, `equatable`, `dartz`, `fpdart`, `bloc_concurrency`, `reactive_forms`, `hive_generator` (store encrypted JSON maps instead), `dio_cache_interceptor` (use `HiveStorage` + sync engine instead).

---

## 23. Check Before Building & Recommended Build Order

### 23.1 Check before building
1. Read `docs/00-brd.md` for the module and `FR-x.y` being implemented.
2. Read `docs/01-project-overview.md` for the monorepo architecture baseline.
3. Read `docs/03-api-reference.md` and `docs/06-sync.md` for the REST endpoints, sync entity payloads, and conflict rules.
4. Read `docs/04-security.md` for the required permission keys, scopes, and PII/Sensitive rules.
5. Read `docs/08-mobile-theme-and-ui-components.md` for existing `Serve*` components and theme tokens.
6. Read the feature doc (`docs/features/13-feature-<name>.md`) if touching an existing feature.
7. Grep `lib/` for existing `UseCase`s, `Repository`s, `Mapper`s, `Cubit`s, and widgets; extend/reuse before creating new ones.

### 23.2 Recommended build order (aligned with Backend §21.2; each step is its own approved plan)

0. **Foundation (M0)** — `pubspec.yaml` sanctioned dependencies, `analysis_options.yaml`, flavors (`dev`/`staging`/`prod` + `.env.example`), `lib/core/` (`AppEnvironment`, `AppLogger`, `BaseCubit`, `SecureStorage`, `Preferences`, `HiveStorage` with AES-256, `AppTheme`/`AppColors`/`AppTypography`, initial `Serve*` component catalogue, `Toaster`, `BottomSheetHost`, `AppEventBus`, `Validation`, `AppFormatters`), `lib/network/` (`DioModule`, `ApiResult`, `Resources`, `Errors`, `_safeCall`, auth/refresh/language interceptors), `lib/di/`, `lib/routing/`, `assets/translations/{en,ar}.json`, and initial mobile docs (`docs/07`–`docs/10`).
1. **`identity` + `admin` basics (M1)** — Login (phone/email + password, OTP), invitation acceptance, `AuthSession` with offline session grace window (FR-1.1–1.4), `PermissionChecker` & scope model, `OrgConfigCubit` (org profile, stages, feature flags, custom role labels — FR-16.1–16.2), and multi-role adaptive app shell.
2. **`sync` engine foundation (M2)** — `OutboxMutationDoc`, `OutboxProcessor` (`POST /api/v1/sync/mutations`), `DeltaPuller` (`GET /api/v1/sync/changes`), tombstone & scope-revocation purging, `SyncCubit`, and `ServeSyncBanner` / Conflict Resolution sheet (BRD §11). Built early so every domain module is offline-first from day one.
3. **`members` + `safeguarding` / `audit` basics (M3)** — `ServedMember` & `Servant` directory, family links, portable history (FR-2.1–2.4), `ServeMemberAvatar` with `photoConsent` gate, scope-checked local queries, and client audit entry queueing (FR-13.1–13.3).
4. **`groups` (M4)** — Stages, groups, servant assignments, member rosters, and online annual promotion flow (FR-3.1–3.4).
5. **`schedule` → `attendance` → `tasks` core loop (M5)** — Recurring events & personalised schedule (FR-4.1–4.4), offline attendance sheet with per-`(occurrenceId, memberId)` merge, absentee follow-up queue & append-only outcome logging (FR-5.1–5.4), and servant Kanban/list tasks (FR-6.1–6.3).
6. **`notifications`, `communication` & `content` MVP (M6)** — Push + on-device local meeting/task reminders with quiet hours (FR-12.1–12.3), announcements (FR-7.1), and offline `ContentPack` reader for Bible reading plans, daily verse, and hymn texts (FR-9.1–9.3).
7. **Phase 2 modules (M7+)** — Built only on explicit user request (`curriculum`, `engagement` memorization/points, `trips` + parent consent e-signature, `PastoralNote`s, `analytics`, `prayer` board).

---

## 24. Definition of Done for Safeguarding-Relevant Work

Any mobile task touching a minor's record (`ServedMember`), a Sensitive field (`PastoralNote`, medical/emergency info, `ConsentForm`), a permission/scope check, or sync caching of member data is done **only** when:

- [ ] Every screen/action is gated by `PermissionChecker` + `ScopeGuard` (matching `docs/04-security.md`) and tested for both in-scope and out-of-scope states.
- [ ] Every view or write of a Sensitive record dispatches an `AuditEntry` (and a unit/cubit test asserts it).
- [ ] Member photos render exclusively through `ServeMemberAvatar` and respect `photoConsent == false` (tested).
- [ ] Sensitive records are isolated from general `served_members` cache and purged on scope revocation, logout, or offline grace expiry (tested).
- [ ] Zero PII appears in `AppLogger` calls, route URLs, analytics events, or lock-screen local notifications.

---

## 25. Post-Task Documentation Updates

**Every task ends with a documentation update** in the monorepo-root `docs/` folder. "Code compiles and tests pass" is not "done".

### 25.1 Shared & Mobile Documentation Map (`../docs/`)

| Document | Scope & When to Update |
| --- | --- |
| `docs/00-brd.md` | Business Requirements Document (read-only unless user explicitly changes requirements) |
| `docs/01-project-overview.md` | Monorepo overview, module status matrix (MVP/P2/P3), `.env.example` keys, build flavors |
| `docs/02-database-schema.md` | Backend PostgreSQL schema (backend tasks) |
| `docs/03-api-reference.md` | REST endpoints consumed/added, request/response shapes, required permission + scope + feature flag |
| `docs/04-security.md` | Permission keys, default roles, scope rules, PII/Sensitive handling, client/server audited actions |
| `docs/05-localization.md` | Supported locales (`ar`, `en`), translation key namespaces, configurable org labels, RTL rules |
| `docs/06-sync.md` | Syncable entities, Hive box names, outbox payload shapes, per-entity conflict strategies, scope revocation |
| `docs/07-mobile-architecture.md` | Mobile Clean Architecture (`BaseCubit`, `ApiResult`, `Resources`, `Errors`, `HiveStorage`, offline grace window) |
| `docs/08-mobile-theme-and-ui-components.md` | Theme tokens (`AppColors`, `AppTypography`, `ServeBreakpoints`) and the `Serve*` Shared UI Component Catalogue |
| `docs/09-mobile-routing-and-di.md` | `AppRouter` routes, deep links, `AuthGuard`/`ScopeGuard`, DI modules and scopes |
| `docs/10-mobile-platform-native.md` | Android/iOS flavors, permissions, push/local notifications, `ServePlatform` channels |
| `docs/features/13-feature-<name>.md` | Per-feature mobile doc: screens, Cubits, states/actions/nav effects, UseCases, local/remote data sources, permissions, and cross-feature dependencies |
| `docs/walkthroughs/YYYY-MM-DD_mobile_<slug>.md` | Per-task walkthrough (§3) + one-line index entry in `docs/walkthroughs/README.md` |

Verify before committing (from the monorepo root):

```bash
grep -rn "<renamed-symbol-or-obsolete-term>" docs/   # no stale references
git status -- docs/                                   # expect changes matching the task
git diff -- docs/
```

If `git status -- docs/` shows no changes after a code change, stop and ask whether a docs update was really not needed (default: it was).

---

## 26. Code Generation Hygiene (`build_runner`)

Generated files are **committed** to git so fresh checkouts compile immediately and PR diffs show exact generated changes.

| Source Annotation / Input | Generated Output | Purpose |
| --- | --- | --- |
| `@JsonSerializable()` | `*.g.dart` | DTO & Hive `*Doc` `fromJson`/`toJson` |
| `@RestApi()` | `*.g.dart` | Retrofit API clients |
| `@injectable` / `@module` | `lib/di/injection.config.dart` | `get_it` dependency graph |
| `@AutoRouterConfig()` | `lib/routing/app_router.gr.dart` | Typed routes |
| `assets/translations/{en,ar}.json` | `lib/generated/locale_keys.g.dart` | Typed translation keys |
| `pubspec.yaml` assets (`flutter_gen`) | `lib/generated/assets.gen.dart` | Typed asset accessors |

Rules:
- Never hand-edit a generated file.
- After changing any `@JsonSerializable`, `@RestApi`, `@injectable`, or `@AutoRouterConfig` file, run:
  ```bash
  dart run build_runner build --delete-conflicting-outputs
  ```
  (or `dart run build_runner build` on `build_runner` ≥ 2.15) and commit the regenerated files in the same commit.
- After changing `assets/translations/en.json` or `ar.json`, run the `easy_localization:generate` command (§5) and commit `locale_keys.g.dart` in the same commit.

---

## 27. Build Flavors (`dev` / `staging` / `prod`)

Three flavors — **`dev`**, **`staging`**, **`prod`** — each with its own app ID, display name, `.env.<flavor>`, and Firebase project:

```
android/app/src/{dev,staging,prod,main}/   ("ServeConnect Dev", "ServeConnect Staging", "ServeConnect")
ios/Runner/Firebase/{Dev,Staging,Prod}/GoogleService-Info.plist
ios/Flutter/{Dev,Staging,Prod}.xcconfig
lib/{main.dart, main_dev.dart, main_staging.dart, main_prod.dart}
```

- Single source of truth: `flavorizr.yaml` (regenerate via `dart run flutter_flavorizr -f`).
- Application / Bundle IDs:
  - Android: `com.john.serv_connect_mobile.dev`, `com.john.serv_connect_mobile.staging`, `com.john.serv_connect_mobile`
  - iOS: `com.john.servConnectMobile.dev`, `com.john.servConnectMobile.staging`, `com.john.servConnectMobile`
- Each `main_<flavor>.dart` calls `bootstrap(flavor: Flavor.<flavor>)` → loads `.env.<flavor>`, runs `AppEnvironment.assertConfigured()`, initializes encrypted `HiveStorage`, rehydrates `AuthSession` from `SecureStorage`, configures `get_it` dependencies, schedules local notifications, and calls `runApp(const ServeConnectApp())`.
- Run commands:
  ```bash
  flutter run --flavor dev -t lib/main_dev.dart
  flutter run --flavor staging -t lib/main_staging.dart
  flutter run --flavor prod -t lib/main_prod.dart
  ```

---

## 28. Platform Channels & Native Interop

For native capabilities not covered by sanctioned pure-Dart plugins, use a typed `MethodChannel` / `EventChannel` behind an abstract facade:

```
lib/core/platform/{serve_platform.dart, serve_platform_method_channel.dart}
android/app/src/main/kotlin/com/john/serv_connect_mobile/platform/ServeMethodChannelHandler.kt
ios/Runner/Platform/ServeMethodChannelHandler.swift
```

- Channel names are namespaced `com.john.serv_connect_mobile/<capability>` and declared as `const` strings on `ServePlatform`.
- Arguments and responses use `@JsonSerializable()` classes serialised to `Map<String, dynamic>`.
- Catch `PlatformException` inside `ServePlatformMethodChannel` and map it to `Failure(exception: PlatformError(...), message: ...)` — never let raw `PlatformException` reach a Cubit.
- Inject a mock `ServePlatform` in unit/widget tests.

---

## Quick Reference — Mandatory Actions Per Task

All task types require **Plan & Approval**, **FR-x.y IDs cited**, a **Commit**, a **Walkthrough** (`docs/walkthroughs/YYYY-MM-DD_mobile_<slug>.md`), and a **Docs Update** in `../docs/`. The table below covers conditional requirements:

| Task Type | Theme + a11y + RTL | API / Sync Contract | Catalogue (`docs/08`) | Shimmer / Offline UX | Permission / Scope / Safeguarding (§24) | Codegen | Tests (≥ 70 %) |
| --- | --- | --- | --- | --- | --- | --- | --- |
| New feature / screen | ✅ | ✅ (`docs/03` + `06`) | ✅ If new shared widget | ✅ Cache-first + shimmer | ✅ `PermissionChecker` + `ScopeGuard` | DI + routes | ✅ Cubit + Widget + Scope |
| New shared `Serve*` widget | ✅ | — | ✅ Add row | If data-loading | If rendering member data/avatar | — | ✅ Widget + RTL golden |
| Modified shared widget | ✅ | — | ✅ Update row | If affected | If rendering member data/avatar | — | ✅ Regression |
| New UseCase / Mapper / Repo | — | ✅ If new endpoint/box | — | ✅ Cache + outbox | ✅ Scope & PII check | `injectable` + JSON | ✅ Unit + Sync conflict |
| Offline sync / outbox change | — | ✅ `docs/06-sync.md` | — | ✅ `ServeSyncBanner` | ✅ Scope revocation & Sensitive purge | JSON | ✅ Conflict + Revocation + Retry |
| Sensitive / Minor data screen | ✅ | ✅ Separate endpoint | — | ✅ Never in list cache | ✅ Full §24 checklist + `AuditEntry` | If DTO/DI | ✅ Audit + Consent + 403 |
| New form | ✅ | ✅ Validation alignment | ✅ If new input widget | ✅ Optimistic or loading | ✅ Scope check | — | ✅ Validation + Cubit |
| New translation key | ✅ RTL check | — | — | — | — | `easy_localization` | — |
| New route / deep link | — | — | — | — | ✅ `AuthGuard` + `ScopeGuard` | `auto_route` | ✅ Guard test |
| Bug fix | If UI | If API/sync | If changed | If affected | If safeguarding-related | If annotations changed | ✅ Regression test |
| Refactor | If UI | — | If changed | — | Preserve all guards | If annotations changed | ✅ Coverage ≥ 70 % |
| Secret / flavor / env change | — | — | — | — | ✅ §4 + §7 checklist | `flavorizr` if flavor | Verify all flavors boot |
