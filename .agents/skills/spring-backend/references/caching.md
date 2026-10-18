# Caching (Redis)

Distributed caching via `spring-boot-starter-cache` + `spring-boot-starter-data-redis`, configured
in `common/config/CacheConfig.java` (see `assets/CacheConfig.java`).

## Fail-open resilience

The config class implements `CachingConfigurer` and supplies a custom `CacheErrorHandler` that
catches Redis connection and serialization exceptions, **logs a warning, and falls through to the
primary database query** instead of failing the request. A Redis outage degrades performance, never
availability. Every `handleCache{Get,Put,Evict,Clear}Error` override logs and swallows.

## Named regions with explicit TTLs

Declare cache-region name constants and give each region a TTL suited to how volatile its data is.
Example regions from the source project:

| Region | TTL | Contents |
|---|---|---|
| `specialties` | 60m | reference catalog (rarely changes) |
| `user-directory` | 30m | user metadata lookups shared across services |
| `doctor-profile` | 15m | public doctor profile views |
| `clinic-profile` | 15m | public clinic profile views |
| `rating-summary` | 15m | aggregate review summaries |

Build them with `RedisCacheManager.builder(...).cacheDefaults(default15m).withInitialCacheConfigurations(map)`.
Use a `GenericJackson2JsonRedisSerializer` (with a `JavaTimeModule`-registered `ObjectMapper`,
default typing enabled) for values and a `StringRedisSerializer` for keys; `disableCachingNullValues()`.

## What to cache — and eviction discipline

- Cache only **read-heavy, rarely-changing** data — reference/lookup data and public profile views.
  **Never** cache patient-specific or frequently-mutated data without an explicit invalidation story.
- **Pair every mutation with a `@CacheEvict`.** Every `update`/`delete`/`approve`/`review-create`
  path that changes cached data evicts the affected region. `@CachePut` where you want to refresh
  rather than evict.

```java
@Cacheable(cacheNames = CacheConfig.CACHE_DOCTOR_PROFILE, key = "#doctorId")
public DoctorProfileResponse getPublicProfile(Long doctorId) { … }

@CacheEvict(cacheNames = CacheConfig.CACHE_DOCTOR_PROFILE, key = "#doctorId")
public DoctorProfileResponse update(Long doctorId, DoctorProfileUpdateRequest req) { … }
```

## Local / test

`compose.yaml` runs a local `redis:7-alpine`. Integration tests set `spring.cache.type=simple`
(in-memory) for fast execution; the `RedisCacheManager` bean is guarded with
`@ConditionalOnProperty(name="spring.cache.type", havingValue="redis", matchIfMissing=true)` and
`@ConditionalOnBean(RedisConnectionFactory.class)` so it only activates when Redis is actually configured.
