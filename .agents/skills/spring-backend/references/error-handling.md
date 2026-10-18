# Error Handling & the Response Envelope

## The uniform envelope: `BaseResponseBody`

Every endpoint and the global handler return a `BaseResponseBody` — a **sealed** interface with
two record subtypes, `Success<T>` (carries `data`) and `Fail<T>` (carries an optional
`List<FieldError>`). See `assets/BaseResponseBody.java` and `assets/FieldError.java`.

- `@JsonInclude(NON_NULL)` keeps optional fields off the wire (a void success serializes as
  `{code, status, message}`; a fail with no field errors omits `errors`).
- Static factories for the common case: `BaseResponseBody.success(data, message, status)` and
  `BaseResponseBody.fail(status, message, errors)`; `toResponseEntity(body)` wraps for return.
  Hand-written per-subtype builders exist for multi-step construction.
- **Never return `204 No Content`.** A void operation returns a `Success` with `data: null` and
  `code: 200`, so clients always get the same structure.

Controller usage:

```java
return BaseResponseBody.toResponseEntity(
        BaseResponseBody.success(response, "Patient created", HttpStatus.CREATED));
```

## The global exception handler

A single `@RestControllerAdvice` (see `assets/HealthCareExceptionHandler.java` — rename per
project) maps every exception to `BaseResponseBody.Fail`. Core rules:

- The **client-facing `message` is generic** — never `exception.toString()`, a raw message, or
  a stack trace. Those are a security and PHI leak.
- **Detail is logged server-side only** (SLF4J), with the request path as an opaque identifier
  (paths carry no PHI — see `references/security.md`).
- Messages are **localized** via `MessageSource` keyed by `MessageKeys`, resolved from the
  request `Locale`, always passing the historical English string as `defaultMessage` so a
  missing/malformed key degrades gracefully instead of throwing a second exception.

## Domain exceptions

Live in `common/exception/`, extend `RuntimeException`, and each maps to a status in the
handler. Services throw these — they never return `null` to signal "not found" and never let a
raw `NullPointerException`, `DataIntegrityViolationException`, or JPA exception escape.

| Exception (example) | Status | Message key |
|---|---|---|
| `EntityNotFoundException` | 404 | `error.entityNotFound` |
| `InvalidCredentialsException` | 401 | `auth.invalidCredentials` |
| `EmailAlreadyRegisteredException` / `PhoneAlreadyRegisteredException` | 409 | `auth.emailAlreadyRegistered` / `…phone…` |
| `SlotAlreadyBookedException` (state conflict) | 409 | `error.slotAlreadyBooked` |
| `MethodArgumentNotValidException` (Bean Validation) | 400 | `error.validation` (+ per-field `errors`) |
| `AuthenticationException` | 401 | `error.unauthorized` |
| `AccessDeniedException` | 403 | `error.forbidden` |
| `Exception` (catch-all) | 500 | `error.unexpected` |

- A repository unique-constraint violation is **caught in the service** and rethrown as a typed
  `Duplicate*`/`*AlreadyRegistered` exception (→ 409), not left to surface as a raw
  `DataIntegrityViolationException`. The source project relies on the DB unique constraint plus
  this translation rather than a pre-save SELECT.
- Validation failures collect per-field messages into `List<FieldError>`; class-level/global
  constraints surface with an empty field name.

## Status code conventions

`200` read/update/delete (wrapped), `201` create (+ `Location`, wrapped), `400` validation,
`401` missing/invalid auth, `403` authenticated-but-forbidden, `404` not found, `409` conflict,
`429` rate limit, `500` unhandled (never leaks detail). Never `204`.

## Filter-level 401/403

Security exceptions thrown inside the filter chain (before a controller runs) are routed into
the same handler so their responses use the same envelope: implement Spring Security's
`AuthenticationEntryPoint` and `AccessDeniedHandler` to delegate to `HandlerExceptionResolver`,
and wire them in `SecurityConfig.exceptionHandling(...)`. See `references/security.md`.
