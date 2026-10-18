package com.john.sev_connect_backend.common.security

import jakarta.servlet.http.HttpServletRequest
import jakarta.servlet.http.HttpServletResponse
import org.springframework.beans.factory.annotation.Qualifier
import org.springframework.security.core.AuthenticationException
import org.springframework.security.web.AuthenticationEntryPoint
import org.springframework.stereotype.Component
import org.springframework.web.servlet.HandlerExceptionResolver

/** Routes filter-level 401s through the global handler so they use the `BaseResponseBody.Fail` envelope. */
@Component
class RestAuthenticationEntryPoint(
    @param:Qualifier("handlerExceptionResolver") private val resolver: HandlerExceptionResolver,
) : AuthenticationEntryPoint {
    override fun commence(
        request: HttpServletRequest,
        response: HttpServletResponse,
        authException: AuthenticationException,
    ) {
        resolver.resolveException(request, response, null, authException)
    }
}
