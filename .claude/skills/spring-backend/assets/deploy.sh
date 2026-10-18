#!/usr/bin/env bash
# Build the app image, push it to a registry (Docker Hub), then redeploy on the VPS over SSH.
#
# Required env vars:
#   DOCKERHUB_USERNAME   registry account/org that owns the image
#   DOCKERHUB_TOKEN      registry access token (never a raw account password)
#
# Optional overrides (defaults shown):
#   IMAGE=<user>/<app>            SSH_TARGET=root@<host>
#   REMOTE_ENV_PATH=/root/app/.env  CONTAINER_NAME=app
#   PORT=8080                     PLATFORM=linux/amd64   DOCKER_NETWORK=app-net
#
# Usage: ./scripts/deploy.sh

set -euo pipefail

IMAGE="${IMAGE:-youruser/app}"
TAG="latest"
SSH_TARGET="${SSH_TARGET:-root@your.vps.host}"
REMOTE_ENV_PATH="${REMOTE_ENV_PATH:-/root/app/.env}"
CONTAINER_NAME="${CONTAINER_NAME:-app}"
PORT="${PORT:-8080}"
# Always amd64: Docker Desktop on Apple Silicon otherwise builds an arm64 image a typical VPS can't run.
PLATFORM="${PLATFORM:-linux/amd64}"
# Shared bridge network so the app reaches sibling containers (e.g. Redis) by name.
DOCKER_NETWORK="${DOCKER_NETWORK:-app-net}"

if [[ -z "${DOCKERHUB_USERNAME:-}" || -z "${DOCKERHUB_TOKEN:-}" ]]; then
  echo "Error: DOCKERHUB_USERNAME and DOCKERHUB_TOKEN must be set in the environment." >&2
  exit 1
fi

for bin in docker ssh; do
  if ! command -v "$bin" >/dev/null 2>&1; then
    echo "Error: required command '$bin' not found on PATH." >&2
    exit 1
  fi
done

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

echo "==> Building ${IMAGE}:${TAG} for ${PLATFORM}"
docker build --platform "${PLATFORM}" -t "${IMAGE}:${TAG}" .

echo "==> Logging in to registry as ${DOCKERHUB_USERNAME}"
echo "${DOCKERHUB_TOKEN}" | docker login -u "${DOCKERHUB_USERNAME}" --password-stdin

echo "==> Pushing ${IMAGE}:${TAG}"
docker push "${IMAGE}:${TAG}"

docker logout >/dev/null 2>&1 || true

echo "==> Deploying to ${SSH_TARGET}"
ssh "${SSH_TARGET}" IMAGE="${IMAGE}" TAG="${TAG}" CONTAINER_NAME="${CONTAINER_NAME}" \
  REMOTE_ENV_PATH="${REMOTE_ENV_PATH}" PORT="${PORT}" DOCKER_NETWORK="${DOCKER_NETWORK}" bash -s <<'REMOTE_SCRIPT'
set -euo pipefail

echo "----> Pulling ${IMAGE}:${TAG}"
docker pull "${IMAGE}:${TAG}"

if docker ps -a --format '{{.Names}}' | grep -Fxq "${CONTAINER_NAME}"; then
  echo "----> Stopping and removing existing container ${CONTAINER_NAME}"
  docker stop "${CONTAINER_NAME}" >/dev/null
  docker rm "${CONTAINER_NAME}" >/dev/null
fi

if ! docker network inspect "${DOCKER_NETWORK}" >/dev/null 2>&1; then
  echo "----> Creating docker network ${DOCKER_NETWORK}"
  docker network create "${DOCKER_NETWORK}" >/dev/null
fi

echo "----> Starting ${CONTAINER_NAME} from ${IMAGE}:${TAG}"
docker run -d \
  --name "${CONTAINER_NAME}" \
  --restart unless-stopped \
  --network "${DOCKER_NETWORK}" \
  -p "${PORT}:${PORT}" \
  --env-file "${REMOTE_ENV_PATH}" \
  "${IMAGE}:${TAG}"

echo "----> Pruning dangling images"
docker image prune -f >/dev/null

echo "----> Container status:"
docker ps --filter "name=${CONTAINER_NAME}" --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'

if [[ "$(docker inspect -f '{{.State.Running}}' "${CONTAINER_NAME}")" != "true" ]]; then
  echo "Error: ${CONTAINER_NAME} is not running after deploy." >&2
  exit 1
fi
REMOTE_SCRIPT

echo "==> Deploy complete: ${IMAGE}:${TAG} is running on ${SSH_TARGET} as ${CONTAINER_NAME}"
