# API Reference

The backend owns this contract; clients rely only on what is documented here. No `/api/v1` endpoints exist yet (the foundation delivers conventions only).

## Conventions

- Base path `/api/v1/<resource>`; plural kebab-case nouns; no verbs. `/api/v1/me/...` scopes to the caller.
- Methods: `GET` read, `POST` create (`201` + `Location`), `PUT` replace, `PATCH` partial, `DELETE` soft-delete / tombstone.
- Status codes: `200`, `201`, `400`, `401`, `403`, `404`, `405`, `409`, `429`, `500`. Never `204`; a void success is `200` with no `data`.
- Identifiers in URLs are opaque UUIDs. No name, phone, or email in a path or query.
- Changes to `/api/v1` are additive only; breaking changes are a new version.
- Idempotency: every create/mutation callable offline accepts a client-generated UUID (entity `id` or an `Idempotency-Key` header) and returns the original result on retry.
- Pagination: `page`, `size`, `sort` query parameters; list endpoints return a `PageResponse` inside `data`.

### Headers

| Header | Direction | Notes |
| --- | --- | --- |
| `Accept-Language` | request | `en` (default) or `ar`; anything else falls back to `en`. Controls `message` and field error text |
| `X-Correlation-Id` | request / response | optional UUID from the client; otherwise generated. Always echoed |
| `Authorization: Bearer <jwt>` | request | issued by the identity feature (not yet built) |
| `Idempotency-Key` | request | allowed by CORS; semantics per endpoint |

### Response envelope (`BaseResponseBody`)

Success:

```json
{ "code": 200, "status": "OK", "message": "Success", "data": { } }
```

`data` is omitted when null. Failure:

```json
{
  "code": 400,
  "status": "BAD_REQUEST",
  "message": "Validation error.",
  "errors": [ { "field": "name", "message": "must not be blank" } ]
}
```

`errors` is omitted unless there are field errors. `field` is empty for class-level violations. `message` is localized and generic: it never contains stack traces, SQL, or exception text. Clients parse the localized `message` and `code`, never raw text.

`PageResponse` (inside `data`): `{ "content": [], "page": 0, "size": 20, "totalElements": 0, "totalPages": 0 }`.

### Error mapping

| Condition | Status |
| --- | --- |
| Bean Validation failure | 400 with `errors[]` |
| Malformed JSON / missing non-null field / bad enum | 400, `errors[0].field` names the field when known |
| Missing or invalid authentication | 401 |
| Authenticated but lacking permission or scope; feature disabled | 403 |
| Unknown resource / `EntityNotFoundException` | 404 |
| Unsupported HTTP method | 405 |
| Unsupported request `Content-Type` | 415 |
| `Accept` that cannot be satisfied | 406 (envelope still returned as JSON) |
| Missing/invalid parameter, header or part; method-level constraint violation | 400 |
| Optimistic-lock failure (stale `version`) | 409 |
| Database integrity violation (unique/FK) | 409 generic message, never row values |
| Duplicate / stale version / `BusinessRuleException(conflict)` | 409 |
| Unhandled exception | 500 (generic message, detail logged server-side) |

## Endpoints

Not under `/api/v1`, so not client contracts:

| Method | Path | Auth | Purpose |
| --- | --- | --- | --- |
| GET | `/` | public | landing; `data.name` is the application name |
| GET | `/actuator/health` | public | liveness/readiness (`status`: `UP`), no details |

`/api/v1/auth/**` is reserved as public for the identity plan. Every other path returns the `401` envelope until then.
