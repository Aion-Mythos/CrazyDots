import QtQuick
import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Widgets
import "../.."
import "../../components"

/**
 * TrayWidget.qml
 * System tray widget hosting StatusNotifierItem (SNI) applets.
 *
 * Responsibilities:
 * - Dynamically enumerates tray items from Quickshell.Services.SystemTray.
 * - Renders application icons via Quickshell.Widgets.IconImage.
 * - Dispatches left-click activation and right-click secondary context actions.
 * - Collapses automatically when no tray items are registered.
 */
Row {
    id: root

    readonly property int itemCount: (SystemTray.items && SystemTray.items.values) ? SystemTray.items.values.length : 0
    visible: root.itemCount > 0
    spacing: Tokens.spaceXs

    Repeater {
        model: SystemTray.items

        delegate: Item {
            id: itemDelegate
            required property var modelData
            required property int index

            width: 26
            height: 26

            Rectangle {
                id: trayItemBg
                anchors.fill: parent
                radius: Tokens.radiusSm
                color: trayMouse.containsMouse ? Theme.alpha(Theme.foreground, 0.12) : "transparent"
                border.width: Tokens.borderWidthThin
                border.color: trayMouse.containsMouse ? Theme.alpha(Theme.accent, 0.4) : "transparent"

                Behavior on color {
                    ColorAnimation { duration: Tokens.durationFast }
                }

                IconImage {
                    id: trayIcon
                    anchors.centerIn: parent
                    implicitSize: 18
                    source: itemDelegate.modelData ? itemDelegate.modelData.icon : ""
                }

                MouseArea {
                    id: trayMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    cursorShape: Qt.PointingHandCursor

                    onClicked: (mouse) => {
                        if (!itemDelegate.modelData) return;
                        if (mouse.button === Qt.LeftButton) {
                            itemDelegate.modelData.activate();
                        } else if (mouse.button === Qt.RightButton) {
                            itemDelegate.modelData.secondaryActivate();
                        }
                    }
                }
            }
        }
    }
}
