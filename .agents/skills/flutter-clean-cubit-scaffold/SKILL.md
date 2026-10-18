---
name: flutter-clean-cubit-scaffold
description: >-
  Scaffold a new Flutter project (or lay this architecture onto an empty one)
  with the exact Clean-Architecture + Cubit structure used across these
  projects: BaseCubit with sealed Action/NavigationAction, ApiResult / Resources
  / Errors envelopes, Dio + Retrofit with auth & mutex-refresh interceptors,
  injectable + get_it DI, auto_route with an AuthGuard, easy_localization
  (en/ar), flavors (dev/staging/prod) via flutter_dotenv, secure/prefs/hive
  storage facades, a theme layer, a sample auth login feature slice, and a
  matching CLAUDE.md rulebook. Use this whenever the user wants to start,
  bootstrap, init, or "set up a new Flutter app", "create another project with
  the same structure", "spin up a Flutter project like this one", establish a
  Flutter clean-architecture / Cubit boilerplate, or add feature slices that
  follow this pattern — even if they don't name the architecture explicitly.
  Not for adding UI to an existing differently-structured app.
---

# Flutter Clean-Architecture + Cubit Scaffold

This skill stamps out a new Flutter app that matches this team's opinionated
architecture, so every project shares the same layering, result envelopes,
network layer, DI, localisation, flavors, and conventions.

## When to use it

Trigger this skill when the user wants to:

- Create / init / bootstrap a **new Flutter project** with this structure.
- "Make another app like this one" / "same structure as the biker app".
- Establish Clean-Architecture + Cubit boilerplate, or the `BaseCubit` /
  `ApiResult` / `Resources` / Retrofit + refresh-interceptor spine.
- Add a **new feature slice** that follows the pattern (see
  `references/add-a-feature.md`).

Do **not** use it to bolt this architecture onto an existing app that already
has a different structure — that's a migration, not a scaffold.

## What it produces

A compiling, runnable Flutter app:

```
<project>/
├── lib/
│   ├── main_dev.dart / main_staging.dart / main_prod.dart   flavor entries
│   ├── bootstrap.dart            env → DI → storage hydrate → runApp
│   ├── app.dart                  MaterialApp.router + LocaleCubit + force-logout
│   ├── core/
│   │   ├── base/base_cubit.dart
│   │   ├── config/               AppEnvironment + loader (flavors)
│   │   ├── services/             AppEventBus, AuthSession, LocaleCubit
│   │   ├── storage/              SecureStorage, Preferences, HiveStorage, keys
│   │   ├── theme/                colors, typography, theme
│   │   └── logger/app_logger.dart
│   ├── network/
│   │   ├── results.dart          ApiResult<T> (Success/Failure)
│   │   ├── resources.dart        Resources<T> (loading/success/error)
│   │   ├── errors.dart           sealed Errors hierarchy
│   │   ├── error_parser.dart · safe_call.dart · dio_module.dart
│   │   └── interceptors/         auth, refresh (mutex), logging
│   ├── di/                       di.dart + network/storage/retrofit modules
│   ├── routing/                  app_router.dart + guards/auth_guard.dart
│   └── features/
│       ├── splash/               initial route (session check)
│       ├── auth/                 FULL sample slice: login (domain/data/presentation)
│       └── home/                 protected route + logout
├── assets/translations/          en.json / ar.json
├── .env.example (+ generated .env.dev/staging/prod)
├── analysis_options.yaml         very_good_analysis + custom rules
├── flavorizr.yaml                native flavor config (opt-in)
├── pubspec.yaml                  the pinned dependency stack
├── test/features/auth/           sample bloc_test
└── CLAUDE.md                     the architecture rulebook for this project
```

The generated `lib/features/auth` slice is the **canonical reference** for
every layer — copy its shape when adding features.

## How to run it

The scaffold is fully automated by `scripts/scaffold.sh`. From anywhere:

```bash
bash <skill-dir>/scripts/scaffold.sh <project_name> \
  --org com.mycompany \
  --title "My App" \
  --desc "My delivery app" \
  --dir ~/dev/my_app
```

`<skill-dir>` is the directory containing this SKILL.md. The only required
argument is `<project_name>` (a valid Dart package name: lowercase, digits,
underscores, starts with a letter). Sensible defaults fill the rest.

Useful flags (full list in the script header):

- `--org <id>` — reverse-domain org for native bundle ids (default
  `com.example` → `com.example.<name>`).
- `--base-url <url>` — seeds `BASE_URL` in the `.env.*` files so the app boots
  (default `https://example.com`).
- `--flavors` — also run `flutter_flavorizr` for native dev/staging/prod
  wiring (off by default; it's fiddly and Flutter-version-sensitive).
- `--platforms <list>` — default `android,ios`.
- `--no-codegen` — skip build_runner + localisation generation.
- `--force` — allow a non-empty target directory.

### What the script does, in order

1. `flutter create` with the given org + platforms.
2. Overlays the template tree (removing the default `lib/main.dart` and
   `test/widget_test.dart`).
3. Substitutes `__PKG__`, `__APP_TITLE__`, `__DESCRIPTION__`, `__BUNDLE_ID__`
   across the copied files.
4. Creates `.env.dev/staging/prod` and appends secret-ignoring rules to
   `.gitignore`.
5. `flutter pub get`.
6. Generates localisation keys, then runs `build_runner` (injectable,
   retrofit, json_serializable, auto_route, flutter_gen).
7. Optionally runs `flutter_flavorizr`.

After it finishes: `cd` in, fill real values in the `.env.*` files, then
`flutter run -t lib/main_dev.dart`.

## Guidance when driving this yourself

- **Prefer the script.** It is deterministic and handles ordering (codegen
  must run before `flutter analyze` is meaningful, since `di.config.dart`,
  `*.gr.dart`, `*.g.dart`, and `locale_keys.g.dart` are generated).
- If the user's Flutter is older and `flutter pub get` fails to resolve the
  pinned versions, run `flutter pub upgrade --major-versions` in the new
  project, then re-run codegen — report this rather than silently editing
  version constraints.
- If you must scaffold **without** the script (e.g. a restricted environment),
  copy `assets/scaffold/` into the target, replace the four placeholders in
  every `.dart`/`.yaml`/`.json`/`.md`/`.env.example` file, create the `.env.*`
  files, and run steps 5–6 above by hand.
- To **add a feature** to an already-scaffolded project, follow
  `references/add-a-feature.md` — do not re-run the scaffold.
- To wire **Firebase, Maps, an HTTP inspector, a Toaster facade, or shimmer
  primitives**, see `references/extending.md`. The base scaffold deliberately
  omits these so it stays a clean, provider-agnostic spine.

## Reference material

- `references/architecture.md` — the layering rules, the Cubit/State/Action
  pattern, and the result-envelope contracts in depth.
- `references/add-a-feature.md` — step-by-step recipe for a new feature slice,
  mirroring the sample `auth` feature.
- `references/extending.md` — adding Firebase/FCM, maps, flavors' native
  wiring, a Toaster, shimmer, and other optional layers.

The generated `CLAUDE.md` is the rulebook the new project's contributors (and
Claude) must follow — it is the de-biker'd distillation of these same rules.
