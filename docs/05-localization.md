# Localization

## Locales

English (`en`, default, LTR) and Arabic (`ar`, RTL). Every user-facing string is added in both in the same change.

## Backend

- Locale comes from the `Accept-Language` header via an `AcceptHeaderLocaleResolver` restricted to `SupportedLocales`; unsupported or absent falls back to `en`. System-locale fallback is disabled so the default bundle is always English.
- Bundles: `src/main/resources/i18n/messages.properties` (en) and `messages_ar.properties`, UTF-8, `spring.messages.basename=i18n/messages`. Keys must stay in sync between the two files.
- Keys are constants in `common/i18n/MessageKeys`; dotted lowercase with hyphens (`error.not-found`). Domain exceptions carry a key, never a raw string. Lookups pass the key itself as the default so a missing key degrades gracefully.
- Jakarta constraint messages (`jakarta.validation.constraints.*.message`) are overridden app-wide in both bundles; the validator resolves them through the `MessageSource`.
- Push notifications will be localized to the recipient's stored language, not the request locale.
- The backend returns machine values (ISO-8601 UTC instants, `LocalDate`s, numbers); clients format dates, numbers, and calendars. Religious/liturgical content is data (content packs), not bundle entries.

## Current keys

`common.success`, `error.generic`, `error.validation`, `error.not-found`, `error.already-exists`, `error.unauthorized`, `error.forbidden`, `error.invalid-credentials`, `error.stale-version`, `error.feature-disabled`, `error.malformed-request`, `error.field-invalid`, `error.method-not-allowed`, `error.business-rule`, `error.unsupported-media-type`, `error.not-acceptable`, `error.data-conflict`, plus Jakarta overrides for `NotBlank`, `NotNull`, `Size`, `Email`, `Pattern`, `Past`, `Positive`, `Min`, `Max`.

## Clients

### Mobile (`serv_connect_mobile/`)
- Uses `easy_localization` with `assets/translations/en.json` and `assets/translations/ar.json` organised by namespace (`common`, `nav`, `errors`, `validation`, `home`) and strongly-typed keys generated into `lib/generated/locale_keys.g.dart` via:
  ```bash
  dart run easy_localization:generate -S assets/translations -O lib/generated -o locale_keys.g.dart -f keys
  ```
- Active locale is persisted in `Preferences` (`StorageKey.appLanguage`) and managed by `LocaleCubit`. `AcceptLanguageInterceptor` attaches `Accept-Language: <en|ar>` to every `Dio` request.
- Typography switches automatically by locale (`Fraunces` + `Inter` for `en`; `Amiri` + `Cairo` for `ar`).
- All layouts use directional primitives (`EdgeInsetsDirectional`, `AlignmentDirectional`, `BorderRadiusDirectional`). Configurable church terms (`Servant`, `Served Member`, `Stage`, `Group`) resolve through `OrgLabelResolver` (`FR-16.2`).

### Web Dashboard (`serv_connect_dashboard/`)
- Uses `i18next` + `react-i18next` with JSON namespaces in `src/locales/en/{common,nav,errors,validation}.json` and `src/locales/ar/{common,nav,errors,validation}.json`.
- Strongly-typed `LocaleKeys` (`src/generated/locale_keys.g.ts`) and 100% EN/AR key + placeholder parity are generated and verified via:
  ```bash
  npm run i18n:generate
  npm run i18n:check
  ```
- `LocaleController` sets `<html lang="en|ar" dir="ltr|rtl">` and persists only the non-sensitive locale code under `serve_locale`. `AcceptLanguageInterceptor` sends `Accept-Language: <en|ar>` on every `HttpClient` request.
- CSS Modules use CSS logical properties exclusively (`margin-inline-start`, `padding-inline`, `inset-inline-start`, `border-inline-start`, `text-align: start`), and `[dir="rtl"]` switches `--font` to `'Cairo'` and `--serif` to `'Amiri'`. Configurable church labels resolve via `useOrgLabels()` (`OrgLabelResolver`).
