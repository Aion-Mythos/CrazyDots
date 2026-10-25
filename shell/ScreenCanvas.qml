import QtQuick
import Quickshell
import Quickshell.Wayland
import "."
import "components"

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
 *   - When shell panels (Bar, Launcher, Dashboard) are active, their bounds
 *     are added to the mask so they receive touch and mouse interactions.
 * - Prevents taking keyboard focus away from desktop windows when idle (keyboardFocus: None).
 */
PanelWindow {
    id: canvas

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
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    // Transparent backdrop allows full desktop visibility
    color: "transparent"

    // =========================================================================
    // DYNAMIC INPUT MASK REGION
    // Controls which areas receive pointer events vs pass-through to apps.
    // In M3 (shell base), without active drawers, the mask remains empty,
    // guaranteeing that 100% of the desktop area remains click-through.
    // =========================================================================
    mask: Region {
        id: canvasMask

        // Child regions for active panels will be bound in subsequent milestones:
        // Region { item: barContainer }
        // Region { item: launcherModal }
        // Region { item: dashboardDrawer }
    }

    // =========================================================================
    // SHELL SLOTS (PREPARED FOR FUTURE MILESTONES)
    // Placeholder containers establish clear visual boundaries without
    // implementing premature features.
    // =========================================================================
    Item {
        id: barSlot
        anchors.top: Config.barPosition === "top" ? parent.top : undefined
        anchors.bottom: Config.barPosition === "bottom" ? parent.bottom : undefined
        anchors.left: parent.left
        anchors.right: parent.right
        height: Config.barHeight + (Config.barFloating ? Config.barMargin * 2 : 0)
    }

    Item {
        id: centerSlot
        anchors.centerIn: parent
        width: Math.min(parent.width * 0.8, 640)
        height: Math.min(parent.height * 0.8, 480)
    }

    Item {
        id: cornerSlot
        anchors.top: parent.top
        anchors.right: parent.right
        width: Config.dashboardWidth
        height: Config.dashboardHeight
    }
}
