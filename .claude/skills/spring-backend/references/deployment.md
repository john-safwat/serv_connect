# Deployment (Docker / VPS)

## Two-stage Docker image

See `assets/Dockerfile`. Shape:

1. **Build stage** — `eclipse-temurin:17-jdk-alpine`. Copy `.mvn/`, `mvnw`, `pom.xml`, run
   `./mvnw -B dependency:go-offline` **before** copying `src/` so an unchanged `pom.xml` reuses
   Docker's dependency layer across source-only rebuilds; then `./mvnw -B clean package -DskipTests`.
2. **Runtime stage** — `eclipse-temurin:17-jre-alpine`. Copy only the built jar, create and run as a
   **non-root** `spring` user, create a writable `logs/` dir, default `SPRING_PROFILES_ACTIVE=prod`,
   `EXPOSE` the app port (match `server.port`), `ENTRYPOINT ["java","-jar","/app/app.jar"]`.

- **No secret is baked into the image.** `DATABASE_URL`, `DATABASE_USERNAME`, `DATABASE_PASSWORD`,
  `REDIS_HOST`, `JWT_SECRET`, `SMTP_*`, etc. are supplied as container env vars at run time. See
  `assets/.env.example` for the full list.
- `.dockerignore` excludes `target/`, `logs/`, `.git/`, `.idea/`, docs, and env files from the build
  context.

## Deploy script (`scripts/deploy.sh`)

See `assets/deploy.sh`. It automates: build the image locally → push to the registry (Docker Hub) →
SSH to the VPS to pull and restart the container. Run from the repo root:

```bash
export DOCKERHUB_USERNAME=<user>
export DOCKERHUB_TOKEN=<access-token>
./scripts/deploy.sh
```

Key properties to preserve when adapting:

- `DOCKERHUB_USERNAME` and `DOCKERHUB_TOKEN` are **required** (fail fast if missing) and never
  written to disk or logged — the token is piped into `docker login --password-stdin`, and
  `docker logout` runs after the push.
- `IMAGE`, `SSH_TARGET`, `REMOTE_ENV_PATH`, `CONTAINER_NAME`, `PORT`, `PLATFORM`, `DOCKER_NETWORK`
  are overridable env vars with sensible defaults.
- **Always build `linux/amd64`** (`PLATFORM` default) regardless of host arch — Docker Desktop on
  Apple Silicon otherwise produces an arm64 image a typical x86 VPS can't run.
- On the server the script pulls the image, stops/removes any existing container, ensures a
  user-defined bridge network exists (so the app reaches Redis by container name), starts the new
  container with `--restart unless-stopped --env-file <remote .env> -p PORT:PORT --network …`,
  prunes dangling images, and exits non-zero if the container isn't running afterward.
- The **remote `.env` is managed manually on the VPS** — the script never creates, edits, or
  transfers it. If the registry repo is public the VPS needs no registry credentials to pull; only
  the machine running the script needs push credentials.

## Config-as-env checklist

- Every credential/URL/secret is a `${ENV_VAR}` placeholder in `application-*.properties`, never
  hardcoded.
- `.env.example` documents every required variable with fake values and is committed; the real
  `.env` is gitignored.
- `compose.yaml` (local Postgres + Redis) is for local development only — never put a value in it
  that also protects staging/production data.
