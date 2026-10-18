package com.john.sev_connect_backend.common.config

import com.john.sev_connect_backend.TestcontainersConfiguration
import org.junit.jupiter.api.Test
import org.springframework.beans.factory.annotation.Autowired
import org.springframework.boot.test.context.SpringBootTest
import org.springframework.boot.test.context.TestConfiguration
import org.springframework.boot.testcontainers.service.connection.ServiceConnection
import org.springframework.cache.CacheManager
import org.springframework.context.annotation.Bean
import org.springframework.context.annotation.Import
import org.springframework.data.redis.cache.RedisCacheManager
import org.springframework.data.redis.core.StringRedisTemplate
import org.springframework.test.context.ActiveProfiles
import org.testcontainers.containers.GenericContainer
import java.time.Duration
import kotlin.test.assertEquals
import kotlin.test.assertIs
import kotlin.test.assertTrue

/** Proves CacheConfig's manager (not Boot's default) is the active one when Redis caching is on. */
@SpringBootTest(properties = ["spring.cache.type=redis", "management.health.redis.enabled=true"])
@ActiveProfiles("test")
@Import(TestcontainersConfiguration::class, CacheManagerWiringTest.RedisContainerConfig::class)
class CacheManagerWiringTest {
    data class Sample(
        val name: String,
        val count: Int,
    )

    @TestConfiguration(proxyBeanMethods = false)
    class RedisContainerConfig {
        @Bean
        @ServiceConnection(name = "redis")
        fun redis(): GenericContainer<*> = GenericContainer("redis:7").withExposedPorts(6379)
    }

    @Autowired
    lateinit var cacheManager: CacheManager

    @Autowired
    lateinit var redisTemplate: StringRedisTemplate

    @Test
    fun `active cache manager uses the configured ttls`() {
        val manager = assertIs<RedisCacheManager>(cacheManager)
        val configs = manager.cacheConfigurations
        assertEquals(
            Duration.ofMinutes(60),
            checkNotNull(configs[CacheConfig.CACHE_REFERENCE_DATA]).ttlFunction.getTimeToLive("k", "v"),
        )
        assertEquals(
            Duration.ofMinutes(30),
            checkNotNull(configs[CacheConfig.CACHE_ORG_CONFIG]).ttlFunction.getTimeToLive("k", "v"),
        )
    }

    @Test
    fun `values are stored as json and round trip through the kotlin module`() {
        val cache = checkNotNull(cacheManager.getCache(CacheConfig.CACHE_REFERENCE_DATA))
        cache.put("sample", Sample("pack", 3))
        assertEquals(Sample("pack", 3), cache.get("sample", Sample::class.java))
        val raw = checkNotNull(redisTemplate.opsForValue().get("${CacheConfig.CACHE_REFERENCE_DATA}::sample"))
        assertTrue(raw.trimStart().startsWith("{"), "expected a JSON document, was: $raw")
    }
}
