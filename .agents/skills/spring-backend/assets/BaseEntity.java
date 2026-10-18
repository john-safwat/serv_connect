package com.example.app.common.base;

import jakarta.persistence.Column;
import jakarta.persistence.EntityListeners;
import jakarta.persistence.MappedSuperclass;
import java.time.Instant;
import lombok.AccessLevel;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import org.springframework.data.annotation.CreatedBy;
import org.springframework.data.annotation.CreatedDate;
import org.springframework.data.annotation.LastModifiedBy;
import org.springframework.data.annotation.LastModifiedDate;
import org.springframework.data.jpa.domain.support.AuditingEntityListener;

/**
 * {@link MappedSuperclass} carrying the audit columns onto every {@code @Entity} that extends it.
 * {@link AuditingEntityListener} (enabled via {@code @EnableJpaAuditing(auditorAwareRef =
 * "auditorAwareImpl")} on the application class) populates the columns automatically, so each
 * feature table gains the same audit trail for free.
 *
 * <p>Standard entity Lombok shape: protected no-arg constructor (Hibernate needs it), getters and
 * setters. Never put {@code @Data} on an entity. Identity equality on subclasses should be based on
 * the database id only.
 */
@Getter
@Setter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
@MappedSuperclass
@EntityListeners(AuditingEntityListener.class)
public abstract class BaseEntity {

    @CreatedDate
    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt;

    @CreatedBy
    @Column(name = "created_by", updatable = false)
    private String createdBy;

    @LastModifiedDate
    @Column(name = "updated_at")
    private Instant updatedAt;

    @LastModifiedBy
    @Column(name = "updated_by")
    private String updatedBy;
}
