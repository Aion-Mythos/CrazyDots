//@ pragma DefaultEnv QS_NO_RELOAD_POPUP=1
//@ pragma DefaultEnv QSG_RENDER_LOOP=threaded

import QtQuick
import Quickshell
import "."

/**
 * shell.qml
 * Primary entry point for crazydots.
 *
 * Responsibilities:
 * - Bootstraps the Quickshell Qt Quick runtime with optimized scene graph settings.
 * - Instantiates the top-level ShellRoot container.
 * - Mounts Main.qml coordinator.
 */
ShellRoot {
    id: root

    Main {
        id: main
    }
}
