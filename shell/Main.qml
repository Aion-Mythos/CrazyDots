import QtQuick
import Quickshell
import Quickshell.Io
import "."
import "services"
import "panels"

/**
 * Main.qml
 * Core shell coordinator for crazydots.
 *
 * Responsibilities:
 * - Bootstraps global services (Config, Theme, ThemeEngine, NetworkService, BrightnessService).
 * - Exposes a safe, structured IPC interface via Quickshell.Io.IpcHandler.
 * - Coordinates per-monitor screen instantiation using Quickshell.screens and Variants.
 * - Manages modal lifecycle (Launcher, WallpaperManager, ThemeManager, Dashboard, Popovers)
 *   with strict deterministic mutual exclusivity.
 */
Item {
    id: root

    // =========================================================================
    // MODAL & POPOVER STATE MANAGEMENT
    // Deterministic modal exclusivity: at most one modal drawer or popover can be active.
    // Opening any modal or popover automatically dismisses all others.
    // =========================================================================
    property bool launcherOpen: false
    property bool wallpaperManagerOpen: false
    property bool dashboardOpen: false
    property bool themeManagerOpen: false
    property string activePopover: ""

    function openLauncher(): bool {
        root.wallpaperManagerOpen = false;
        root.dashboardOpen = false;
        root.themeManagerOpen = false;
        root.activePopover = "";
        root.launcherOpen = true;
        return true;
    }

    function closeLauncher(): bool {
        root.launcherOpen = false;
        return true;
    }

    function toggleLauncher(): bool {
        return root.launcherOpen ? root.closeLauncher() : root.openLauncher();
    }

    function isLauncherOpen(): bool {
        return root.launcherOpen;
    }

    function openWallpaperManager(): bool {
        root.launcherOpen = false;
        root.dashboardOpen = false;
        root.themeManagerOpen = false;
        root.activePopover = "";
        root.wallpaperManagerOpen = true;
        return true;
    }

    function closeWallpaperManager(): bool {
        root.wallpaperManagerOpen = false;
        return true;
    }

    function toggleWallpaperManager(): bool {
        return root.wallpaperManagerOpen ? root.closeWallpaperManager() : root.openWallpaperManager();
    }

    function isWallpaperManagerOpen(): bool {
        return root.wallpaperManagerOpen;
    }

    function openThemeManager(): bool {
        root.launcherOpen = false;
        root.wallpaperManagerOpen = false;
        root.dashboardOpen = false;
        root.activePopover = "";
        root.themeManagerOpen = true;
        return true;
    }

    function closeThemeManager(): bool {
        root.themeManagerOpen = false;
        return true;
    }

    function toggleThemeManager(): bool {
        return root.themeManagerOpen ? root.closeThemeManager() : root.openThemeManager();
    }

    function isThemeManagerOpen(): bool {
        return root.themeManagerOpen;
    }

    function openDashboard(): bool {
        root.launcherOpen = false;
        root.wallpaperManagerOpen = false;
        root.themeManagerOpen = false;
        root.activePopover = "";
        root.dashboardOpen = true;
        return true;
    }

    function closeDashboard(): bool {
        root.dashboardOpen = false;
        return true;
    }

    function toggleDashboard(): bool {
        return root.dashboardOpen ? root.closeDashboard() : root.openDashboard();
    }

    function isDashboardOpen(): bool {
        return root.dashboardOpen;
    }

    function openPopover(name: string): bool {
        if (!name || typeof name !== "string") return false;
        root.launcherOpen = false;
        root.wallpaperManagerOpen = false;
        root.themeManagerOpen = false;
        root.dashboardOpen = false;
        root.activePopover = name.trim();
        return true;
    }

    function closePopover(): bool {
        root.activePopover = "";
        return true;
    }

    function togglePopover(name: string): bool {
        const clean = (name || "").trim();
        if (root.activePopover === clean) {
            return root.closePopover();
        } else {
            return root.openPopover(clean);
        }
    }

    function getActivePopover(): string {
        return root.activePopover;
    }

    // =========================================================================
    // SERVICE SINGLETONS
    // =========================================================================
    ThemeEngine {
        id: themeEngine
    }

    HyprlandService {
        id: hyprlandService
    }

    TerminalService {
        id: terminalService
    }

    NetworkService {
        id: networkService
    }

    BrightnessService {
        id: brightnessService
    }

    // =========================================================================
    // SAFE IPC INTERFACE
    // Exposes controlled methods for external scripts, keybinds, and debugging.
    // Does not execute arbitrary commands or evaluate untrusted strings.
    // =========================================================================
    IpcHandler {
        id: ipc
        target: "crazydots"

        function ping(): string {
            return "pong";
        }

        function getTheme(): string {
            return Theme.activeThemeName;
        }

        function setTheme(name: string): bool {
            return Config.setThemeName(name);
        }

        function reloadConfig(): bool {
            return Config.loadFromFile("");
        }

        function isAnimationsEnabled(): bool {
            return Config.animationsEnabled;
        }

        function getScreenCount(): int {
            return Quickshell.screens.length;
        }

        function getBarPosition(): string {
            return Config.barPosition;
        }

        function setBarPosition(pos: string): bool {
            return Config.setBarPosition(pos);
        }

        function isBarFloating(): bool {
            return Config.barFloating;
        }

        function setBarFloating(floating: bool): bool {
            return Config.setBarFloating(floating);
        }

        function getScreens() {
            const list = [];
            for (let i = 0; i < Quickshell.screens.length; i++) {
                const s = Quickshell.screens[i];
                list.push({
                    name: s.name,
                    width: s.width,
                    height: s.height
                });
            }
            return list;
        }

        // Launcher IPC API
        function openLauncher(): bool {
            return root.openLauncher();
        }

        function closeLauncher(): bool {
            return root.closeLauncher();
        }

        function toggleLauncher(): bool {
            return root.toggleLauncher();
        }

        function isLauncherOpen(): bool {
            return root.isLauncherOpen();
        }

        // Wallpaper IPC API
        function getWallpaper(): string {
            return Config.wallpaperCurrent;
        }

        function setWallpaper(path: string, mode: string): bool {
            Config.setWallpaper(path, mode);
            return true;
        }

        function getWallpaperMode(): string {
            return Config.wallpaperMode;
        }

        function getWallpaperDirectory(): string {
            return Config.wallpaperDirectory;
        }

        function setWallpaperDirectory(dir: string): bool {
            return Config.setWallpaperDirectory(dir);
        }

        function openWallpaperManager(): bool {
            return root.openWallpaperManager();
        }

        function closeWallpaperManager(): bool {
            return root.closeWallpaperManager();
        }

        function toggleWallpaperManager(): bool {
            return root.toggleWallpaperManager();
        }

        function isWallpaperManagerOpen(): bool {
            return root.isWallpaperManagerOpen();
        }

        function extractDynamicColors(path: string): bool {
            return themeEngine.extractFromWallpaper(path);
        }

        // Dedicated Theme Manager IPC API
        function openThemeManager(): bool {
            return root.openThemeManager();
        }

        function closeThemeManager(): bool {
            return root.closeThemeManager();
        }

        function toggleThemeManager(): bool {
            return root.toggleThemeManager();
        }

        function isThemeManagerOpen(): bool {
            return root.isThemeManagerOpen();
        }

        // Dashboard IPC API
        function openDashboard(): bool {
            return root.openDashboard();
        }

        function closeDashboard(): bool {
            return root.closeDashboard();
        }

        function toggleDashboard(): bool {
            return root.toggleDashboard();
        }

        function isDashboardOpen(): bool {
            return root.isDashboardOpen();
        }

        function getDashboardCorner(): string {
            return Config.dashboardCorner;
        }

        function setDashboardCorner(corner: string): bool {
            return Config.setDashboardCorner(corner);
        }

        function getDashboardWidth(): int {
            return Config.dashboardWidth;
        }

        function setDashboardWidth(w: int): bool {
            return Config.setDashboardWidth(w);
        }

        function getDashboardHeight(): int {
            return Config.dashboardHeight;
        }

        function setDashboardHeight(h: int): bool {
            return Config.setDashboardHeight(h);
        }

        // Contextual Popovers IPC API
        function openPopover(name: string): bool {
            return root.openPopover(name);
        }

        function closePopover(): bool {
            return root.closePopover();
        }

        function togglePopover(name: string): bool {
            return root.togglePopover(name);
        }

        function getActivePopover(): string {
            return root.getActivePopover();
        }

        // Connectivity & Network IPC API
        function isNetworkAvailable(): bool {
            return networkService.isAvailable;
        }

        function getWifiEnabled(): bool {
            return networkService.wifiEnabled;
        }

        function toggleWifi(): bool {
            return networkService.toggleWifi();
        }

        function getConnectedSsid(): string {
            return networkService.connectedSsid;
        }

        function rescanWifi(): bool {
            return networkService.rescan();
        }

        // Brightness IPC API
        function isBrightnessAvailable(): bool {
            return brightnessService.isAvailable;
        }

        function getBrightness(): int {
            return brightnessService.brightnessPercent;
        }

        function setBrightness(pct: int): bool {
            return brightnessService.setBrightness(pct);
        }

        // Hyprland Integration IPC API
        function isHyprlandAvailable(): bool {
            return hyprlandService.isAvailable;
        }

        function getActiveWorkspace() {
            return hyprlandService.getActiveWorkspace();
        }

        function getWorkspaces() {
            return hyprlandService.getWorkspaces();
        }

        function getActiveWindow() {
            return hyprlandService.getActiveWindow();
        }

        function focusWorkspace(id: int): bool {
            return hyprlandService.focusWorkspace(id);
        }

        function dispatchHyprland(request: string): bool {
            return hyprlandService.dispatch(request);
        }

        // Terminal Integration IPC API
        function isTerminalAvailable(): bool {
            return terminalService.isTerminalAvailable;
        }

        function getTerminalCommand(): string {
            return Config.terminalCommand;
        }

        function setTerminalCommand(cmd: string): bool {
            return Config.setTerminalCommand(cmd);
        }

        function getTerminalAppId(): string {
            return Config.terminalAppId;
        }

        function setTerminalAppId(id: string): bool {
            return Config.setTerminalAppId(id);
        }

        function launchTerminal(): bool {
            return terminalService.launchTerminal();
        }
    }

    // =========================================================================
    // MULTI-MONITOR WALLPAPER BACKGROUND INSTANTIATION
    // Mounts an independent wallpaper background surface on each connected display.
    // =========================================================================
    Variants {
        id: wallpaperVariants
        model: Quickshell.screens

        delegate: Component {
            WallpaperSurface {
                required property var modelData
                screen: modelData
                onWallpaperManagerRequested: root.openWallpaperManager()
                onThemeManagerRequested: root.openThemeManager()
            }
        }
    }

    // =========================================================================
    // MULTI-MONITOR CANVAS INSTANTIATION
    // Dynamically manages a ScreenCanvas for every connected display.
    // =========================================================================
    Variants {
        id: screenVariants
        model: Quickshell.screens

        delegate: Component {
            ScreenCanvas {
                required property var modelData
                screen: modelData
                networkService: networkService
                brightnessService: brightnessService
                launcherOpen: root.launcherOpen
                wallpaperManagerOpen: root.wallpaperManagerOpen
                dashboardOpen: root.dashboardOpen
                themeManagerOpen: root.themeManagerOpen
                activePopover: root.activePopover

                onLauncherCloseRequested: root.closeLauncher()
                onWallpaperManagerCloseRequested: root.closeWallpaperManager()
                onDashboardCloseRequested: root.closeDashboard()
                onThemeManagerCloseRequested: root.closeThemeManager()
                onPopoverCloseRequested: root.closePopover()
                onWallpaperManagerRequested: root.openWallpaperManager()
                onThemeManagerRequested: root.openThemeManager()

                onTerminalLaunchRequested: function() {
                    terminalService.launchTerminal();
                }
                onDynamicColorsRequested: function(path) {
                    themeEngine.extractFromWallpaper(path);
                }
            }
        }
    }

    // =========================================================================
    // MULTI-MONITOR DESKTOP BAR INSTANTIATION
    // Mounts an independent desktop bar on each connected display.
    // =========================================================================
    Variants {
        id: barVariants
        model: Quickshell.screens

        delegate: Component {
            Bar {
                required property var modelData
                screen: modelData

                onLauncherTriggered: {
                    root.toggleLauncher();
                }

                onDashboardTriggered: {
                    root.toggleDashboard();
                }

                onConnectivityTriggered: {
                    root.togglePopover("connectivity");
                }

                onVolumeTriggered: {
                    root.togglePopover("volume");
                }

                onQuickTogglesTriggered: {
                    root.togglePopover("quickToggles");
                }
            }
        }
    }

    Component.onCompleted: {
        console.log("crazydots: Shell Base initialized with", Quickshell.screens.length, "screen(s). Active theme:", Theme.activeThemeName);
    }
}
