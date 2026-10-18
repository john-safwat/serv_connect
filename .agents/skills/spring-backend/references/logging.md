# Logging

## Framework & configuration

- Use **SLF4J via Lombok `@Slf4j`** on the class — never `System.out.println` or a raw
  `Logger.getLogger`.
- `src/main/resources/logback-spring.xml` (see `assets/logback-spring.xml`) defines one readable
  pattern used by two appenders:
  - a **console** appender (local dev / container stdout), and
  - a **rolling file** appender to `logs/<app>.log` (e.g. 20MB/file, daily rollover, 30-day / 1GB
    retention) so history is persisted, not just visible while the process runs.
- `logs/` is gitignored — runtime output, not source.
- `logging.level.*` in `application-<profile>.properties` overrides levels on top of this base.
- The pattern includes a `%X{correlationId}` MDC slot. Populate it with a `OncePerRequestFilter`
  that reads/generates an `X-Correlation-Id` and puts it in the MDC when request tracing is needed
  (a correlation id carries no PHI and is safe to echo and log). Until such a filter exists the slot
  is just the default `-`.

## Levels

- `error` — unhandled/unexpected failures. **Always pass the exception object as the last argument**
  so the stack trace is captured: `log.error("Unhandled exception on {}", path, ex);`
- `warn` — handled-but-notable (a validation rejection, a failed auth attempt, a cache fallback).
- `info` — significant business events (user registered, appointment booked).
- `debug` — diagnostics only. **No PHI at `debug` either.**

## Parameterized only

Structured, parameterized logging — never string concatenation, which defeats aggregation and risks
concatenating sensitive data into the template:

```java
log.info("Appointment {} booked for patient {}", appointmentId, patientId);   // good
log.info("Appointment " + id + " booked for " + patientName);                  // never
```

## PHI/PII golden rule (same as security)

Never log a raw request/response body, a full entity, or any field containing a person's name, DOB,
diagnosis, address, phone, or national ID — at **any** level. Log identifiers (`patientId`) instead
of the person. The global exception handler logs only the request path (an opaque identifier) plus
the exception, never the request body. If a service needs richer audit detail ("which record
changed"), log the numeric/UUID id deliberately inside that method — never a blanket argument dump.
