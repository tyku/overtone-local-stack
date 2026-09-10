#!/bin/sh
set -eu

component="${1:-}"
image="${2:-}"
if [ -z "$component" ] || [ -z "$image" ]; then
  echo "Usage: deploy-overtone.sh <backend|frontend> <immutable-image>" >&2
  exit 2
fi

STACK_DIR="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
compose() {
  docker compose --project-directory "$STACK_DIR" -f "$STACK_DIR/compose.yaml" "$@"
}

docker pull "$image"
revision="$(
  docker image inspect --format '{{ index .Config.Labels "org.opencontainers.image.revision" }}' \
    "$image"
)"
if [ -z "$revision" ]; then
  echo "Image has no source revision label: $image" >&2
  exit 1
fi

case "$component" in
  backend)
    OVERTONE_BACKEND_IMAGE="$image" compose \
      up --detach --no-build --no-deps --wait api worker
    compose exec -T nginx nginx -s reload
    compose exec -T nginx sh /usr/local/bin/overtone-healthcheck
    ;;
  frontend)
    OVERTONE_FRONTEND_IMAGE="$image" compose \
      run --rm --no-deps frontend-assets
    compose exec -T nginx sh /usr/local/bin/overtone-healthcheck
    ;;
  *)
    echo "Unknown component: $component" >&2
    exit 2
    ;;
esac

echo "Deployed $component revision $revision"
