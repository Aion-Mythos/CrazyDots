import QtQuick
import Quickshell
import Quickshell.Hyprland
import "../.."
import "../../components"

/**
 * Workspaces.qml
 * Hyprland workspace indicator widget with elastic pill animations.
 *
 * Responsibilities:
 * - Queries and monitors Hyprland workspaces for the active screen.
 * - Filters out special workspaces (negative IDs) and sorts by index.
 * - Provides immediate tactile visual feedback for active and focused states.
 * - Supports direct workspace switching on click and edge cycling on mouse scroll.
 */
Item {
    id: root

    // =========================================================================
    // PUBLIC PROPERTIES
    // =========================================================================
    property var screen: null
    property bool vertical: false
    readonly property var currentMonitor: root.screen ? Hyprland.monitorFor(root.screen) : null

    implicitHeight: root.vertical ? (workspaceLayout.implicitHeight || 28) : 28
    implicitWidth: root.vertical ? 28 : (workspaceLayout.implicitWidth || 28)

    // Sorted and filtered list of visible workspaces
    readonly property var visibleWorkspaces: {
        const raw = Hyprland.workspaces.values;
        if (!raw || raw.length === 0) return [];

        const list = [];
        for (let i = 0; i < raw.length; i++) {
            const ws = raw[i];
            // Filter out special workspaces (negative IDs like special:music)
            if (ws.id > 0) {
                // If monitor is known, match against current monitor
                if (root.currentMonitor && ws.monitor) {
                    if (ws.monitor.id === root.currentMonitor.id) {
                        list.push(ws);
                    }
                } else {
                    list.push(ws);
                }
            }
        }

        // Sort ascending by workspace ID
        list.sort((a, b) => a.id - b.id);
        return list;
    }

    // =========================================================================
    // WORKSPACE PILLS GRID (ADAPTIVE HORIZONTAL / VERTICAL)
    // =========================================================================
    Grid {
        id: workspaceLayout
        anchors.centerIn: parent
        columns: root.vertical ? 1 : Math.max(1, root.visibleWorkspaces.length)
        rows: root.vertical ? Math.max(1, root.visibleWorkspaces.length) : 1
        spacing: Tokens.spaceXs

        Repeater {
            model: root.visibleWorkspaces

            delegate: Item {
                id: pillDelegate
                required property var modelData
                required property int index

                readonly property var ws: modelData
                readonly property bool isFocused: {
                    if (ws.focused) return true;
                    if (Hyprland.focusedWorkspace && Hyprland.focusedWorkspace.id === ws.id) return true;
                    return false;
                }
                readonly property bool isActive: ws.active || isFocused

                width: pillRect.width
                height: pillRect.height

                Rectangle {
                    id: pillRect
                    anchors.centerIn: parent
                    // Elastic pill sizing: expands smoothly on active
                    width: root.vertical ? 20 : (pillDelegate.isFocused ? 28 : (pillMouse.containsMouse ? 20 : 12))
                    height: root.vertical ? (pillDelegate.isFocused ? 28 : (pillMouse.containsMouse ? 20 : 12)) : 20
                    radius: Tokens.radiusFull

                    color: {
                        if (pillDelegate.isFocused) return Theme.accent;
                        if (pillDelegate.isActive) return Theme.alpha(Theme.accent, 0.45);
                        if (pillMouse.containsMouse) return Theme.alpha(Theme.foreground, 0.35);
                        return Theme.alpha(Theme.foreground, 0.15);
                    }

                    border.width: Tokens.borderWidthThin
                    border.color: pillDelegate.isFocused ? Theme.accent : Theme.alpha(Theme.border, 0.6)

                    // Elastic spring transition when size changes
                    Behavior on width {
                        NumberAnimation {
                            duration: Tokens.durationNormal
                            easing.type: Tokens.easingSpring.type
                            easing.bezierCurve: Tokens.easingSpring.bezierCurve
                        }
                    }

                    Behavior on height {
                        NumberAnimation {
                            duration: Tokens.durationNormal
                            easing.type: Tokens.easingSpring.type
                            easing.bezierCurve: Tokens.easingSpring.bezierCurve
                        }
                    }

                    Behavior on color {
                        ColorAnimation {
                            duration: Tokens.durationFast
                            easing.type: Tokens.easingStandard.type
                            easing.bezierCurve: Tokens.easingStandard.bezierCurve
                        }
                    }

                    // Workspace number / glyph
                    Text {
                        anchors.centerIn: parent
                        text: pillDelegate.ws.name ? pillDelegate.ws.name : String(pillDelegate.ws.id)
                        font.family: Tokens.fontFamilyMono
                        font.pixelSize: Tokens.fontXs
                        font.weight: pillDelegate.isFocused ? Tokens.weightBold : Tokens.weightNormal
                        visible: pillDelegate.isFocused || pillRect.width >= 20
                        renderType: Text.NativeRendering
                        color: pillDelegate.isFocused ? "#0d0e15" : Theme.foreground
                    }

                    MouseArea {
                        id: pillMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor

                        onClicked: {
                            if (pillDelegate.ws && typeof pillDelegate.ws.activate === "function") {
                                pillDelegate.ws.activate();
                            } else {
                                Hyprland.dispatch("workspace " + pillDelegate.ws.id);
                            }
                        }
                    }
                }
            }
        }
    }

    // =========================================================================
    // MOUSE WHEEL WORKSPACE SWITCHING
    // =========================================================================
    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.NoButton
        propagateComposedEvents: true

        onWheel: (wheel) => {
            if (wheel.angleDelta.y > 0) {
                Hyprland.dispatch("workspace e-1");
            } else if (wheel.angleDelta.y < 0) {
                Hyprland.dispatch("workspace e+1");
            }
        }
    }
}
