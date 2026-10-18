# Localization (i18n)

## Supported locales — single source of truth

Define the supported set once in `common/i18n/SupportedLocales.java` (`ALL` + `DEFAULT`). Source
project: English (`en`, default) and Arabic (`ar`). To add a locale: add the `Locale` to `ALL`, add
`i18n/messages_<lang>.properties` with the required keys — no code change beyond that.

## Locale resolution

`common/config/LocalizationConfig.java` registers an `AcceptHeaderLocaleResolver` **restricted to
`SupportedLocales.ALL`**, defaulting to `DEFAULT` when the header is missing or requests an
unsupported language. A custom bean is required because Boot's `spring.mvc.locale` can only set a
default, not restrict accepted locales. Message-bundle lookup itself stays with Boot's
`MessageSourceAutoConfiguration` (`spring.messages.basename=i18n/messages` in `application.properties`)
— don't hand-roll a `MessageSource` bean.

`DispatcherServlet` calls the resolver at the start of every request, so any `@ExceptionHandler` or
`@RequestMapping` method can simply declare a `Locale` parameter and Spring resolves it — no manual
header reading.

## System (error) messages

The global exception handler resolves every client-facing message via constructor-injected
`MessageSource`, keyed by `common/i18n/MessageKeys.java`, always passing the historical English
string as `defaultMessage`:

```java
messageSource.getMessage(key, args, defaultMessage, locale);
```

so a missing/malformed key degrades to English instead of throwing `NoSuchMessageException` (which
would turn a handled error into a second unhandled one). Bundles live at
`src/main/resources/i18n/messages.properties` and `messages_<lang>.properties`.

## Bean Validation messages

`spring-boot-starter-validation` is required for `@Valid` to work at all. Once present, Boot wires
the app `MessageSource` into `LocalValidatorFactoryBean` automatically, and interpolation resolves
against `LocaleContextHolder.getLocale()` — the same locale the resolver set.

- **Overriding a standard Jakarta constraint's own key** localizes it for every annotated field with
  no `message="{...}"` on individual annotations:
  ```properties
  jakarta.validation.constraints.NotBlank.message=هذا الحقل مطلوب ولا يجوز أن يكون فارغًا.
  ```
  Override the constraints you use (`NotBlank`, `NotNull`, `Email`, `Size`, `Past`, `Pattern`,
  `Min`, `Digits`, …) in **both** bundles, adding more keys as features introduce new constraints.
- A **domain-specific** validation message uses an explicit `message = "{some.specific.key}"` on the
  annotation, with the key defined in both bundles.

## Domain-data translation (pattern)

When a feature owns translatable content (a specialty name, clinic name), use **locale-suffixed
columns directly on the entity** (`name_en`, `name_ar`, …) — not a per-locale child table — since
the locale set is small and fixed; a join per translated field is unjustified overhead. Rules:

- One column per translatable field per locale on the same table, added in the create migration.
- The default-locale column (`name_en`) is `NOT NULL`; others may be nullable until translated — a
  partial row still has a usable fallback.
- The mapper builds a small `locale → value` map at request time and resolves it with the fallback
  rule (missing locale → `DEFAULT`), exposing only the resolved string in the response DTO — never
  every locale column.
- Adding a locale later = a new migration `ALTER TABLE … ADD COLUMN name_<lang>` (backfilled or
  nullable per zero-downtime rules) on every table with suffixed columns; grep for an existing
  suffix like `_en` across `db/migration/` to find them.

## Localized HTML emails (Thymeleaf)

- Templates under `src/main/resources/templates/email/` inherit from a shared `fragments/layout.html`
  shell that applies `dir="rtl" lang="ar"` when `#locale.language == 'ar'`, else `dir="ltr" lang="en"`.
- Static text resolves from the same bundles via Thymeleaf `#{...}`; each email is a multipart
  `MimeMessage` with a plain-text fallback (resolved via `MessageSource`) plus the rendered HTML.
- **Async boundary caveat:** `@Async` event listeners run on a different thread and can't read
  `LocaleContextHolder` after the request completes. **Capture the locale at event-publication time**
  (`LocaleContextHolder.getLocale()`) and pass it through the domain event to the listener.

## Known limitation

Locale is derived from `Accept-Language` per request — no stored per-user preference yet. When a
stored preference is added, it can override the header.
