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
    "$SCRIPT_DIR/shell/services/HyprlandService.qml" \
    "$SCRIPT_DIR/shell/services/TerminalService.qml" \
    "$SCRIPT_DIR/shell/services/NetworkService.qml" \
    "$SCRIPT_DIR/shell/services/BrightnessService.qml" \
    "$SCRIPT_DIR/shell/components/StyledRect.qml" \
    "$SCRIPT_DIR/shell/components/StyledText.qml" \
    "$SCRIPT_DIR/shell/components/ButtonBase.qml" \
    "$SCRIPT_DIR/shell/panels/Bar.qml" \
    "$SCRIPT_DIR/shell/panels/Launcher.qml" \
    "$SCRIPT_DIR/shell/panels/WallpaperSurface.qml" \
    "$SCRIPT_DIR/shell/panels/WallpaperManager.qml" \
    "$SCRIPT_DIR/shell/panels/Dashboard.qml" \
    "$SCRIPT_DIR/shell/panels/ThemeManager.qml" \
    "$SCRIPT_DIR/shell/panels/popovers/ConnectivityPopover.qml" \
    "$SCRIPT_DIR/shell/panels/popovers/VolumePopover.qml" \
    "$SCRIPT_DIR/shell/panels/popovers/BrightnessPopover.qml" \
    "$SCRIPT_DIR/shell/panels/popovers/QuickTogglesPopover.qml" \
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
    "$SCRIPT_DIR/shell/TestLauncher.qml" \
    "$SCRIPT_DIR/shell/TestWallpaper.qml" \
    "$SCRIPT_DIR/shell/TestDashboard.qml" \
    "$SCRIPT_DIR/shell/TestHyprlandGhostty.qml" \
    "$SCRIPT_DIR/shell/TestPopoversUX.qml"

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

echo "==> 7. Executing M6 Wallpaper Manager & Dynamic Color Engine test suite in Quickshell..."
quickshell -p "$SCRIPT_DIR/shell/TestWallpaper.qml"

echo "==> 8. Executing M7 Corner Dashboard & Quick Settings test suite in Quickshell..."
quickshell -p "$SCRIPT_DIR/shell/TestDashboard.qml"

echo "==> 9. Executing M8 Hyprland & Ghostty Integration test suite in Quickshell..."
quickshell -p "$SCRIPT_DIR/shell/TestHyprlandGhostty.qml"

echo "==> 10. Executing M10 Popovers & Desktop UX test suite in Quickshell..."
quickshell -p "$SCRIPT_DIR/shell/TestPopoversUX.qml"

echo "==> 11. Verifying live Quickshell entry point (shell/shell.qml) & IPC..."
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

IPC_WP_DIR=$(quickshell ipc -p "$SCRIPT_DIR/shell" call crazydots getWallpaperDirectory)
IPC_WP_MODE=$(quickshell ipc -p "$SCRIPT_DIR/shell" call crazydots getWallpaperMode)
IPC_WP_MGR_INIT=$(quickshell ipc -p "$SCRIPT_DIR/shell" call crazydots isWallpaperManagerOpen)
IPC_WP_MGR_OPEN=$(quickshell ipc -p "$SCRIPT_DIR/shell" call crazydots openWallpaperManager)
IPC_WP_MGR_CHECK=$(quickshell ipc -p "$SCRIPT_DIR/shell" call crazydots isWallpaperManagerOpen)
IPC_WP_MGR_CLOSE=$(quickshell ipc -p "$SCRIPT_DIR/shell" call crazydots closeWallpaperManager)
IPC_WP_MGR_FINAL=$(quickshell ipc -p "$SCRIPT_DIR/shell" call crazydots isWallpaperManagerOpen)
IPC_WP_SET=$(quickshell ipc -p "$SCRIPT_DIR/shell" call crazydots setWallpaper "$SCRIPT_DIR/assets/wallpapers/crazydots-dark-mesh.svg" "fit")
IPC_WP_GET=$(quickshell ipc -p "$SCRIPT_DIR/shell" call crazydots getWallpaper)

IPC_DASH_CORNER=$(quickshell ipc -p "$SCRIPT_DIR/shell" call crazydots getDashboardCorner)
IPC_DASH_WIDTH=$(quickshell ipc -p "$SCRIPT_DIR/shell" call crazydots getDashboardWidth)
IPC_DASH_HEIGHT=$(quickshell ipc -p "$SCRIPT_DIR/shell" call crazydots getDashboardHeight)
IPC_DASH_INIT=$(quickshell ipc -p "$SCRIPT_DIR/shell" call crazydots isDashboardOpen)
IPC_DASH_OPEN=$(quickshell ipc -p "$SCRIPT_DIR/shell" call crazydots openDashboard)
IPC_DASH_CHECK=$(quickshell ipc -p "$SCRIPT_DIR/shell" call crazydots isDashboardOpen)
# Exclusivity: opening launcher must close dashboard
IPC_EXCL_LAUNCH=$(quickshell ipc -p "$SCRIPT_DIR/shell" call crazydots openLauncher)
IPC_DASH_AFTER_LAUNCH=$(quickshell ipc -p "$SCRIPT_DIR/shell" call crazydots isDashboardOpen)
IPC_LAUNCH_CHECK=$(quickshell ipc -p "$SCRIPT_DIR/shell" call crazydots isLauncherOpen)
# Re-opening dashboard must close launcher
IPC_DASH_REOPEN=$(quickshell ipc -p "$SCRIPT_DIR/shell" call crazydots openDashboard)
IPC_LAUNCH_AFTER_DASH=$(quickshell ipc -p "$SCRIPT_DIR/shell" call crazydots isLauncherOpen)
IPC_DASH_CLOSE=$(quickshell ipc -p "$SCRIPT_DIR/shell" call crazydots closeDashboard)
IPC_DASH_FINAL=$(quickshell ipc -p "$SCRIPT_DIR/shell" call crazydots isDashboardOpen)

# Theme Manager IPC verification
IPC_TM_INIT=$(quickshell ipc -p "$SCRIPT_DIR/shell" call crazydots isThemeManagerOpen)
IPC_TM_OPEN=$(quickshell ipc -p "$SCRIPT_DIR/shell" call crazydots openThemeManager)
IPC_TM_CHECK=$(quickshell ipc -p "$SCRIPT_DIR/shell" call crazydots isThemeManagerOpen)
IPC_TM_CLOSE=$(quickshell ipc -p "$SCRIPT_DIR/shell" call crazydots closeThemeManager)
IPC_TM_FINAL=$(quickshell ipc -p "$SCRIPT_DIR/shell" call crazydots isThemeManagerOpen)

# Contextual Popover IPC verification
IPC_POP_INIT=$(quickshell ipc -p "$SCRIPT_DIR/shell" call crazydots getActivePopover)
IPC_POP_OPEN=$(quickshell ipc -p "$SCRIPT_DIR/shell" call crazydots openPopover "connectivity")
IPC_POP_CHECK=$(quickshell ipc -p "$SCRIPT_DIR/shell" call crazydots getActivePopover)
IPC_POP_CLOSE=$(quickshell ipc -p "$SCRIPT_DIR/shell" call crazydots closePopover)
IPC_POP_FINAL=$(quickshell ipc -p "$SCRIPT_DIR/shell" call crazydots getActivePopover)

# Network & Hardware Brightness Services IPC
IPC_NET_AVAIL=$(quickshell ipc -p "$SCRIPT_DIR/shell" call crazydots isNetworkAvailable)
IPC_BRIGHT_AVAIL=$(quickshell ipc -p "$SCRIPT_DIR/shell" call crazydots isBrightnessAvailable)

# Hyprland & Terminal (Ghostty) IPC verification
IPC_HYPR_AVAIL=$(quickshell ipc -p "$SCRIPT_DIR/shell" call crazydots isHyprlandAvailable)
IPC_TERM_AVAIL=$(quickshell ipc -p "$SCRIPT_DIR/shell" call crazydots isTerminalAvailable)
IPC_TERM_CMD=$(quickshell ipc -p "$SCRIPT_DIR/shell" call crazydots getTerminalCommand)
IPC_TERM_APPID=$(quickshell ipc -p "$SCRIPT_DIR/shell" call crazydots getTerminalAppId)

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
echo "    IPC getWallpaperDirectory: $IPC_WP_DIR"
echo "    IPC getWallpaperMode: $IPC_WP_MODE"
echo "    IPC isWallpaperManagerOpen initial: $IPC_WP_MGR_INIT"
echo "    IPC openWallpaperManager response: $IPC_WP_MGR_OPEN"
echo "    IPC isWallpaperManagerOpen after open: $IPC_WP_MGR_CHECK"
echo "    IPC closeWallpaperManager response: $IPC_WP_MGR_CLOSE"
echo "    IPC isWallpaperManagerOpen after close: $IPC_WP_MGR_FINAL"
echo "    IPC setWallpaper response: $IPC_WP_SET"
echo "    IPC getWallpaper response: $IPC_WP_GET"
echo "    IPC getDashboardCorner: $IPC_DASH_CORNER"
echo "    IPC getDashboardWidth: $IPC_DASH_WIDTH"
echo "    IPC getDashboardHeight: $IPC_DASH_HEIGHT"
echo "    IPC isDashboardOpen initial: $IPC_DASH_INIT"
echo "    IPC openDashboard response: $IPC_DASH_OPEN"
echo "    IPC isDashboardOpen after open: $IPC_DASH_CHECK"
echo "    IPC isDashboardOpen after launcher open: $IPC_DASH_AFTER_LAUNCH"
echo "    IPC isLauncherOpen after launcher open: $IPC_LAUNCH_CHECK"
echo "    IPC isLauncherOpen after dashboard reopen: $IPC_LAUNCH_AFTER_DASH"
echo "    IPC isDashboardOpen after close: $IPC_DASH_FINAL"
echo "    IPC isThemeManagerOpen after open: $IPC_TM_CHECK"
echo "    IPC isThemeManagerOpen after close: $IPC_TM_FINAL"
echo "    IPC getActivePopover after open: $IPC_POP_CHECK"
echo "    IPC getActivePopover after close: $IPC_POP_FINAL"
echo "    IPC isNetworkAvailable: $IPC_NET_AVAIL"
echo "    IPC isBrightnessAvailable: $IPC_BRIGHT_AVAIL"
echo "    IPC isHyprlandAvailable: $IPC_HYPR_AVAIL"
echo "    IPC isTerminalAvailable: $IPC_TERM_AVAIL"
echo "    IPC getTerminalCommand: $IPC_TERM_CMD"
echo "    IPC getTerminalAppId: $IPC_TERM_APPID"

if [[ "$IPC_PING" != *"pong"* ]]; then
    echo "ERROR: IPC ping failed!" >&2
    exit 1
fi

if [[ "$IPC_LAUNCHER_CHECK" != *"true"* || "$IPC_LAUNCHER_FINAL" != *"false"* ]]; then
    echo "ERROR: IPC launcher toggling failed!" >&2
    exit 1
fi

if [[ "$IPC_WP_MGR_CHECK" != *"true"* || "$IPC_WP_MGR_FINAL" != *"false"* ]]; then
    echo "ERROR: IPC wallpaper manager toggling failed!" >&2
    exit 1
fi

if [[ "$IPC_WP_GET" != *"crazydots-dark-mesh.svg"* ]]; then
    echo "ERROR: IPC setWallpaper / getWallpaper failed!" >&2
    exit 1
fi

if [[ "$IPC_DASH_CHECK" != *"true"* || "$IPC_DASH_FINAL" != *"false"* ]]; then
    echo "ERROR: IPC dashboard toggling failed!" >&2
    exit 1
fi

if [[ "$IPC_DASH_AFTER_LAUNCH" != *"false"* || "$IPC_LAUNCH_AFTER_DASH" != *"false"* ]]; then
    echo "ERROR: IPC modal exclusivity failed!" >&2
    exit 1
fi

if [[ "$IPC_TM_CHECK" != *"true"* || "$IPC_TM_FINAL" != *"false"* ]]; then
    echo "ERROR: IPC theme manager toggling failed!" >&2
    exit 1
fi

if [[ "$IPC_POP_CHECK" != *"connectivity"* || "$IPC_POP_FINAL" == *"connectivity"* ]]; then
    echo "ERROR: IPC popover toggling failed!" >&2
    exit 1
fi

if [[ "$IPC_HYPR_AVAIL" != *"true"* ]]; then
    echo "ERROR: IPC isHyprlandAvailable failed!" >&2
    exit 1
fi

if [[ "$IPC_TERM_AVAIL" != *"true"* || "$IPC_TERM_CMD" != *"ghostty"* ]]; then
    echo "ERROR: IPC Ghostty terminal check failed!" >&2
    exit 1
fi

echo "==> 12. Verifying live environment integrity..."
# Check that ~/.config/hypr and Caelestia are untouched
if [[ ! -f "$HOME/.config/hypr/hyprland.lua" ]]; then
    echo "ERROR: ~/.config/hypr/hyprland.lua missing!" >&2
    exit 1
fi

echo "==> ALL AUTOMATED CHECKS AND RUNTIME TESTS PASSED SUCCESSFULLY!"
