package com.john.sev_connect_backend.common.security

import jakarta.servlet.http.HttpServletRequest
import jakarta.servlet.http.HttpServletResponse
import org.springframework.beans.factory.annotation.Qualifier
import org.springframework.security.access.AccessDeniedException
import org.springframework.security.web.access.AccessDeniedHandler
import org.springframework.stereotype.Component
import org.springframework.web.servlet.HandlerExceptionResolver

/** Routes filter-level 403s through the global handler so they use the `BaseResponseBody.Fail` envelope. */
@Component
class RestAccessDeniedHandler(
    @param:Qualifier("handlerExceptionResolver") private val resolver: HandlerExceptionResolver,
) : AccessDeniedHandler {
    override fun handle(
        request: HttpServletRequest,
        response: HttpServletResponse,
        accessDeniedException: AccessDeniedException,
    ) {
        resolver.resolveException(request, response, null, accessDeniedException)
    }
}
