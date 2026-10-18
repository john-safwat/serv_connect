package com.john.sev_connect_backend.common.config

import org.springframework.cache.Cache
import org.springframework.cache.CacheManager
import org.springframework.cache.annotation.Cacheable
import org.springframework.cache.annotation.CachingConfigurer
import org.springframework.cache.annotation.EnableCaching
import org.springframework.cache.interceptor.CacheErrorHandler
import org.springframework.context.annotation.AnnotationConfigApplicationContext
import org.springframework.context.annotation.Bean
import org.springframework.context.annotation.Configuration
import java.util.concurrent.atomic.AtomicInteger
import kotlin.test.Test
import kotlin.test.assertEquals

class CacheConfigTest {
    open class Lookup {
        open val calls = AtomicInteger()

        @Cacheable("broken")
        open fun find(id: Int): String {
            calls.incrementAndGet()
            return "value-$id"
        }
    }

    /** A cache whose every operation fails, as during a Redis outage. */
    class BrokenCache : Cache {
        override fun getName() = "broken"

        override fun getNativeCache(): Any = this

        override fun get(key: Any): Cache.ValueWrapper? = throw IllegalStateException("redis down")

        override fun <T : Any> get(
            key: Any,
            type: Class<T>?,
        ): T? = throw IllegalStateException("redis down")

        override fun <T : Any> get(
            key: Any,
            valueLoader: java.util.concurrent.Callable<T>,
        ): T? = throw IllegalStateException("redis down")

        override fun put(
            key: Any,
            value: Any?,
        ): Unit = throw IllegalStateException("redis down")

        override fun evict(key: Any): Unit = throw IllegalStateException("redis down")

        override fun clear(): Unit = throw IllegalStateException("redis down")
    }

    @Configuration
    @EnableCaching
    class TestCaching : CachingConfigurer {
        @Bean
        fun lookup() = Lookup()

        override fun cacheManager(): CacheManager =
            object : CacheManager {
                override fun getCache(name: String): Cache = BrokenCache()

                override fun getCacheNames() = listOf("broken")
            }

        override fun errorHandler(): CacheErrorHandler = CacheConfig().errorHandler()
    }

    @Test
    fun `redis failures fall through to the real method instead of failing`() {
        AnnotationConfigApplicationContext(TestCaching::class.java).use { context ->
            val lookup = context.getBean(Lookup::class.java)
            assertEquals("value-1", lookup.find(1))
            assertEquals("value-1", lookup.find(1))
            assertEquals(2, lookup.calls.get())
        }
    }
}
