package com.john.sev_connect_backend.common.response

import org.springframework.data.domain.Page

/** Page-shaped payload for list endpoints; carried as `data` inside a [BaseResponseBody.Success]. */
data class PageResponse<T>(
    val content: List<T>,
    val page: Int,
    val size: Int,
    val totalElements: Long,
    val totalPages: Int,
) {
    companion object {
        fun <S : Any, T> of(
            page: Page<S>,
            transform: (S) -> T,
        ): PageResponse<T> =
            PageResponse(
                content = page.content.map(transform),
                page = page.number,
                size = page.size,
                totalElements = page.totalElements,
                totalPages = page.totalPages,
            )
    }
}
