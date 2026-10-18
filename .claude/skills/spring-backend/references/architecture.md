# Application Architecture & Layering

Every feature follows the same call chain: **Controller → Service → Repository.** No layer
is skipped.

```
XController  --calls-->  XService (interface)
                              |
                        XServiceImpl  --calls-->  XRepository
                              |                        |
                        XMapper (Entity<->DTO)    X (@Entity)
```

## Controllers

- Bind the HTTP request (`@RequestBody`, `@PathVariable`, `@RequestParam`), validate
  (`@Valid`), delegate to **exactly one** service method, wrap the result in a
  `ResponseEntity` via `BaseResponseBody`.
- No business logic, no repository calls, no entity manipulation in a controller.
- Base path `/api/v1/<resource>` — plural nouns, kebab-case for multi-word
  (`/api/v1/medical-records`). Version prefix `v1` is mandatory from the first endpoint.
  (If the app sets `server.servlet.context-path=/api`, map controllers **without** repeating
  `/api` — e.g. `@RequestMapping("/v1/patients")` — the container prefixes it back.)
- HTTP verbs map to intent: `GET` read, `POST` create (`201` + `Location`), `PUT` full
  replace, `PATCH` partial update, `DELETE` remove/soft-delete. `GET`/`DELETE` take no body.
- A sub-resource action verb is acceptable when the transition isn't a plain field update:
  `POST /api/v1/appointments/{id}/cancel`. Prefer `PATCH` for partial updates otherwise.

## Services

- Hold business logic and own transaction boundaries (`@Transactional`; read-only methods
  use `@Transactional(readOnly = true)`).
- Receive and return DTOs/domain types — a controller never sees an `@Entity`, and a service
  never accepts a controller-shaped request object other than the DTO.
- Define a service **interface + `*Impl`** when a feature has (or will soon have) more than
  one implementation, or when another feature consumes it — this is the project default so
  callers depend on the abstraction (Dependency Inversion). A single-impl CRUD feature may
  use a concrete `@Service` class; don't add an interface purely for ceremony.
- Keep transactions short: no outbound HTTP, file I/O, or long computation inside
  `@Transactional`. Don't swallow an exception in a way that defeats rollback.

## Repositories

- `interface XRepository extends JpaRepository<X, Long>` (or `UUID`). No business logic beyond
  derived-query method names and `@Query` (JPQL preferred; native SQL only when JPQL can't
  express it).
- Any list that can grow unbounded is paginated (`Pageable`/`Page<T>`), never a wholesale
  `List<T>` into a controller.
- Avoid N+1: use `@EntityGraph` or `JOIN FETCH` for a listing's associations, not a lazy walk
  in a loop.

## Mappers

- `Entity ↔ DTO` conversion. Project default is **MapStruct** `@Mapper(componentModel = "spring")`
  interfaces (adopted project-wide, not per-feature). Hand-written `@Component` mappers are the
  fallback if MapStruct isn't adopted.

## DTOs & mapping

- Request/response DTOs are **Java `record`s** — immutable, no Lombok.
- A DTO never carries a JPA annotation; an entity never carries request-binding validation.
  Validation lives on the request DTO.
- **Never return an `@Entity`** (or a JPA-proxied collection) from a controller — it leaks
  lazy-loading exceptions, internal fields, and relationship cycles.
- A response DTO includes only fields the consumer needs — omit audit columns, soft-delete
  flags, and anything internal.

```java
public record PatientRequest(
        @NotBlank @Size(max = 100) String firstName,
        @NotBlank @Size(max = 100) String lastName,
        @Past LocalDate dateOfBirth,
        @Email String email
) {}

public record PatientResponse(
        Long id, String firstName, String lastName,
        LocalDate dateOfBirth, String email, Instant createdAt
) {}
```

## Dependency injection & Lombok

- **Constructor injection only** via Lombok `@RequiredArgsConstructor` on `final` fields —
  never field injection (`@Autowired` on a field) or setter injection.
- Lombok is deliberate: `@RequiredArgsConstructor` for injection, `@Slf4j` for logging,
  `@Getter`/`@Builder` where they remove real boilerplate. **Never `@Data` on an `@Entity`.**
  Prefer records over Lombok for DTOs.

```java
@Service
@RequiredArgsConstructor
public class PatientServiceImpl implements PatientService {
    private final PatientRepository patientRepository;
    private final PatientMapper patientMapper;

    @Override
    @Transactional
    public PatientResponse create(PatientRequest request) {
        Patient patient = patientMapper.toEntity(request);
        return patientMapper.toResponse(patientRepository.save(patient));
    }
}
```

## Naming symmetry

`PatientController ↔ PatientService ↔ PatientRepository ↔ Patient` — a reader should be able
to guess the sibling class names. No wildcard imports.
