#!/usr/bin/env bash
# crazydots uninstallation script
# Safely removes crazydots configuration symlinks without touching other tools

set -euo pipefail

CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
TARGET_DIR="$CONFIG_HOME/quickshell/crazydots"

echo "==> crazydots uninstaller"

if [[ -L "$TARGET_DIR" ]]; then
    rm "$TARGET_DIR"
    echo "Removed symlink: $TARGET_DIR"
elif [[ -d "$TARGET_DIR" ]]; then
    read -rp "Directory $TARGET_DIR is not a symlink. Delete it? [y/N]: " confirm
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        rm -rf "$TARGET_DIR"
        echo "Removed directory: $TARGET_DIR"
    else
        echo "Skipping directory removal."
    fi
else
    echo "crazydots link not found in $CONFIG_HOME/quickshell/."
fi

echo "==> crazydots uninstalled."
