# Architecture reference

The contracts a scaffolded project is built on. The generated
`lib/features/auth` slice implements every one of these — read it alongside
this doc.

## Table of contents

1. Layering & dependency direction
2. The Cubit contract (`BaseCubit<T, A, NE>`)
3. State / Action / NavigationAction shapes
4. `ApiResult<T>` vs `Resources<T>` vs `Errors`
5. The network layer & interceptors
6. Dependency injection
7. Routing
8. Naming conventions

---

## 1. Layering & dependency direction

```
View (StatefulWidget) ──doAction(Action)──▶ Cubit
Cubit ──▶ UseCase ──▶ Repository (interface)
                          │
                RepositoryImpl ──▶ RemoteDataSource (Retrofit) + Mapper
                          └──▶ SecureStorage / Preferences / HiveStorage
```

- A View talks only to its Cubit, and only via `doAction`. It never sees a
  repository, use case, or `Dio`.
- A Cubit talks only to UseCases and `switch`es on the `ApiResult<T>` each
  returns. It never touches storage or the router.
- A UseCase returns `Future<ApiResult<T>>` and calls the repository
  **interface**, never `Dio` or the data source.
- `RepositoryImpl` wraps every remote call in `safeCall(...)`, maps DTOs to
  entities, and owns storage.
- `lib/core/` never imports `lib/features/`. One feature imports another only
  through a DI-registered use case passed via its constructor (see how
  `HomeCubit` injects `LogoutUseCase` from the auth feature).

## 2. The Cubit contract

`lib/core/base/base_cubit.dart` defines `BaseCubit<T, A, NE>`:

- `T` — State, `A` — sealed Action union, `NE` — sealed NavigationAction union.
- `doAction(A)` is the single entry-point; it `switch`es on `A` and delegates
  to one private `async` handler per case.
- `emitNavigation(NE)` pushes a one-shot effect onto `navigation`
  (a broadcast stream). The View listens in `initState` and cancels in
  `dispose`.
- Never call `Navigator` / `context.router` from a Cubit — it has no
  `BuildContext`. Emit a NavigationAction; the View bridges it.

Each handler follows the rhythm:

```dart
Future<void> _login(SubmitLoginAction action) async {
  emit(state.copyWith(loginResource: const Resources.loading()));
  final result = await _loginUseCase(email: action.email, password: action.password);
  switch (result) {
    case Success<UserData>():
      emit(state.copyWith(loginResource: Resources.success(data: result.data)));
      emitNavigation(NavigateToHome());
    case Failure<UserData>():
      emit(state.copyWith(loginResource: Resources.failure(
        exception: result.exception, message: result.message)));
      emitNavigation(ShowLoginError(result.message));
  }
}
```

## 3. State / Action / NavigationAction shapes

**Forbidden:** `freezed`, `equatable`, `dartz` / `fpdart` / `Either`. State is
a plain class; unions are Dart 3 `sealed class`es.

```dart
class LoginStates {
  LoginStates({this.loginResource = const Resources.initial()});
  final Resources<UserData> loginResource;
  LoginStates copyWith({Resources<UserData>? loginResource}) =>
      LoginStates(loginResource: loginResource ?? this.loginResource);
}

sealed class LoginAction {}
class SubmitLoginAction extends LoginAction { /* final fields */ }

sealed class LoginNavigationAction {}
class NavigateToHome extends LoginNavigationAction {}
class ShowLoginError extends LoginNavigationAction {
  ShowLoginError(this.message);
  final String message;
}
```

- State fields are `final`; always emit a new instance via `copyWith`. State
  uses identity equality, so `emit` fires whenever a fresh instance is passed —
  that is intentional.
- State never carries `Function`s, `BuildContext`, or `StreamController`s.
- If a State grows past ~12 fields, compose sub-states rather than reaching for
  freezed.

## 4. `ApiResult<T>` vs `Resources<T>` vs `Errors`

- `ApiResult<T>` (`lib/network/results.dart`) — what the **data layer
  returns**. Sealed `Success<T>` / `Failure<T>`.
- `Resources<T>` (`lib/network/resources.dart`) — what the **Cubit emits into
  State**. `initial` / `loading` / `success` / `error`, one per async op.
  Drives shimmer / spinner / error view. Convert `ApiResult` → `Resources`
  inside the `switch` arms.
- `Errors` (`lib/network/errors.dart`) — the sealed error hierarchy carried by
  `Failure` and `Resources.error`. `safeCall` + `ErrorParser` produce these
  from thrown exceptions, so feature code never `try/catch`es HTTP.

## 5. The network layer & interceptors

- `DioModule` builds two `Dio` instances: the **main** one (auth + refresh +
  logging interceptors) and a **bare** one for the refresh call (no
  `RefreshInterceptor`, so refresh can't recurse).
- `AuthInterceptor` attaches `Authorization: Bearer <token>` from
  `SecureStorage`, skipping whitelisted public paths.
- `RefreshInterceptor` catches 401 (only — 403 is a business error), refreshes
  the token under a `Lock` so N concurrent 401s trigger one refresh, retries
  the original request, and emits `ForceLogout` on the `AppEventBus` if refresh
  fails. `app.dart` listens and bounces to the login route.
- Retrofit `<Feature>RemoteDataSource` classes are the only place `Dio` is
  used. `RetrofitModule` exposes the main `Dio` under its bare type so the
  generated `factory ...(Dio dio)` resolves it.

## 6. Dependency injection

`injectable` + `get_it`. Annotation guide:

| Annotation                 | Use for                                              |
| -------------------------- | --------------------------------------------------- |
| `@injectable`              | Screen Cubits, use cases (new instance per resolve) |
| `@lazySingleton`           | Repositories, data sources, services, mappers       |
| `@singleton`               | Boot-critical (e.g. `AppLogger`)                    |
| `@module`                  | Factory bindings (`NetworkModule`, `StorageModule`) |
| `@LazySingleton(as: X)`    | Bind an impl to its interface (`AuthRepositoryImpl`)|

`AppEnvironment` is registered manually in `configureDependencies` before the
generated `$initGetIt` runs, because it is flavor-dependent. Re-run
`dart run build_runner build --delete-conflicting-outputs` after any DI change;
never edit `di.config.dart` by hand.

## 7. Routing

`auto_route`. `AppRouter` is `@LazySingleton @AutoRouterConfig`; every page is
`@RoutePage()`. Protected routes carry `guards: [AuthGuard(_session)]`, which
reads `AuthSession.isAuthenticated` and redirects to `LoginRoute` otherwise.
Regenerate `app_router.gr.dart` with `build_runner` after editing routes.

## 8. Naming conventions

| Artefact              | Convention                         | Example                 |
| --------------------- | ---------------------------------- | ----------------------- |
| Cubit                 | `<Feature><Screen>Cubit`           | `LoginCubit`            |
| State/Action/NavAction| `<F>States` / `<F>Action` / `<F>NavigationAction` | `LoginStates` |
| Action subclass       | `<Verb><Noun>Action`               | `SubmitLoginAction`     |
| NavAction subclass    | `<Verb><Noun>` / `Show<Noun><Fx>`  | `NavigateToHome`        |
| UseCase               | `<Verb><Noun>UseCase`              | `LoginUseCase`          |
| Repository / impl     | `<Feature>Repository` / `…Impl`    | `AuthRepository(Impl)`  |
| Mapper                | `<Feature>Mapper`                  | `AuthMapper`            |
| Remote data source    | `<Feature>RemoteDataSource`        | `AuthRemoteDataSource`  |
| Request / Response DTO| `<Name>Request` / `<Name>Response` | `LoginRequest`          |
