#!/bin/sh
set -eu

SMOKE_FRONTEND_PORT="${SMOKE_FRONTEND_PORT:-18080}"
SMOKE_API_PORT="${SMOKE_API_PORT:-18081}"
export SMOKE_FRONTEND_PORT SMOKE_API_PORT
STACK_DIR="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
FRONTEND_DIR="$(CDPATH= cd -- "$STACK_DIR/../overtone/frontend" && pwd)"

compose() {
  docker compose -p overtone-smoke --project-directory "$STACK_DIR" \
    -f "$STACK_DIR/compose.smoke.yaml" "$@"
}

cleanup() {
  compose down --volumes --remove-orphans
}
trap cleanup EXIT INT TERM

compose up --build --detach --wait

cd "$FRONTEND_DIR"
STACK_BASE_URL="http://127.0.0.1:${SMOKE_FRONTEND_PORT}" \
STACK_API_URL="http://127.0.0.1:${SMOKE_API_PORT}" \
npm run test:stack
