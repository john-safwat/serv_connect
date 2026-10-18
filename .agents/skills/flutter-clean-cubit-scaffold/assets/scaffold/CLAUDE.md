# __APP_TITLE__ — Flutter Development Rules

> Read and follow every rule here before starting **any** task — feature, bug
> fix, refactor, or one-line hot-fix. "It's a small change" is never grounds to
> skip a rule. A task ends only when the code compiles, `dart format` and
> `flutter analyze` are clean, tests pass, **and** the docs reflect the change.

This project follows **Clean Architecture + Cubit**, organised by feature. It
was scaffolded with the `flutter-clean-cubit-scaffold` skill; the sections
below mirror that structure.

---

## 0. Pre-Task Checklist

1. Read this file.
2. Write a short plan (files created/modified, approach) before writing code.
3. Check for an existing widget / `UseCase` / `Mapper` / util that already
   covers the need — extend before inventing.
4. Confirm every endpoint the task needs already exists. If one is missing,
   stop and report it rather than working around it.
5. Never hard-code a colour, text style, or dimension — add it to
   `lib/core/theme/` and reference the token.

---

## 1. Architecture & Layering

```
lib/features/<name>/
├── presentation/<screen>/view/   <screen>_cubit.dart / _states.dart / _page.dart
├── presentation/<screen>/widgets/
├── domain/{entities,repository,use_case}/
└── data/{datasource,model,mapper,repository}/
```

- **View → Cubit** only, via `cubit.doAction(<Action>)`. Views never touch
  repositories, use cases, or `Dio`.
- **Cubit → UseCase.** Cubits never call repositories directly; they `switch`
  on the `ApiResult<T>` each use case returns.
- **UseCase → Repository interface.** Returns `Future<ApiResult<T>>`.
- **RepositoryImpl → RemoteDataSource + Mapper.** Wraps every call in
  `safeCall(...)`. Owns storage (`SecureStorage` / `Preferences` /
  `HiveStorage`).
- `lib/core/` never imports `lib/features/`. One feature never imports another
  except through a DI-registered use case passed via constructor.

### File & method limits

| Kind                   | Max lines |
| ---------------------- | --------- |
| Dart file              | 400       |
| `build()` body         | 100 (extract sub-widgets) |
| Method / function body | 25 (extract helpers)      |

---

## 2. The Cubit Contract — `BaseCubit<T, A, NE>`

Every screen Cubit extends `BaseCubit<States, Action, NavigationAction>`
(`lib/core/base/base_cubit.dart`). **Cubit, never Bloc** — no `on<Event>`, no
event transformers. The single entry-point is `doAction(action)`.

- `State` — a **plain class** with `final` fields and a hand-written
  `copyWith`. No `freezed`, no `equatable`.
- `Action` / `NavigationAction` — Dart 3 **`sealed class`** unions, so the
  `switch` in `doAction` / `_handleNavigation` is exhaustive without `default`.
- Mutate only via `emit(state.copyWith(...))` — never reassign `state`, never
  mutate a collection in place.
- One-shot effects (navigate, toast, sheet) go through
  `emitNavigation(<NavigationAction>())`. The Cubit has **no `BuildContext`**
  and never calls the router — the View bridges navigation in its
  `_handleNavigation` switch.
- Per-action handlers follow: emit loading → call use case → `switch` on
  `ApiResult` → emit success/failure → emit navigation effect.
- The View cancels its `cubit.navigation` subscription in `dispose`.

---

## 3. Result & Loading Envelopes

- **Data layer returns `ApiResult<T>`** (`lib/network/results.dart`) — sealed
  `Success<T>` / `Failure<T>`. Never `Future<T>`, never `Either`.
- **Cubit emits `Resources<T>`** into State (`lib/network/resources.dart`) —
  `initial` / `loading` / `success` / `error`, one per async operation.
- **Every error is an `Errors`** (`lib/network/errors.dart`) sealed subclass.
  `safeCall` + `ErrorParser` convert thrown `DioException` / `FormatException`
  / `TimeoutException` into `Failure`. Feature code never `try/catch`es HTTP.

---

## 4. Network

- Retrofit `<Feature>RemoteDataSource` classes only; never call `Dio` from a
  Cubit / UseCase / Repository.
- DTOs are `@JsonSerializable(fieldRename: FieldRename.snake)` plain classes
  with hand-written `fromJson` / `toJson` wrappers. No `freezed`.
- The `AuthInterceptor` attaches the bearer token; the `RefreshInterceptor`
  handles 401 → refresh → retry with a mutex, and emits `ForceLogout` on the
  bus when refresh fails. Don't attach `Authorization` manually.
- Tokens live only in `SecureStorage` — never logged, never in query strings.
- New endpoint → update the API docs and the endpoint table in the same PR.

---

## 5. Localisation

- **Every** user-facing string is localised via `easy_localization`. Add the
  key to **both** `assets/translations/en.json` and `ar.json`, then run the
  generator (see §7) before using `LocaleKeys.<scope>_<key>`.
- From widget code always pass `context`: `LocaleKeys.x.tr(context: context)`.
  Bare `.tr()` is only for validators, post-`await` toasts, and non-widget
  code (Cubits, mappers).
- Layouts are direction-agnostic: use `EdgeInsetsDirectional` and
  `AlignmentDirectional`, never `left`/`right`.

---

## 6. Dependency Injection

- `injectable` + `get_it`. Screen Cubits are `@injectable` (new per resolve);
  repositories / data sources / services are `@lazySingleton`; boot-critical
  singletons are `@singleton`.
- `AppEnvironment` is registered manually in `configureDependencies` before the
  generated graph runs (it is flavor-dependent).
- Never edit `di.config.dart` by hand — regenerate after any DI change.

---

## 7. Code Generation

Generated files are **committed**. After changing a source annotation, run:

```bash
dart run build_runner build --delete-conflicting-outputs
```

After changing translation JSON, run:

```bash
dart run easy_localization:generate -S assets/translations -O lib/generated -o locale_keys.g.dart -f keys
```

Every PR that changes a source annotation must commit the regenerated output.

---

## 8. Testing (≥ 70% coverage)

- Every `UseCase`, `Mapper`, `Repository`, and `Cubit` has a test. Mirror the
  `lib/` path under `test/`.
- Use `bloc_test` for Cubits (works despite the name), `mocktail` for mocks,
  `http_mock_adapter` for Dio-level tests.
- `flutter test --coverage`; don't merge if coverage drops.

---

## 9. Lint & Formatting

`analysis_options.yaml` extends `very_good_analysis` and errors on unused
imports/elements/fields/locals. Before every commit:

```bash
dart format --set-exit-if-changed .
flutter analyze
```

Both must exit 0. No `// ignore:` without a justification.

---

## 10. Flavors, Secrets & Security

- Three flavors: `dev`, `staging`, `prod`, each with a `main_<flavor>.dart`
  entry, a `.env.<flavor>` file, and (after `flutter_flavorizr`) its own native
  application id.
- All base URLs / keys live in `.env.<flavor>`, loaded once into
  `AppEnvironment`. Never `dotenv.env['KEY']` at a call site. Only
  `.env.example` is committed.
- No secret, token, or PII in source or logs. Use `AppLogger` (no-op in
  release), never `print` / `debugPrint`.
- Cleartext traffic disabled on release; TLS bypass gated to non-prod only.

---

## 11. Post-Task Documentation

A task is done when the docs match reality. Update the relevant doc in the same
PR: feature docs, the component catalogue for shared widgets, the endpoint
table for network changes, the DI catalogue for new bindings. If a code change
touched no docs, ask whether it really needed none — the default assumption is
that it did.
