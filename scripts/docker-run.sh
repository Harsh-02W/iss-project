#!/bin/bash
set -e
set -o pipefail

# ── Colors ────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

info()    { echo -e "${CYAN}[INFO]${NC}  $1"; }
success() { echo -e "${GREEN}[OK]${NC}    $1"; }
warn()    { echo -e "${YELLOW}[WARN]${NC}  $1"; }
error()   { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

# ── Config ────────────────────────────────────────────────
IMAGE_NAME="iss-tracker:latest"
CONTAINER_NAME="iss-tracker-app"
PORT=$(grep -E '^FLASK_PORT=' .env 2>/dev/null | cut -d= -f2 | tr -d ' ')
PORT=${PORT:-5000}

echo -e "${BOLD}"
echo "  ╔══════════════════════════════════╗"
echo "  ║     ISS Tracker — Docker Run     ║"
echo "  ╚══════════════════════════════════╝"
echo -e "${NC}"

# ── Pre-checks ────────────────────────────────────────────
command -v docker &>/dev/null || error "Docker not found"
[ ! -f ".env" ] && error ".env file not found — secrets won't be passed to container"

# Check image exists
docker image inspect "$IMAGE_NAME" &>/dev/null || \
    error "Image ${IMAGE_NAME} not found. Run: bash scripts/docker-build.sh"

# ── Stop existing container ───────────────────────────────
if docker ps -a --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
    info "Stopping existing container: ${CONTAINER_NAME}"
    docker stop "$CONTAINER_NAME" &>/dev/null || true
    docker rm   "$CONTAINER_NAME" &>/dev/null || true
    success "Old container removed"
fi

# ── Run container ─────────────────────────────────────────
info "Starting container: ${CONTAINER_NAME}"

docker run \
    --detach \
    --name "$CONTAINER_NAME" \
    --publish "${PORT}:${PORT}" \
    --env-file .env \
    --restart unless-stopped \
    --health-cmd "curl -f http://localhost:${PORT}/iss-position || exit 1" \
    --health-interval 30s \
    --health-timeout 10s \
    --health-retries 3 \
    "$IMAGE_NAME"

# ── Wait for health ───────────────────────────────────────
info "Waiting for container to be healthy..."
ATTEMPTS=0
MAX=10

until [ "$(docker inspect --format='{{.State.Health.Status}}' "$CONTAINER_NAME" 2>/dev/null)" == "healthy" ]; do
    ATTEMPTS=$((ATTEMPTS + 1))
    [ $ATTEMPTS -ge $MAX ] && {
        warn "Container not healthy after ${MAX} attempts — check logs:"
        docker logs "$CONTAINER_NAME" --tail 20
        break
    }
    sleep 3
done

echo ""
success "Container is running!"
echo ""
echo -e "  ${GREEN}➜${NC}  App:    ${BOLD}http://localhost:${PORT}/splash${NC}"
echo -e "  ${CYAN}➜${NC}  Logs:   ${BOLD}docker logs -f ${CONTAINER_NAME}${NC}"
echo -e "  ${YELLOW}➜${NC}  Stop:   ${BOLD}docker stop ${CONTAINER_NAME}${NC}"
echo ""