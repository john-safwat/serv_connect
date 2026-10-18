package com.john.sev_connect_backend.common.base

import com.john.sev_connect_backend.TestcontainersConfiguration
import org.junit.jupiter.api.Test
import org.springframework.beans.factory.annotation.Autowired
import org.springframework.boot.test.context.SpringBootTest
import org.springframework.context.annotation.Import
import org.springframework.test.context.ActiveProfiles
import org.springframework.transaction.support.TransactionTemplate
import java.time.Instant
import java.util.UUID
import kotlin.test.assertEquals
import kotlin.test.assertNotEquals
import kotlin.test.assertNotNull
import kotlin.test.assertTrue

@SpringBootTest
@ActiveProfiles("test")
@Import(TestcontainersConfiguration::class)
class SyncableEntityIntegrationTest {
    @Autowired
    lateinit var repository: SyncProbeRepository

    @Autowired
    lateinit var tx: TransactionTemplate

    private val orgId = UUID.randomUUID()

    private fun <T> inTx(block: () -> T): T = checkNotNull(tx.execute { block() })

    @Test
    fun `changeSeq increases on insert and update and version bumps`() {
        val id = UUID.randomUUID()
        val saved = inTx { repository.saveAndFlush(SyncProbe(id, orgId, "first")) }
        assertEquals(0L, saved.version)
        assertTrue(saved.changeSeq > 0)

        val second = inTx { repository.saveAndFlush(SyncProbe(UUID.randomUUID(), orgId, "other")) }
        assertTrue(second.changeSeq > saved.changeSeq)

        val updated =
            inTx {
                val probe = repository.findById(id).orElseThrow()
                probe.label = "changed"
                repository.saveAndFlush(probe)
            }
        assertEquals(1L, updated.version)
        assertTrue(updated.changeSeq > second.changeSeq)
    }

    @Test
    fun `unchanged entity does not consume a new changeSeq`() {
        val id = UUID.randomUUID()
        val saved = inTx { repository.saveAndFlush(SyncProbe(id, orgId, "same")) }
        val reloaded = inTx { repository.saveAndFlush(repository.findById(id).orElseThrow()) }
        assertEquals(saved.changeSeq, reloaded.changeSeq)
        assertEquals(0L, reloaded.version)
    }

    @Test
    fun `tombstoning is an update that gets a new changeSeq`() {
        val id = UUID.randomUUID()
        val saved = inTx { repository.saveAndFlush(SyncProbe(id, orgId, "gone")) }
        val tombstoned =
            inTx {
                val probe = repository.findById(id).orElseThrow()
                probe.deletedAt = Instant.now()
                repository.saveAndFlush(probe)
            }
        assertNotNull(tombstoned.deletedAt)
        assertNotEquals(saved.changeSeq, tombstoned.changeSeq)
    }

    @Test
    fun `audit columns are filled with the system user when unauthenticated`() {
        val saved = inTx { repository.saveAndFlush(SyncProbe(UUID.randomUUID(), orgId, "audited")) }
        assertEquals(BaseEntity.SYSTEM_USER_ID, saved.createdBy)
        assertEquals(BaseEntity.SYSTEM_USER_ID, saved.updatedBy)
        assertTrue(saved.createdAt.isAfter(Instant.EPOCH))
    }
}
