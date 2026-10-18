package com.john.sev_connect_backend.common.exception_handler

import com.john.sev_connect_backend.common.exception.AlreadyExistsException
import com.john.sev_connect_backend.common.exception.BusinessRuleException
import com.john.sev_connect_backend.common.exception.EntityNotFoundException
import com.john.sev_connect_backend.common.exception.FeatureDisabledException
import com.john.sev_connect_backend.common.exception.InvalidCredentialsException
import com.john.sev_connect_backend.common.exception.StaleVersionException
import jakarta.validation.ConstraintViolationException
import jakarta.validation.Valid
import jakarta.validation.constraints.Min
import jakarta.validation.constraints.NotBlank
import jakarta.validation.constraints.Size
import org.springframework.dao.DataIntegrityViolationException
import org.springframework.orm.ObjectOptimisticLockingFailureException
import org.springframework.security.access.prepost.PreAuthorize
import org.springframework.web.bind.annotation.GetMapping
import org.springframework.web.bind.annotation.PostMapping
import org.springframework.web.bind.annotation.RequestBody
import org.springframework.web.bind.annotation.RequestHeader
import org.springframework.web.bind.annotation.RequestParam
import org.springframework.web.bind.annotation.RestController
import org.springframework.web.multipart.support.MissingServletRequestPartException

data class ProbeRequest(
    @field:NotBlank
    @field:Size(max = 5)
    val name: String?,
    val count: Int,
)

/** Test-only controller that throws each exception type so the global handler can be asserted. */
@RestController
class ProbeController {
    @PostMapping("/test-probe/validate")
    fun validate(
        @Valid @RequestBody request: ProbeRequest,
    ): String = request.name.orEmpty()

    @GetMapping("/test-probe/not-found")
    fun notFound(): Nothing = throw EntityNotFoundException()

    @GetMapping("/test-probe/conflict")
    fun conflict(): Nothing = throw AlreadyExistsException()

    @GetMapping("/test-probe/stale")
    fun stale(): Nothing = throw StaleVersionException()

    @GetMapping("/test-probe/boom")
    fun boom(): Nothing = error("secret internal detail SELECT * FROM members")

    @GetMapping("/test-probe/business")
    fun business(): Nothing = throw BusinessRuleException()

    @GetMapping("/test-probe/business-conflict")
    fun businessConflict(): Nothing = throw BusinessRuleException(conflict = true)

    @GetMapping("/test-probe/credentials")
    fun credentials(): Nothing = throw InvalidCredentialsException()

    @GetMapping("/test-probe/feature")
    fun feature(): Nothing = throw FeatureDisabledException()

    @GetMapping("/test-probe/param")
    fun param(
        @RequestParam n: Int,
    ): Int = n

    @GetMapping("/test-probe/header")
    fun header(
        @RequestHeader("X-Required") value: String,
    ): String = value

    @GetMapping("/test-probe/method-validation")
    fun methodValidation(
        @RequestParam @Min(1) n: Int,
    ): Int = n

    @GetMapping("/test-probe/constraint")
    fun constraint(): Nothing = throw ConstraintViolationException("detail", emptySet())

    @GetMapping("/test-probe/part")
    fun part(): Nothing = throw MissingServletRequestPartException("file")

    @GetMapping("/test-probe/optimistic")
    fun optimistic(): Nothing = throw ObjectOptimisticLockingFailureException(String::class.java, "id")

    @GetMapping("/test-probe/integrity")
    fun integrity(): Nothing = throw DataIntegrityViolationException("Key (email)=(person@example.test) already exists")

    @GetMapping("/test-probe/json-only", produces = ["application/json"])
    fun jsonOnly(): String = "ok"

    @PostMapping("/test-probe/consumes-json", consumes = ["application/json"])
    fun consumesJson(): String = "ok"

    @GetMapping("/test-probe/denied")
    @PreAuthorize("denyAll()")
    fun denied(): String = "never"
}
