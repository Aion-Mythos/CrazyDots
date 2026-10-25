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
 * - Bootstraps global services (Config, Theme, ThemeEngine).
 * - Exposes a safe, structured IPC interface via Quickshell.Io.IpcHandler.
 * - Coordinates per-monitor screen instantiation using Quickshell.screens and Variants.
 * - Manages the lifecycle of desktop panels without embedding individual panel logic.
 */
Item {
    id: root

    // =========================================================================
    // LAUNCHER & MODAL STATE MANAGEMENT
    // =========================================================================
    property bool launcherOpen: false
    property bool wallpaperManagerOpen: false

    function openLauncher(): bool {
        root.launcherOpen = true;
        return true;
    }

    function closeLauncher(): bool {
        root.launcherOpen = false;
        return true;
    }

    function toggleLauncher(): bool {
        root.launcherOpen = !root.launcherOpen;
        return root.launcherOpen;
    }

    function isLauncherOpen(): bool {
        return root.launcherOpen;
    }

    function openWallpaperManager(): bool {
        root.wallpaperManagerOpen = true;
        return true;
    }

    function closeWallpaperManager(): bool {
        root.wallpaperManagerOpen = false;
        return true;
    }

    function toggleWallpaperManager(): bool {
        root.wallpaperManagerOpen = !root.wallpaperManagerOpen;
        return root.wallpaperManagerOpen;
    }

    function isWallpaperManagerOpen(): bool {
        return root.wallpaperManagerOpen;
    }

    ThemeEngine {
        id: themeEngine
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

        // Wallpaper & Theme IPC API
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
                launcherOpen: root.launcherOpen
                wallpaperManagerOpen: root.wallpaperManagerOpen
                onLauncherCloseRequested: root.closeLauncher()
                onWallpaperManagerCloseRequested: root.closeWallpaperManager()
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
                    console.log("crazydots: Dashboard triggered from Bar on screen", modelData ? modelData.name : "");
                }
            }
        }
    }

    Component.onCompleted: {
        console.log("crazydots: Shell Base initialized with", Quickshell.screens.length, "screen(s). Active theme:", Theme.activeThemeName);
    }
}
