# syntax=docker/dockerfile:1

# ---- Build stage ----
FROM eclipse-temurin:17-jdk-alpine AS build
WORKDIR /app

# Resolve dependencies in a cached layer before copying source, so an unchanged
# pom.xml reuses the cache across source-only rebuilds.
COPY .mvn/ .mvn/
COPY mvnw pom.xml ./
RUN ./mvnw -B dependency:go-offline

COPY src/ src/
RUN ./mvnw -B clean package -DskipTests

# ---- Runtime stage ----
FROM eclipse-temurin:17-jre-alpine AS runtime

# Run as a non-root user.
RUN addgroup -S spring && adduser -S spring -G spring
WORKDIR /app
RUN mkdir logs && chown spring:spring logs
COPY --from=build /app/target/*.jar app.jar
RUN chown spring:spring app.jar
USER spring

# No secret is baked in — supply DATABASE_URL, JWT_SECRET, REDIS_HOST, SMTP_* etc. at run time.
ENV SPRING_PROFILES_ACTIVE=prod
EXPOSE 8080

ENTRYPOINT ["java", "-jar", "/app/app.jar"]
