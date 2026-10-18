# ---- Build stage ----
FROM eclipse-temurin:25-jdk-alpine AS build
WORKDIR /app

# Resolve dependencies in a cached layer before copying source.
COPY gradlew settings.gradle build.gradle ./
COPY gradle/ gradle/
RUN ./gradlew --no-daemon dependencies > /dev/null

COPY src/main/ src/main/
RUN ./gradlew --no-daemon bootJar -x test

# ---- Runtime stage ----
FROM eclipse-temurin:25-jre-alpine AS runtime

# Run as a non-root user.
RUN addgroup -S spring && adduser -S spring -G spring
WORKDIR /app
RUN mkdir logs && chown spring:spring logs
COPY --from=build /app/build/libs/*.jar app.jar
RUN chown spring:spring app.jar
USER spring

# No secret is baked in: supply DATABASE_URL, DATABASE_USERNAME, DATABASE_PASSWORD, REDIS_*, CORS_ALLOWED_ORIGINS
# (and later JWT_SECRET etc.) at run time. The prod profile fails fast when one is missing.
ENV SPRING_PROFILES_ACTIVE=prod
EXPOSE 8080

ENTRYPOINT ["java", "-jar", "/app/app.jar"]
