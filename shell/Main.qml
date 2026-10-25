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
    // GLOBAL HEADLESS SERVICES
    // =========================================================================
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
                    console.log("crazydots: Launcher triggered from Bar on screen", modelData ? modelData.name : "");
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
