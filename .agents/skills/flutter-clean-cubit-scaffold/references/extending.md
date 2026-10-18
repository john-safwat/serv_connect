# Extending the scaffold

The base scaffold is a clean, provider-agnostic spine. Add these layers per
project as needed. Each keeps to the same rules: DI-registered, no secrets in
source, docs updated.

## Native flavors (`flutter_flavorizr`)

The three `main_<flavor>.dart` entries and `.env.<flavor>` files exist from the
start, so `flutter run -t lib/main_dev.dart` works immediately with a single
default native flavor. To get **distinct native flavors** (separate app ids,
icons, names for dev/staging/prod):

```bash
dart run flutter_flavorizr          # reads flavorizr.yaml
```

`flavorizr.yaml`'s `instructions` list is pre-set to touch only native
Android/iOS files, never `lib/`. After it runs:

```bash
flutter run --flavor dev -t lib/main_dev.dart
```

Add a launch config per flavor in your IDE so nobody types the long command.
Re-run flavorizr and commit the result after editing `flavorizr.yaml`.

## A new flavor

1. Add the enum value in `lib/core/config/app_environment.dart`.
2. Add `lib/main_<flavor>.dart` calling `bootstrap(flavor: Flavor.<x>)`.
3. Add `.env.<flavor>` (and list it under `flutter: assets:` in `pubspec.yaml`).
4. Add the flavor block to `flavorizr.yaml`, re-run flavorizr.

## Firebase / FCM / Crashlytics

1. `flutterfire configure --flavor=dev` (etc.) — do **not** commit the
   generated `firebase_options*.dart` or the plist/json (already gitignored).
2. Add `firebase_core`, `firebase_messaging`, `firebase_crashlytics`,
   `firebase_analytics` to `pubspec.yaml`.
3. In `bootstrap.dart`, after loading env and before `configureDependencies`,
   add:
   ```dart
   await Firebase.initializeApp(options: firebaseOptionsFor(flavor));
   FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterError;
   PlatformDispatcher.instance.onError = (e, s) {
     FirebaseCrashlytics.instance.recordError(e, s, fatal: true);
     return true;
   };
   ```
4. Add the Firebase fields to `AppEnvironment` / `AppEnvironmentLoader` and the
   keys to `.env.example`, then assert them at boot.
5. Wrap FCM behind an `@lazySingleton FcmService` initialised in `bootstrap`;
   route pushes through `AppEventBus` events, not directly to the router.

## Google Maps / geolocation

Add `google_maps_flutter` + a location plugin, put the Maps key in
`.env.<flavor>` → `AppEnvironment`, and inject it into the Android manifest via
`manifestPlaceholders` and into iOS via `AppDelegate` at bootstrap. Wrap map
usage in a `BikerMap`-style widget so the key handoff and unavailable-state
fallback live in one place.

## Toaster & BottomSheetHost facades

The sample `LoginPage` uses a raw `ScaffoldMessenger` SnackBar. For a real app,
add a `Toaster` facade (a `@lazySingleton` mounting via a global
`ScaffoldMessengerKey` set on `MaterialApp.router`) with
`showSuccess/showError/showWarning`, and a `BottomSheetHost` for modal sheets.
Feature code then calls `getIt<Toaster>()` from the View's `_handleNavigation`
— never from a Cubit.

## Shimmer loading primitives

Add `lib/core/common_ui/shimmer/` with reusable skeletons (list, row, grid)
built on the `shimmer` package (already in `pubspec.yaml`). Drive them off
`state.<resource>.isLoading`. Prefer shimmer over spinners for list/grid
loading; keep in-button spinners only for submit actions.

## Cached network images

`cached_network_image` is in the stack. Wrap it in a
`lib/core/common_ui/network_image.dart` widget that bakes in the placeholder,
error fallback, and shimmer, and use that everywhere instead of `Image.network`.

## Adding an endpoint to an existing data source

1. Add the method to the Retrofit `<Feature>RemoteDataSource` abstract class.
2. Add / adjust the request & response DTOs.
3. Add the repository method (wrapped in `safeCall`) and its use case.
4. `dart run build_runner build --delete-conflicting-outputs`.
5. Update the API docs / endpoint table and add a test.

## An HTTP inspector for QA builds

For on-device request inspection on non-prod builds, add an inspector package
(e.g. `chucker_flutter`) as an interceptor built conditionally in `DioModule`
(return `null` on prod, mirroring `LoggingInterceptor`), and mount its overlay
via the router's `navigatorObservers` gated on `!env.isProduction`.
