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
DB_PATH="instance/iss.db"
BACKUP_DIR="backups"
RETENTION_DAYS=7
TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
BACKUP_FILE="${BACKUP_DIR}/iss_backup_${TIMESTAMP}.db"

echo -e "${BOLD}"
echo "  ╔══════════════════════════════════╗"
echo "  ║    ISS Tracker — DB Backup       ║"
echo "  ╚══════════════════════════════════╝"
echo -e "${NC}"

# ── Checks ────────────────────────────────────────────────
[ ! -f "$DB_PATH" ] && error "Database not found at ${DB_PATH}"

# ── Create backup dir ─────────────────────────────────────
if [ ! -d "$BACKUP_DIR" ]; then
    mkdir -p "$BACKUP_DIR"
    info "Created backups/ directory"
fi

# ── Backup ────────────────────────────────────────────────
info "Backing up ${DB_PATH}..."
cp "$DB_PATH" "$BACKUP_FILE"

# Verify backup
[ ! -f "$BACKUP_FILE" ] && error "Backup failed — file not created"
BACKUP_SIZE=$(du -sh "$BACKUP_FILE" | cut -f1)
success "Backup created: ${BACKUP_FILE} (${BACKUP_SIZE})"

# ── Cleanup old backups ───────────────────────────────────
echo ""
info "Removing backups older than ${RETENTION_DAYS} days..."
DELETED=0

while IFS= read -r old_backup; do
    rm -f "$old_backup"
    info "  Deleted: $(basename "$old_backup")"
    DELETED=$((DELETED + 1))
done < <(find "$BACKUP_DIR" -name "iss_backup_*.db" -mtime "+${RETENTION_DAYS}" 2>/dev/null)

if [ $DELETED -eq 0 ]; then
    info "No old backups to remove"
else
    success "Removed ${DELETED} old backup(s)"
fi

# ── List current backups ──────────────────────────────────
echo ""
info "Current backups:"
find "$BACKUP_DIR" -name "iss_backup_*.db" -printf "  %f  (%s bytes)\n" 2>/dev/null \
    | sort -r \
    || ls -lh "$BACKUP_DIR"

echo ""
success "Backup complete!"