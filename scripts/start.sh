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

echo -e "${BOLD}"
echo "  ╔══════════════════════════════════╗"
echo "  ║     ISS Tracker — Starting       ║"
echo "  ╚══════════════════════════════════╝"
echo -e "${NC}"

# ── Check venv ────────────────────────────────────────────
[ ! -d "venv" ] && error "Virtual environment not found. Run: bash scripts/setup.sh"
source venv/bin/activate
success "Virtual environment activated"

# ── Check .env ────────────────────────────────────────────
if [ ! -f ".env" ]; then
    warn ".env file not found — app may not work correctly"
else
    success ".env file found"
fi

# ── Check requirements ────────────────────────────────────
info "Verifying dependencies..."
pip check --quiet && success "All dependencies satisfied" || warn "Some dependency issues found"

# ── Load port from .env ───────────────────────────────────
PORT=$(grep -E '^FLASK_PORT=' .env 2>/dev/null | cut -d= -f2 | tr -d ' ')
PORT=${PORT:-5000}

info "Starting ISS Tracker on port ${PORT}..."
echo ""
echo -e "  ${GREEN}➜${NC}  Local:   ${BOLD}http://localhost:${PORT}/splash${NC}"
echo ""

# ── Start App ─────────────────────────────────────────────
python app.py