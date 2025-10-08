#!/usr/bin/env bash
set -euo pipefail

APP_DIR="/opt/shvirtd-example"
REPO_URL="https://github.com/zis-git/shvirtd-example-python.git"
BRANCH="feature/docker-basics"

echo "[i] Preparing ${APP_DIR}"
mkdir -p "${APP_DIR}"

echo "[i] Sync repo → ${APP_DIR}"
if [ -d "${APP_DIR}/.git" ]; then
  git -C "${APP_DIR}" fetch --all --prune
  git -C "${APP_DIR}" checkout "${BRANCH}"
  git -C "${APP_DIR}" reset --hard "origin/${BRANCH}"
else
  git clone --branch "${BRANCH}" --depth 1 "${REPO_URL}" "${APP_DIR}"
fi

cd "${APP_DIR}"

# safety: Docker & Compose v2
if ! command -v docker >/dev/null 2>&1; then
  echo "[!] Docker is not installed" >&2; exit 1
fi
if ! docker compose version >/dev/null 2>&1; then
  echo "[!] Docker Compose v2 is not available" >&2; exit 1
fi

echo "[i] Restart stack"
docker compose down -v || true
docker compose up -d

echo "[i] Waiting MySQL to become healthy..."
for i in {1..60}; do
  state="$(docker inspect -f '{{.State.Health.Status}}' db 2>/dev/null || true)"
  [ "$state" = "healthy" ] && break
  sleep 2
done

echo "[i] Health check http://127.0.0.1:8090/"
curl -sS -w "\nHTTP %{http_code}\n" http://127.0.0.1:8090/ || true

echo "[✓] Deploy complete."
