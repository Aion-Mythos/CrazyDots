#!/usr/bin/env bash
# crazydots automated test runner
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
echo "==> Running static analysis with qmllint..."
qmllint -I "$SCRIPT_DIR/shell" \
    "$SCRIPT_DIR/shell/Tokens.qml" \
    "$SCRIPT_DIR/shell/Theme.qml" \
    "$SCRIPT_DIR/shell/Config.qml" \
    "$SCRIPT_DIR/shell/services/ThemeEngine.qml" \
    "$SCRIPT_DIR/shell/TestThemeEngine.qml" \
    "$SCRIPT_DIR/shell/TestConfig.qml"

echo "==> qmllint passed with 0 errors!"
echo "==> Executing M1 Theme Engine test suite in Quickshell..."
quickshell -p "$SCRIPT_DIR/shell/TestThemeEngine.qml"

echo "==> Executing M2 Config & Persistence test suite in Quickshell..."
quickshell -p "$SCRIPT_DIR/shell/TestConfig.qml"

echo "==> All automated tests completed successfully!"
