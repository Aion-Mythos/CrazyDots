import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import "."
import "components"
import "panels"

/**
 * ScreenCanvas.qml
 * Per-monitor static fullscreen layer-shell surface for crazydots.
 *
 * Responsibilities:
 * - Spans the full dimensions of a designated monitor (screen: modelData).
 * - Avoids continuous Wayland window reconfiguration by keeping the layer-shell
 *   surface dimensions permanently static (ExclusionMode.Ignore).
 * - Manages input region masking via Quickshell's Region API:
 *   - Empty regions pass pointer clicks straight through to desktop windows.
 *   - When modal drawers (Launcher, Dashboard) are active, the surface claims pointer
 *     and keyboard focus and displays a dismissible backdrop scrim.
 * - Prevents taking keyboard focus away from desktop windows when idle (keyboardFocus: None).
 */
PanelWindow {
    id: canvas

    // =========================================================================
    // PUBLIC PROPERTIES & SCREEN BINDING
    // =========================================================================
    required property var screen
    property bool launcherOpen: false

    signal launcherCloseRequested()

    // Multi-monitor active screen coordination
    readonly property bool isCurrentMonitor: {
        if (!Hyprland.focusedMonitor) return true;
        const mon = Hyprland.monitorFor(canvas.screen);
        return mon ? (mon.id === Hyprland.focusedMonitor.id) : true;
    }

    readonly property bool isLauncherActive: canvas.launcherOpen && canvas.isCurrentMonitor

    // =========================================================================
    // WINDOW GEOMETRY & WAYLAND LAYER PROPERTIES
    // =========================================================================
    WlrLayershell.namespace: "crazydots-canvas"

    // Fill the target screen completely
    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    // Overlay layer with ignored exclusion mode (zero surface resizes)
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.exclusionMode: ExclusionMode.Ignore

    // Dynamic keyboard focus: Exclusive while launcher is active, None when idle
    WlrLayershell.keyboardFocus: canvas.isLauncherActive ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    // Transparent backdrop allows full desktop visibility
    color: "transparent"

    // =========================================================================
    // DYNAMIC INPUT MASK REGION
    // Controls which areas receive pointer events vs pass-through to apps.
    // When idle, mask is empty, guaranteeing 100% click-through to apps.
    // =========================================================================
    Region { id: emptyMask }
    Region {
        id: launcherMask
        Region { item: launcherScrim }
    }

    mask: canvas.isLauncherActive ? launcherMask : emptyMask

    // =========================================================================
    // 1. MODAL SCRIM BACKDROP
    // Dims the screen and catches clicks outside the launcher dialog to close it.
    // =========================================================================
    Rectangle {
        id: launcherScrim
        anchors.fill: parent
        color: Theme.alpha("#000000", 0.45)
        visible: canvas.isLauncherActive
        opacity: canvas.isLauncherActive ? 1.0 : 0.0

        Behavior on opacity {
            NumberAnimation {
                duration: Tokens.durationNormal * (Config.animationsEnabled ? Config.animationSpeed : 0)
                easing.type: Tokens.easingStandard.type
                easing.bezierCurve: Tokens.easingStandard.bezierCurve
            }
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.ArrowCursor
            onClicked: canvas.launcherCloseRequested()
        }
    }

    // =========================================================================
    // 2. SHELL SLOTS & LAUNCHER MODAL
    // =========================================================================
    Item {
        id: centerSlot
        anchors.centerIn: parent
        width: launcherWidget.implicitWidth
        height: launcherWidget.implicitHeight

        Launcher {
            id: launcherWidget
            anchors.centerIn: parent
            active: canvas.isLauncherActive
            visible: canvas.isLauncherActive
            opacity: canvas.isLauncherActive ? 1.0 : 0.0
            scale: canvas.isLauncherActive ? 1.0 : 0.94

            Behavior on opacity {
                NumberAnimation {
                    duration: Tokens.durationNormal * (Config.animationsEnabled ? Config.animationSpeed : 0)
                    easing.type: Tokens.easingStandard.type
                    easing.bezierCurve: Tokens.easingStandard.bezierCurve
                }
            }

            Behavior on scale {
                NumberAnimation {
                    duration: Tokens.durationNormal * (Config.animationsEnabled ? Config.animationSpeed : 0)
                    easing.type: Tokens.easingSpring.type
                    easing.bezierCurve: Tokens.easingSpring.bezierCurve
                }
            }

            onCloseRequested: canvas.launcherCloseRequested()

            onActiveChanged: {
                if (active) {
                    resetSearch();
                    focusSearch();
                }
            }
        }
    }

    Item {
        id: cornerSlot
        anchors.top: parent.top
        anchors.right: parent.right
        width: Config.dashboardWidth
        height: Config.dashboardHeight
    }
}
