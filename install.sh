#!/usr/bin/env bash
# crazydots installation script
# Installs configuration links safely without overwriting without confirmation

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
TARGET_DIR="$CONFIG_HOME/quickshell/crazydots"
DRY_RUN=0

usage() {
    cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Options:
  -d, --dry-run    Show actions without creating symlinks or files
  -h, --help       Show this help message
EOF
    exit 0
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        -d|--dry-run)
            DRY_RUN=1
            shift
            ;;
        -h|--help)
            usage
            ;;
        *)
            echo "Unknown option: $1" >&2
            usage
            ;;
    esac
done

echo "==> crazydots installer"
echo "Source: $SCRIPT_DIR/shell"
echo "Target: $TARGET_DIR"

if [[ $DRY_RUN -eq 1 ]]; then
    echo "[dry-run] Would create directory: $(dirname "$TARGET_DIR")"
    echo "[dry-run] Would link $SCRIPT_DIR/shell to $TARGET_DIR"
    exit 0
fi

mkdir -p "$(dirname "$TARGET_DIR")"

if [[ -e "$TARGET_DIR" || -L "$TARGET_DIR" ]]; then
    echo "Warning: Target $TARGET_DIR already exists."
    read -rp "Backup and replace? [y/N]: " confirm
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        BACKUP_DIR="${TARGET_DIR}.bak.$(date +%s)"
        mv "$TARGET_DIR" "$BACKUP_DIR"
        echo "Backed up existing configuration to: $BACKUP_DIR"
    else
        echo "Aborting installation."
        exit 1
    fi
fi

ln -s "$SCRIPT_DIR/shell" "$TARGET_DIR"
echo "==> crazydots installed successfully!"
echo "You can launch the shell using: quickshell -c crazydots"
echo "Or run in isolated mode using: quickshell -p $SCRIPT_DIR/shell"
