package com.john.sev_connect_backend.common.security

import com.john.sev_connect_backend.TestcontainersConfiguration
import org.junit.jupiter.api.Test
import org.springframework.beans.factory.annotation.Autowired
import org.springframework.boot.test.context.SpringBootTest
import org.springframework.boot.webmvc.test.autoconfigure.AutoConfigureMockMvc
import org.springframework.context.annotation.Import
import org.springframework.http.HttpHeaders
import org.springframework.http.MediaType
import org.springframework.security.test.context.support.WithMockUser
import org.springframework.test.context.ActiveProfiles
import org.springframework.test.web.servlet.MockMvc
import org.springframework.test.web.servlet.get
import org.springframework.test.web.servlet.options

@SpringBootTest
@ActiveProfiles("test")
@AutoConfigureMockMvc
@Import(TestcontainersConfiguration::class)
class SecurityConfigTest {
    @Autowired
    lateinit var mockMvc: MockMvc

    @Test
    fun `landing page is public and returns the envelope`() {
        mockMvc.get("/").andExpect {
            status { isOk() }
            jsonPath("$.code") { value(200) }
            jsonPath("$.data.name") { value("sev_connect_backend") }
        }
    }

    @Test
    fun `health is public and up`() {
        mockMvc.get("/actuator/health").andExpect {
            status { isOk() }
            jsonPath("$.status") { value("UP") }
        }
    }

    @Test
    fun `unknown path returns the 401 envelope in english`() {
        mockMvc.get("/api/v1/anything").andExpect {
            status { isUnauthorized() }
            jsonPath("$.code") { value(401) }
            jsonPath("$.message") { value("Authentication is required or has failed.") }
        }
    }

    @Test
    fun `unauthenticated response is localized to arabic`() {
        mockMvc.get("/test-probe/not-found") { header(HttpHeaders.ACCEPT_LANGUAGE, "ar") }.andExpect {
            status { isUnauthorized() }
            jsonPath("$.message") { value("المصادقة مطلوبة أو فشلت.") }
        }
    }

    @Test
    fun `non-public actuator endpoints are not exposed`() {
        mockMvc.get("/actuator/env").andExpect { status { isUnauthorized() } }
    }

    @Test
    fun `correlation id is generated and echoed`() {
        mockMvc.get("/").andExpect { header { exists("X-Correlation-Id") } }
    }

    @Test
    fun `forged correlation id is replaced`() {
        mockMvc
            .get("/") { header("X-Correlation-Id", "evil\nlog-line") }
            .andExpect { header { string("X-Correlation-Id", org.hamcrest.Matchers.not("evil\nlog-line")) } }
    }

    @Test
    fun `cors preflight allows the configured dashboard origin only`() {
        mockMvc
            .options("/api/v1/anything") {
                header(HttpHeaders.ORIGIN, "http://localhost:5173")
                header(HttpHeaders.ACCESS_CONTROL_REQUEST_METHOD, "GET")
            }.andExpect { header { string(HttpHeaders.ACCESS_CONTROL_ALLOW_ORIGIN, "http://localhost:5173") } }
        mockMvc
            .options("/api/v1/anything") {
                header(HttpHeaders.ORIGIN, "http://evil.example")
                header(HttpHeaders.ACCESS_CONTROL_REQUEST_METHOD, "GET")
            }.andExpect { status { isForbidden() } }
    }

    @Test
    @WithMockUser
    fun `authenticated but denied caller gets the 403 envelope in english`() {
        mockMvc.get("/test-probe/denied").andExpect {
            status { isForbidden() }
            jsonPath("$.code") { value(403) }
            jsonPath("$.message") { value("Access denied: you do not have permission to access this resource.") }
        }
    }

    @Test
    @WithMockUser
    fun `authenticated but denied caller gets the 403 envelope in arabic`() {
        mockMvc.get("/test-probe/denied") { header(HttpHeaders.ACCEPT_LANGUAGE, "ar") }.andExpect {
            status { isForbidden() }
            jsonPath("$.message") { value("تم رفض الوصول: ليس لديك صلاحية للوصول إلى هذا المورد.") }
        }
    }

    @Test
    fun `401 is json with no www-authenticate challenge`() {
        mockMvc.get("/api/v1/anything").andExpect {
            status { isUnauthorized() }
            header { doesNotExist(HttpHeaders.WWW_AUTHENTICATE) }
            content { contentTypeCompatibleWith(MediaType.APPLICATION_JSON) }
        }
    }
}
