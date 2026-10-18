package com.john.sev_connect_backend

import org.junit.jupiter.api.Test
import org.springframework.beans.factory.annotation.Autowired
import org.springframework.boot.test.context.SpringBootTest
import org.springframework.context.annotation.Import
import org.springframework.jdbc.core.JdbcTemplate
import org.springframework.test.context.ActiveProfiles
import kotlin.test.assertEquals

@SpringBootTest
@ActiveProfiles("test")
@Import(TestcontainersConfiguration::class)
class SevConnectBackendApplicationTests {
    @Autowired
    lateinit var jdbcTemplate: JdbcTemplate

    @Test
    fun contextLoadsAndFlywayAppliesV1() {
        val version =
            jdbcTemplate.queryForObject(
                "select version from flyway_schema_history where success order by installed_rank limit 1",
                String::class.java,
            )
        assertEquals("1", version)
        val sequences =
            jdbcTemplate.queryForObject(
                "select count(*) from pg_sequences where sequencename = 'sync_change_seq'",
                Int::class.java,
            )
        assertEquals(1, sequences)
    }
}
