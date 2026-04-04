#!/bin/bash
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
error()   { echo -e "${RED}[DOWN]${NC} $1"; }

# ── Config ────────────────────────────────────────────────
PORT=$(grep -E '^FLASK_PORT=' .env 2>/dev/null | cut -d= -f2 | tr -d ' ')
PORT=${PORT:-5000}
BASE_URL="http://localhost:${PORT}"

echo -e "${BOLD}"
echo "  ╔══════════════════════════════════╗"
echo "  ║   ISS Tracker — Health Check     ║"
echo "  ╚══════════════════════════════════╝"
echo -e "${NC}"

PASS=0
FAIL=0

# ── Helper ────────────────────────────────────────────────
check() {
    local label="$1"
    local url="$2"
    local expect="$3"  # optional: string to grep in response

    HTTP_CODE=$(curl -s -o /tmp/iss_hc_resp -w "%{http_code}" \
        --max-time 5 "${url}" 2>/dev/null || echo "000")

    if [ "$HTTP_CODE" == "000" ]; then
        error "${label} — UNREACHABLE"
        FAIL=$((FAIL + 1))
        return
    fi

    if [ "$HTTP_CODE" -ge 400 ]; then
        error "${label} — HTTP ${HTTP_CODE}"
        FAIL=$((FAIL + 1))
        return
    fi

    if [ -n "$expect" ]; then
        if grep -q "$expect" /tmp/iss_hc_resp 2>/dev/null; then
            success "${label} — HTTP ${HTTP_CODE} ✓"
            PASS=$((PASS + 1))
        else
            warn "${label} — HTTP ${HTTP_CODE} but unexpected response"
            FAIL=$((FAIL + 1))
        fi
    else
        success "${label} — HTTP ${HTTP_CODE} ✓"
        PASS=$((PASS + 1))
    fi
}

# ── Checks ────────────────────────────────────────────────
info "Checking endpoints on ${BASE_URL}..."
echo ""

check "Splash page"    "${BASE_URL}/splash"         "ISS"
check "Login page"     "${BASE_URL}/login"           "Sign in"
check "ISS Position"   "${BASE_URL}/iss-position"    "latitude"

# ── ISS data details ──────────────────────────────────────
echo ""
info "Fetching live ISS position..."
RESP=$(curl -s --max-time 5 "${BASE_URL}/iss-position" 2>/dev/null)

if echo "$RESP" | python3 -c "import sys,json; d=json.load(sys.stdin); print(f'  Latitude:  {d[\"latitude\"]}°\n  Longitude: {d[\"longitude\"]}°\n  Timestamp: {d[\"timestamp\"]}')" 2>/dev/null; then
    echo ""
    success "ISS data is valid JSON"
else
    warn "Could not parse ISS position response"
fi

# ── Docker container check ────────────────────────────────
echo ""
info "Checking Docker container..."
if command -v docker &>/dev/null; then
    CONTAINER_STATUS=$(docker inspect --format='{{.State.Status}}' iss-tracker-app 2>/dev/null || echo "not found")
    HEALTH_STATUS=$(docker inspect --format='{{.State.Health.Status}}' iss-tracker-app 2>/dev/null || echo "n/a")

    if [ "$CONTAINER_STATUS" == "running" ]; then
        success "Container: ${CONTAINER_STATUS} | Health: ${HEALTH_STATUS}"
    elif [ "$CONTAINER_STATUS" == "not found" ]; then
        info "Container not running (running locally instead)"
    else
        warn "Container status: ${CONTAINER_STATUS}"
    fi
else
    info "Docker not available — skipping container check"
fi

# ── Summary ───────────────────────────────────────────────
echo ""
echo "  ─────────────────────────────────"
echo -e "  ${GREEN}Passed: ${PASS}${NC}   ${RED}Failed: ${FAIL}${NC}"
echo "  ─────────────────────────────────"
echo ""

[ $FAIL -gt 0 ] && exit 1 || exit 0