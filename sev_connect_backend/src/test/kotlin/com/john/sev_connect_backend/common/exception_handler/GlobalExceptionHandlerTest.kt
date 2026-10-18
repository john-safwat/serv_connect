package com.john.sev_connect_backend.common.exception_handler

import ch.qos.logback.classic.Level
import ch.qos.logback.classic.Logger
import ch.qos.logback.classic.spi.ILoggingEvent
import ch.qos.logback.core.read.ListAppender
import com.john.sev_connect_backend.common.config.LocalizationConfig
import com.john.sev_connect_backend.common.config.ValidationConfig
import org.hamcrest.Matchers.containsString
import org.hamcrest.Matchers.not
import org.junit.jupiter.api.Test
import org.slf4j.LoggerFactory
import org.springframework.beans.factory.annotation.Autowired
import org.springframework.boot.webmvc.test.autoconfigure.AutoConfigureMockMvc
import org.springframework.boot.webmvc.test.autoconfigure.WebMvcTest
import org.springframework.context.annotation.Import
import org.springframework.http.HttpHeaders
import org.springframework.http.MediaType
import org.springframework.test.context.ActiveProfiles
import org.springframework.test.web.servlet.MockHttpServletRequestDsl
import org.springframework.test.web.servlet.MockMvc
import org.springframework.test.web.servlet.get
import org.springframework.test.web.servlet.post
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNull
import kotlin.test.assertTrue

@WebMvcTest(ProbeController::class)
@ActiveProfiles("test")
@AutoConfigureMockMvc(addFilters = false)
@Import(GlobalExceptionHandler::class, LocalizationConfig::class, ValidationConfig::class)
class GlobalExceptionHandlerTest {
    @Autowired
    lateinit var mockMvc: MockMvc

    private fun postJson(
        body: String,
        language: String,
    ) = mockMvc.post("/test-probe/validate") {
        contentType = MediaType.APPLICATION_JSON
        header(HttpHeaders.ACCEPT_LANGUAGE, language)
        content = body
    }

    @Test
    fun `validation failure returns 400 with field errors in english`() {
        postJson("""{"name":"","count":1}""", "en").andExpect {
            status { isBadRequest() }
            jsonPath("$.code") { value(400) }
            jsonPath("$.message") { value("Validation error.") }
            jsonPath("$.errors[0].field") { value("name") }
            jsonPath("$.errors[0].message") { value("must not be blank") }
        }
    }

    @Test
    fun `validation failure is localized to arabic`() {
        postJson("""{"name":"","count":1}""", "ar").andExpect {
            status { isBadRequest() }
            jsonPath("$.message") { value("خطأ في التحقق من البيانات.") }
            jsonPath("$.errors[0].message") { value("يجب ألا يكون فارغًا") }
        }
    }

    @Test
    fun `size constraint interpolates parameters`() {
        postJson("""{"name":"toolongname","count":1}""", "en").andExpect {
            status { isBadRequest() }
            jsonPath("$.errors[0].message") { value("size must be between 0 and 5") }
        }
    }

    @Test
    fun `missing non-null field returns 400 naming the field`() {
        postJson("""{"name":"ok"}""", "en").andExpect {
            status { isBadRequest() }
            jsonPath("$.message") { value("The request is malformed.") }
            jsonPath("$.errors[0].field") { value("count") }
        }
    }

    @Test
    fun `malformed json returns 400 without leaking parser detail`() {
        postJson("{not json", "en").andExpect {
            status { isBadRequest() }
            jsonPath("$.message") { value("The request is malformed.") }
        }
    }

    @Test
    fun `entity not found returns 404 in both languages`() {
        mockMvc.get("/test-probe/not-found") { header(HttpHeaders.ACCEPT_LANGUAGE, "en") }.andExpect {
            status { isNotFound() }
            jsonPath("$.status") { value("NOT_FOUND") }
            jsonPath("$.message") { value("Resource not found.") }
        }
        mockMvc.get("/test-probe/not-found") { header(HttpHeaders.ACCEPT_LANGUAGE, "ar") }.andExpect {
            status { isNotFound() }
            jsonPath("$.message") { value("المورد غير موجود.") }
        }
    }

    @Test
    fun `already exists and stale version return 409`() {
        mockMvc.get("/test-probe/conflict").andExpect { status { isConflict() } }
        mockMvc.get("/test-probe/stale").andExpect { status { isConflict() } }
    }

    @Test
    fun `unexpected error returns 500 with a generic message and no internals`() {
        mockMvc.get("/test-probe/boom") { header(HttpHeaders.ACCEPT_LANGUAGE, "ar") }.andExpect {
            status { isInternalServerError() }
            jsonPath("$.message") { value("حدث خطأ غير متوقع.") }
            content { string(not(containsString("SELECT"))) }
        }
        mockMvc.get("/test-probe/boom").andExpect {
            jsonPath("$.message") { value("An unexpected error occurred.") }
            content { string(not(containsString("secret"))) }
        }
    }

    private fun expect(
        path: String,
        status: Int,
        message: String,
        language: String = "en",
        method: String = "GET",
        accept: String? = null,
        init: MockHttpServletRequestDsl.() -> Unit = {},
    ) {
        val result =
            when (method) {
                "POST" ->
                    mockMvc.post(path) {
                        header(HttpHeaders.ACCEPT_LANGUAGE, language)
                        accept?.let { header(HttpHeaders.ACCEPT, it) }
                        init()
                    }
                else ->
                    mockMvc.get(path) {
                        header(HttpHeaders.ACCEPT_LANGUAGE, language)
                        accept?.let { header(HttpHeaders.ACCEPT, it) }
                        init()
                    }
            }
        result.andExpect {
            status { isEqualTo(status) }
            jsonPath("$.code") { value(status) }
            jsonPath("$.message") { value(message) }
        }
    }

    @Test
    fun `business rule maps to 400 and conflict flavour to 409`() {
        expect("/test-probe/business", 400, "The request violates a business rule.")
        expect("/test-probe/business-conflict", 409, "The request violates a business rule.")
        expect("/test-probe/business", 400, "الطلب يخالف قاعدة من قواعد العمل.", "ar")
    }

    @Test
    fun `invalid credentials 401 and feature disabled 403`() {
        expect("/test-probe/credentials", 401, "Invalid credentials.")
        expect("/test-probe/feature", 403, "This feature is not enabled.")
        expect("/test-probe/feature", 403, "هذه الميزة غير مفعّلة.", "ar")
    }

    @Test
    fun `wrong method is 405 and unknown resource is 404`() {
        expect("/test-probe/not-found", 405, "This HTTP method is not supported for this resource.", method = "POST")
        expect("/test-probe/does-not-exist", 404, "Resource not found.")
    }

    @Test
    fun `bad or missing parameters and headers are 400`() {
        expect("/test-probe/param?n=abc", 400, "The request is malformed.")
        expect("/test-probe/param", 400, "The request is malformed.")
        expect("/test-probe/header", 400, "The request is malformed.")
        expect("/test-probe/method-validation?n=0", 400, "The request is malformed.")
        expect("/test-probe/constraint", 400, "The request is malformed.")
        expect("/test-probe/part", 400, "The request is malformed.")
    }

    @Test
    fun `unsupported media type is 415 and not acceptable is 406`() {
        expect(
            "/test-probe/consumes-json",
            415,
            "The request content type is not supported.",
            method = "POST",
        ) { contentType = MediaType.TEXT_PLAIN }
        expect(
            "/test-probe/consumes-json",
            415,
            "نوع محتوى الطلب غير مدعوم.",
            language = "ar",
            method = "POST",
        ) { contentType = MediaType.TEXT_PLAIN }
        expect("/test-probe/json-only", 406, "The requested response format is not supported.", accept = "application/xml")
    }

    @Test
    fun `optimistic lock is 409 stale version and integrity violation is 409 without row values`() {
        expect("/test-probe/optimistic", 409, "This record was changed by someone else. Refresh and try again.")
        expect("/test-probe/optimistic", 409, "تم تعديل هذا السجل بواسطة شخص آخر. حدّث الصفحة وحاول مرة أخرى.", "ar")
        expect("/test-probe/integrity", 409, "The request conflicts with existing data.")
        mockMvc.get("/test-probe/integrity").andExpect { content { string(not(containsString("person@example.test"))) } }
    }

    @Test
    fun `unexpected error log carries class and path but not the message or a stack trace at error level`() {
        val logger = LoggerFactory.getLogger(GlobalExceptionHandler::class.java) as Logger
        val appender = ListAppender<ILoggingEvent>().apply { start() }
        logger.addAppender(appender)
        try {
            mockMvc.get("/test-probe/boom")
        } finally {
            logger.detachAppender(appender)
        }
        val errors = appender.list.filter { it.level == Level.ERROR }
        assertEquals(1, errors.size)
        assertFalse(errors.single().formattedMessage.contains("secret internal detail"))
        assertNull(errors.single().throwableProxy)
        assertTrue(errors.single().formattedMessage.contains("/test-probe/boom"))
    }
}
