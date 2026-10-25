import QtQuick
import Quickshell
import Quickshell.Hyprland
import "../.."
import "../../components"

/**
 * ActiveWindow.qml
 * Displays the title of the currently focused window with graceful elision.
 *
 * Responsibilities:
 * - Reactive binding to Quickshell.Hyprland.activeToplevel.
 * - Handles empty or desktop states gracefully without visual glitches.
 * - Enforces elision and width bounds to avoid overflowing the center bar area.
 */
Item {
    id: root

    // =========================================================================
    // PUBLIC PROPERTIES
    // =========================================================================
    property int maxTitleWidth: 380

    readonly property var activeWindow: Hyprland.activeToplevel
    readonly property string windowTitle: (activeWindow && activeWindow.title) ? activeWindow.title : ""
    readonly property bool hasWindow: windowTitle.length > 0

    implicitHeight: 28
    implicitWidth: Math.min(contentRow.implicitWidth, root.maxTitleWidth)

    Row {
        id: contentRow
        anchors.verticalCenter: parent.verticalCenter
        spacing: Tokens.spaceSm

        // Active window status indicator dot
        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            width: 6
            height: 6
            radius: Tokens.radiusFull
            color: root.hasWindow ? Theme.accent : Theme.alpha(Theme.mutedForeground, 0.4)

            Behavior on color {
                ColorAnimation { duration: Tokens.durationFast }
            }
        }

        // Window Title
        Text {
            id: titleText
            anchors.verticalCenter: parent.verticalCenter
            width: Math.min(implicitWidth, root.maxTitleWidth - 14)
            elide: Text.ElideRight
            text: root.hasWindow ? root.windowTitle : "Desktop"
            font.family: Tokens.fontFamilySans
            font.pixelSize: Tokens.fontSm
            font.weight: root.hasWindow ? Tokens.weightMedium : Tokens.weightNormal
            color: root.hasWindow ? Theme.foreground : Theme.mutedForeground
            renderType: Text.NativeRendering

            Behavior on color {
                ColorAnimation { duration: Tokens.durationFast }
            }
        }
    }
}
