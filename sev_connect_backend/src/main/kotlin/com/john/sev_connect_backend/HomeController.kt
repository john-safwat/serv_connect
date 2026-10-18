package com.john.sev_connect_backend

import com.john.sev_connect_backend.common.i18n.MessageKeys
import com.john.sev_connect_backend.common.response.BaseResponseBody
import org.springframework.context.MessageSource
import org.springframework.core.env.Environment
import org.springframework.http.ResponseEntity
import org.springframework.web.bind.annotation.GetMapping
import org.springframework.web.bind.annotation.RestController
import java.util.Locale

/** Public landing endpoint; exposes the application name only. */
@RestController
class HomeController(
    private val environment: Environment,
    private val messageSource: MessageSource,
) {
    @GetMapping("/")
    fun home(locale: Locale): ResponseEntity<BaseResponseBody<Map<String, String>>> {
        val name = environment.getProperty("spring.application.name").orEmpty()
        val body =
            BaseResponseBody.success(
                mapOf("name" to name),
                messageSource.getMessage(MessageKeys.SUCCESS, null, "Success", locale).orEmpty(),
            )
        return BaseResponseBody.toResponseEntity(body)
    }
}
