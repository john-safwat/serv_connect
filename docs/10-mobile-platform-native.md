# 10 — Mobile Platform, Flavors & Native Interop (`serv_connect_mobile`)

| Field | Value |
| --- | --- |
| Flavors | `dev`, `staging`, `prod` (`flavorizr.yaml`) |
| Env Files | `.env.example` (tracked), `.env.dev`, `.env.staging`, `.env.prod` (gitignored) |
| Native Channel | `com.john.serv_connect_mobile/device` (`ServePlatform` ↔ Kotlin / Swift handlers) |

---

## 1. Build Flavors (`dev` / `staging` / `prod`)

Configured in `serv_connect_mobile/flavorizr.yaml`, `android/app/build.gradle.kts`, and `ios/Flutter/{Dev,Staging,Prod}.xcconfig`:

| Flavor | App Display Name | Android `applicationId` | iOS `PRODUCT_BUNDLE_IDENTIFIER` | Entrypoint | Env File |
| --- | --- | --- | --- | --- | --- |
| `dev` | `ServeConnect Dev` | `com.john.serv_connect_mobile.dev` | `com.john.servConnectMobile.dev` | `lib/main_dev.dart` | `.env.dev` |
| `staging` | `ServeConnect Staging` | `com.john.serv_connect_mobile.staging` | `com.john.servConnectMobile.staging` | `lib/main_staging.dart` | `.env.staging` |
| `prod` | `ServeConnect` | `com.john.serv_connect_mobile` | `com.john.servConnectMobile` | `lib/main_prod.dart` | `.env.prod` |

### 1.1 Run Commands

```bash
flutter run --flavor dev -t lib/main_dev.dart
flutter run --flavor staging -t lib/main_staging.dart
flutter run --flavor prod -t lib/main_prod.dart
```

---

## 2. Environment Configuration (`AppEnvironment`)

Loaded at startup by `AppEnvironmentLoader` (`lib/core/config/app_environment_loader.dart`) and validated by `AppEnvironment.assertConfigured()` (`lib/core/config/app_environment.dart`). If any required key is missing, empty, or starts with `__`, startup fails immediately with a `StateError`.

| Key | Required | Default / Example (`.env.example`) | Description |
| --- | --- | --- | --- |
| `API_BASE_URL` | Yes | `https://api.dev.serveconnect.org` | Base URL for `/api/v1/*` REST calls |
| `ENV_NAME` | Yes | `dev` | Environment identifier (`dev`, `staging`, `prod`) |
| `DEFAULT_OFFLINE_GRACE_DAYS` | Yes (> 0) | `14` | Offline session grace window in days (`FR-1.3`) |
| `MEDIA_CACHE_MAX_MB` | Yes (> 0) | `250` | Maximum on-device media cache size (`NFR-12`) |
| `SYNC_BATCH_SIZE` | Yes (> 0) | `50` | Maximum mutations pushed per `/api/v1/sync/mutations` batch |
| `SENTRY_DSN` | Optional | `""` | Crash reporting DSN (PII-scrubbed) |

---

## 3. Transport Security (`NFR-4`)

- **Android:** `android/app/src/main/AndroidManifest.xml` sets `android:usesCleartextTraffic="false"`. Only the `dev` flavor manifest (`android/app/src/dev/AndroidManifest.xml`) enables `android:usesCleartextTraffic="true"` for local backend testing (`http://localhost:8080` / `10.0.2.2`).
- **iOS:** `ios/Runner/Info.plist` sets `NSAppTransportSecurity -> NSAllowsArbitraryLoads = false`.

---

## 4. Native Platform Channel (`ServePlatform`)

Native capabilities not covered by pure-Dart plugins are exposed behind `ServePlatform` (`lib/core/platform/serve_platform.dart`) and `ServePlatformMethodChannel` (`lib/core/platform/serve_platform_method_channel.dart`):

- **Channel Name:** `com.john.serv_connect_mobile/device`
- **Methods:**
  - `getDeviceMetadata` → returns `@JsonSerializable() DeviceMetadata` (`platform`, `osVersion`, `sdkInt`, `packageName`) wrapped in `ApiResult<DeviceMetadata>`.
- **Error Boundary:** `ServePlatformMethodChannel` catches `PlatformException` and maps it to `Failure(exception: PlatformError(code, message))` — raw `PlatformException` never escapes into Cubits.
- **Native Handlers:**
  - Android: `android/app/src/main/kotlin/com/john/serv_connect_mobile/platform/ServeMethodChannelHandler.kt` (registered in `MainActivity.kt`).
  - iOS: `ios/Runner/Platform/ServeMethodChannelHandler.swift`.
