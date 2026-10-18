package com.john.sev_connect_backend.common.config

import org.slf4j.LoggerFactory
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty
import org.springframework.cache.Cache
import org.springframework.cache.annotation.CachingConfigurer
import org.springframework.cache.annotation.EnableCaching
import org.springframework.cache.interceptor.CacheErrorHandler
import org.springframework.context.annotation.Bean
import org.springframework.context.annotation.Configuration
import org.springframework.data.redis.cache.RedisCacheConfiguration
import org.springframework.data.redis.cache.RedisCacheManager
import org.springframework.data.redis.connection.RedisConnectionFactory
import org.springframework.data.redis.serializer.GenericJacksonJsonRedisSerializer
import org.springframework.data.redis.serializer.RedisSerializationContext.SerializationPair
import org.springframework.data.redis.serializer.StringRedisSerializer
import tools.jackson.databind.jsontype.BasicPolymorphicTypeValidator
import tools.jackson.module.kotlin.KotlinModule
import java.time.Duration

/**
 * Redis caching with a fail-open [CacheErrorHandler]: a Redis outage or serialization failure logs
 * a warning and falls through to the database instead of failing the request. Regions are named
 * constants with per-region TTLs. Never cache member records, scoped lists, PII or Sensitive data.
 * Tests set `spring.cache.type=simple`, which switches the Redis manager off.
 */
@Configuration
@EnableCaching
class CacheConfig : CachingConfigurer {
    @Bean
    @ConditionalOnProperty(name = ["spring.cache.type"], havingValue = "redis", matchIfMissing = true)
    fun redisCacheManager(connectionFactory: RedisConnectionFactory): RedisCacheManager {
        val typeValidator =
            BasicPolymorphicTypeValidator
                .builder()
                .allowIfSubType("com.john.sev_connect_backend.")
                .allowIfSubType("java.util.")
                .allowIfSubType("java.time.")
                .build()
        val serializer =
            GenericJacksonJsonRedisSerializer
                .builder()
                .enableDefaultTyping(typeValidator)
                .customize { it.addModule(KotlinModule.Builder().build()) }
                .build()

        val defaults =
            RedisCacheConfiguration
                .defaultCacheConfig()
                .entryTtl(Duration.ofMinutes(DEFAULT_TTL_MINUTES))
                .disableCachingNullValues()
                .serializeKeysWith(SerializationPair.fromSerializer(StringRedisSerializer()))
                .serializeValuesWith(SerializationPair.fromSerializer(serializer))

        return RedisCacheManager
            .builder(connectionFactory)
            .cacheDefaults(defaults)
            .withInitialCacheConfigurations(
                mapOf(
                    CACHE_REFERENCE_DATA to defaults.entryTtl(Duration.ofMinutes(REFERENCE_DATA_TTL_MINUTES)),
                    CACHE_ORG_CONFIG to defaults.entryTtl(Duration.ofMinutes(ORG_CONFIG_TTL_MINUTES)),
                ),
            ).build()
    }

    override fun errorHandler(): CacheErrorHandler = FailOpenCacheErrorHandler()

    /**
     * Cache errors degrade to direct database access, never a failed request. Only the exception
     * class and cache name reach warn (messages and keys can embed ids); the detail is at debug.
     */
    class FailOpenCacheErrorHandler : CacheErrorHandler {
        private val log = LoggerFactory.getLogger(javaClass)

        private fun report(
            operation: String,
            cache: Cache,
            exception: RuntimeException,
        ) {
            log.warn("Cache {} failed for [{}]: {}", operation, cache.name, exception.javaClass.simpleName)
            log.debug("Cache failure detail", exception)
        }

        override fun handleCacheGetError(
            exception: RuntimeException,
            cache: Cache,
            key: Any,
        ) = report("GET", cache, exception)

        override fun handleCachePutError(
            exception: RuntimeException,
            cache: Cache,
            key: Any,
            value: Any?,
        ) = report("PUT", cache, exception)

        override fun handleCacheEvictError(
            exception: RuntimeException,
            cache: Cache,
            key: Any,
        ) = report("EVICT", cache, exception)

        override fun handleCacheClearError(
            exception: RuntimeException,
            cache: Cache,
        ) = report("CLEAR", cache, exception)
    }

    companion object {
        const val CACHE_REFERENCE_DATA = "reference-data"
        const val CACHE_ORG_CONFIG = "org-config"
        private const val DEFAULT_TTL_MINUTES = 15L
        private const val REFERENCE_DATA_TTL_MINUTES = 60L
        private const val ORG_CONFIG_TTL_MINUTES = 30L
    }
}
