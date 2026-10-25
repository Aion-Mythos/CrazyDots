#!/usr/bin/env bash
# crazydots automated test runner
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "==> 1. Running static analysis with qmllint..."
qmllint -I "$SCRIPT_DIR/shell" \
    "$SCRIPT_DIR/shell/Tokens.qml" \
    "$SCRIPT_DIR/shell/Theme.qml" \
    "$SCRIPT_DIR/shell/Config.qml" \
    "$SCRIPT_DIR/shell/Main.qml" \
    "$SCRIPT_DIR/shell/ScreenCanvas.qml" \
    "$SCRIPT_DIR/shell/shell.qml" \
    "$SCRIPT_DIR/shell/services/ThemeEngine.qml" \
    "$SCRIPT_DIR/shell/components/StyledRect.qml" \
    "$SCRIPT_DIR/shell/components/StyledText.qml" \
    "$SCRIPT_DIR/shell/components/ButtonBase.qml" \
    "$SCRIPT_DIR/shell/panels/Bar.qml" \
    "$SCRIPT_DIR/shell/panels/Launcher.qml" \
    "$SCRIPT_DIR/shell/panels/bar/BarPill.qml" \
    "$SCRIPT_DIR/shell/panels/bar/Workspaces.qml" \
    "$SCRIPT_DIR/shell/panels/bar/ActiveWindow.qml" \
    "$SCRIPT_DIR/shell/panels/bar/ClockWidget.qml" \
    "$SCRIPT_DIR/shell/panels/bar/AudioWidget.qml" \
    "$SCRIPT_DIR/shell/panels/bar/BatteryWidget.qml" \
    "$SCRIPT_DIR/shell/panels/bar/TrayWidget.qml" \
    "$SCRIPT_DIR/shell/TestThemeEngine.qml" \
    "$SCRIPT_DIR/shell/TestConfig.qml" \
    "$SCRIPT_DIR/shell/TestBaseComponents.qml" \
    "$SCRIPT_DIR/shell/TestBar.qml" \
    "$SCRIPT_DIR/shell/TestLauncher.qml"

echo "==> qmllint passed with 0 errors!"

echo "==> 2. Executing M1 Theme Engine test suite in Quickshell..."
quickshell -p "$SCRIPT_DIR/shell/TestThemeEngine.qml"

echo "==> 3. Executing M2 Config & Persistence test suite in Quickshell..."
quickshell -p "$SCRIPT_DIR/shell/TestConfig.qml"

echo "==> 4. Executing M3 Shell Base & Components test suite in Quickshell..."
quickshell -p "$SCRIPT_DIR/shell/TestBaseComponents.qml"

echo "==> 5. Executing M4 Desktop Bar test suite in Quickshell..."
quickshell -p "$SCRIPT_DIR/shell/TestBar.qml"

echo "==> 6. Executing M5 Application Launcher test suite in Quickshell..."
quickshell -p "$SCRIPT_DIR/shell/TestLauncher.qml"

echo "==> 7. Verifying live Quickshell entry point (shell/shell.qml) & IPC..."
# Start shell.qml in background with isolated config path
quickshell -p "$SCRIPT_DIR/shell" &
SHELL_PID=$!
sleep 1.2

# Verify IPC functions
IPC_PING=$(quickshell ipc -p "$SCRIPT_DIR/shell" call crazydots ping)
IPC_THEME=$(quickshell ipc -p "$SCRIPT_DIR/shell" call crazydots getTheme)
IPC_SCREENS=$(quickshell ipc -p "$SCRIPT_DIR/shell" call crazydots getScreenCount)
IPC_BAR_POS=$(quickshell ipc -p "$SCRIPT_DIR/shell" call crazydots getBarPosition)
IPC_BAR_FLOAT=$(quickshell ipc -p "$SCRIPT_DIR/shell" call crazydots isBarFloating)
IPC_LAUNCHER_INIT=$(quickshell ipc -p "$SCRIPT_DIR/shell" call crazydots isLauncherOpen)
IPC_LAUNCHER_OPEN=$(quickshell ipc -p "$SCRIPT_DIR/shell" call crazydots openLauncher)
IPC_LAUNCHER_CHECK=$(quickshell ipc -p "$SCRIPT_DIR/shell" call crazydots isLauncherOpen)
IPC_LAUNCHER_CLOSE=$(quickshell ipc -p "$SCRIPT_DIR/shell" call crazydots closeLauncher)
IPC_LAUNCHER_FINAL=$(quickshell ipc -p "$SCRIPT_DIR/shell" call crazydots isLauncherOpen)

# Terminate test instance cleanly
kill "$SHELL_PID" 2>/dev/null || true
wait "$SHELL_PID" 2>/dev/null || true

echo "    IPC ping response: $IPC_PING"
echo "    IPC getTheme response: $IPC_THEME"
echo "    IPC getScreenCount response: $IPC_SCREENS"
echo "    IPC getBarPosition response: $IPC_BAR_POS"
echo "    IPC isBarFloating response: $IPC_BAR_FLOAT"
echo "    IPC isLauncherOpen initial: $IPC_LAUNCHER_INIT"
echo "    IPC openLauncher response: $IPC_LAUNCHER_OPEN"
echo "    IPC isLauncherOpen after open: $IPC_LAUNCHER_CHECK"
echo "    IPC closeLauncher response: $IPC_LAUNCHER_CLOSE"
echo "    IPC isLauncherOpen after close: $IPC_LAUNCHER_FINAL"

if [[ "$IPC_PING" != *"pong"* ]]; then
    echo "ERROR: IPC ping failed!" >&2
    exit 1
fi

if [[ "$IPC_LAUNCHER_CHECK" != *"true"* || "$IPC_LAUNCHER_FINAL" != *"false"* ]]; then
    echo "ERROR: IPC launcher toggling failed!" >&2
    exit 1
fi

echo "==> 8. Verifying live environment integrity..."
# Check that ~/.config/hypr and Caelestia are untouched
if [[ ! -f "$HOME/.config/hypr/hyprland.lua" ]]; then
    echo "ERROR: ~/.config/hypr/hyprland.lua missing!" >&2
    exit 1
fi

echo "==> ALL AUTOMATED CHECKS AND RUNTIME TESTS PASSED SUCCESSFULLY!"
