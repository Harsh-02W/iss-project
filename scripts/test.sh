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
echo "  ║     ISS Tracker — Tests          ║"
echo "  ╚══════════════════════════════════╝"
echo -e "${NC}"

# ── Activate venv ─────────────────────────────────────────
[ ! -d "venv" ] && error "venv not found. Run: bash scripts/setup.sh"
source venv/bin/activate

# ── Install pytest if missing ─────────────────────────────
if ! python -c "import pytest" 2>/dev/null; then
    info "Installing pytest..."
    pip install pytest pytest-cov --quiet
fi

# ── Check if tests exist ──────────────────────────────────
if [ ! -d "tests" ] && [ -z "$(find . -name 'test_*.py' -not -path './venv/*' 2>/dev/null)" ]; then
    warn "No tests found. Create a tests/ folder with test_*.py files"
    echo ""
    echo -e "  ${YELLOW}Example:${NC} tests/test_iss.py"
    echo ""

    # Still run import checks as basic smoke test
    info "Running smoke tests (import checks)..."
    python -c "import app; print('  app.py        ✓')"
    python -c "import iss; print('  iss.py        ✓')"
    python -c "import models; print('  models.py     ✓')"
    python -c "import auth; print('  auth.py       ✓')"
    success "Smoke tests passed"
    exit 0
fi

# ── Run pytest ────────────────────────────────────────────
info "Running test suite..."
echo ""

python -m pytest tests/ \
    --tb=short \
    --cov=. \
    --cov-omit="venv/*,tests/*" \
    --cov-report=term-missing \
    -v

echo ""
success "All tests completed"