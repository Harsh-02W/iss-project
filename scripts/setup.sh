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

# ── Helpers ───────────────────────────────────────────────
info()    { echo -e "${CYAN}[INFO]${NC}  $1"; }
success() { echo -e "${GREEN}[OK]${NC}    $1"; }
warn()    { echo -e "${YELLOW}[WARN]${NC}  $1"; }
error()   { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

echo -e "${BOLD}"
echo "  ╔══════════════════════════════════╗"
echo "  ║      ISS Tracker — Setup         ║"
echo "  ╚══════════════════════════════════╝"
echo -e "${NC}"

# ── Check Python ──────────────────────────────────────────
info "Checking Python version..."
PYTHON=$(command -v python3 || command -v python)
[ -z "$PYTHON" ] && error "Python not found. Install Python 3.10+"

VERSION=$($PYTHON --version 2>&1 | awk '{print $2}')
MAJOR=$(echo "$VERSION" | cut -d. -f1)
MINOR=$(echo "$VERSION" | cut -d. -f2)

[ "$MAJOR" -lt 3 ] || [ "$MINOR" -lt 10 ] && error "Python 3.10+ required. Found $VERSION"
success "Python $VERSION found"

# ── Virtual Environment ───────────────────────────────────
if [ ! -d "venv" ]; then
    info "Creating virtual environment..."
    $PYTHON -m venv venv
    success "Virtual environment created"
else
    success "Virtual environment already exists"
fi

# ── Activate venv ─────────────────────────────────────────
source venv/bin/activate
success "Virtual environment activated"

# ── Install Dependencies ──────────────────────────────────
info "Installing dependencies..."
pip install --upgrade pip --quiet
pip install -r requirements.txt --quiet
success "Dependencies installed"

# ── .env file ─────────────────────────────────────────────
if [ ! -f ".env" ]; then
    if [ -f ".env.example" ]; then
        cp .env.example .env
        warn ".env created from .env.example — fill in your values"
    else
        warn "No .env file found. Create one before running the app"
    fi
else
    success ".env file found"
fi

# ── Scripts permissions ───────────────────────────────────
info "Making scripts executable..."
chmod +x scripts/*.sh
success "Scripts are executable"

echo ""
echo -e "${GREEN}${BOLD}Setup complete! Run: bash scripts/start.sh${NC}"