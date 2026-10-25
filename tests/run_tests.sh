#!/usr/bin/env bash
# crazydots automated test runner
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
echo "==> Running static analysis with qmllint..."
qmllint -I "$SCRIPT_DIR/shell" \
    "$SCRIPT_DIR/shell/Tokens.qml" \
    "$SCRIPT_DIR/shell/Theme.qml" \
    "$SCRIPT_DIR/shell/services/ThemeEngine.qml" \
    "$SCRIPT_DIR/shell/TestThemeEngine.qml"

echo "==> qmllint passed with 0 errors!"
echo "==> Executing runtime test suite in Quickshell..."
quickshell -p "$SCRIPT_DIR/shell/TestThemeEngine.qml"

echo "==> All automated tests completed successfully!"
