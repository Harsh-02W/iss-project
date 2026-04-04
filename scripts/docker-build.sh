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
IMAGE_NAME="iss-tracker"
GIT_HASH=$(git rev-parse --short HEAD 2>/dev/null || echo "nogit")
TAG="${1:-$GIT_HASH}"            # use arg if provided, else git hash
FULL_TAG="${IMAGE_NAME}:${TAG}"
LATEST_TAG="${IMAGE_NAME}:latest"

echo -e "${BOLD}"
echo "  ╔══════════════════════════════════╗"
echo "  ║    ISS Tracker — Docker Build    ║"
echo "  ╚══════════════════════════════════╝"
echo -e "${NC}"

# ── Pre-checks ────────────────────────────────────────────
command -v docker &>/dev/null || error "Docker not found. Install Docker first"
[ ! -f "Dockerfile" ] && error "Dockerfile not found in project root"
[ ! -f "requirements.txt" ] && error "requirements.txt not found"

info "Building image: ${FULL_TAG}"
info "Also tagging as: ${LATEST_TAG}"
echo ""

# ── Build ─────────────────────────────────────────────────
START_TIME=$(date +%s)

docker build \
    --tag "$FULL_TAG" \
    --tag "$LATEST_TAG" \
    --label "build.git-hash=${GIT_HASH}" \
    --label "build.date=$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
    .

END_TIME=$(date +%s)
BUILD_TIME=$((END_TIME - START_TIME))

echo ""
success "Build completed in ${BUILD_TIME}s"

# ── Image info ────────────────────────────────────────────
echo ""
info "Image details:"
docker images "$IMAGE_NAME" --format "  Tag: {{.Tag}}  |  Size: {{.Size}}  |  Created: {{.CreatedAt}}"

# ── Optional push ─────────────────────────────────────────
echo ""
if [ "${2}" == "--push" ]; then
    DOCKERHUB_USER=$(grep -E '^DOCKERHUB_USER=' .env 2>/dev/null | cut -d= -f2 | tr -d ' ')
    [ -z "$DOCKERHUB_USER" ] && error "DOCKERHUB_USER not set in .env"

    info "Pushing to Docker Hub as ${DOCKERHUB_USER}/${IMAGE_NAME}..."
    docker tag "$FULL_TAG" "${DOCKERHUB_USER}/${IMAGE_NAME}:${TAG}"
    docker tag "$LATEST_TAG" "${DOCKERHUB_USER}/${IMAGE_NAME}:latest"
    docker push "${DOCKERHUB_USER}/${IMAGE_NAME}:${TAG}"
    docker push "${DOCKERHUB_USER}/${IMAGE_NAME}:latest"
    success "Pushed to Docker Hub"
fi

echo ""
echo -e "  ${GREEN}Run it:${NC} bash scripts/docker-run.sh"