import QtQuick
import Quickshell
import "../.."
import "../../components"
import "../../services"

/**
 * BrightnessPopover.qml
 * Compact contextual popover for display backlight brightness.
 *
 * Responsibilities:
 * - Backed by BrightnessService and brightnessctl.
 * - Real-time synchronized brightness slider with clamp protection.
 * - Truthfully reports unavailable status on systems without backlight hardware.
 */
Item {
    id: root

    property bool active: false
    property var brightnessService: null

    readonly property bool isBrightAvailable: root.brightnessService ? root.brightnessService.isAvailable : false
    readonly property int brightnessPct: (root.brightnessService && root.isBrightAvailable) ? root.brightnessService.brightnessPercent : 0
    readonly property string deviceName: (root.brightnessService && root.brightnessService.deviceName) ? root.brightnessService.deviceName : ""

    signal closeRequested()

    implicitWidth: 320
    implicitHeight: 140

    Keys.onEscapePressed: root.closeRequested()

    StyledRect {
        id: card
        anchors.fill: parent
        radius: Tokens.radiusLg
        elevated: true
        color: Theme.alpha(Theme.surfaceElevated, Config.themeOpacity)
        border.color: Theme.alpha(Theme.accent, 0.4)
        border.width: Tokens.borderWidthThin

        MouseArea {
            anchors.fill: parent
        }

        Column {
            anchors.fill: parent
            anchors.margins: Tokens.spaceMd
            spacing: Tokens.spaceSm

            // =================================================================
            // 1. HEADER ROW
            // =================================================================
            Row {
                width: parent.width
                height: 28

                Row {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: Tokens.spaceXs

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "󰃠"
                        font.family: Tokens.fontFamilyMono
                        font.pixelSize: Tokens.fontBase
                        color: root.isBrightAvailable ? Theme.accent : Theme.mutedForeground
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "DISPLAY BRIGHTNESS"
                        font.family: Tokens.fontFamilyMono
                        font.pixelSize: Tokens.fontSm
                        font.weight: Tokens.weightBold
                        color: Theme.foreground
                    }
                }

                Item {
                    width: parent.width - 210
                    height: 1
                }

                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    width: 22
                    height: 22
                    radius: Tokens.radiusFull
                    color: closeMouse.containsMouse ? Theme.alpha(Theme.error, 0.2) : "transparent"
                    border.color: closeMouse.containsMouse ? Theme.error : Theme.border
                    border.width: Tokens.borderWidthThin

                    Text {
                        anchors.centerIn: parent
                        text: "✕"
                        font.family: Tokens.fontFamilySans
                        font.pixelSize: Tokens.fontXs
                        color: closeMouse.containsMouse ? Theme.error : Theme.mutedForeground
                    }

                    MouseArea {
                        id: closeMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.closeRequested()
                    }
                }
            }

            // Divider
            Rectangle {
                width: parent.width
                height: Tokens.borderWidthThin
                color: Theme.alpha(Theme.border, 0.4)
            }

            // =================================================================
            // 2. SLIDER & PERCENTAGE
            // =================================================================
            Row {
                width: parent.width
                Text {
                    text: root.isBrightAvailable
                        ? ("Brightness: " + root.brightnessPct + "%")
                        : "Backlight Control Unavailable"
                    font.family: Tokens.fontFamilySans
                    font.pixelSize: Tokens.fontSm
                    font.weight: Tokens.weightBold
                    color: root.isBrightAvailable ? Theme.foreground : Theme.mutedForeground
                }

                Item { width: parent.width - 240; height: 1 }

                Text {
                    text: root.deviceName
                    font.family: Tokens.fontFamilyMono
                    font.pixelSize: Tokens.fontXs
                    color: Theme.mutedForeground
                    visible: root.isBrightAvailable
                }
            }

            // Slider Track
            Rectangle {
                id: sliderTrack
                width: parent.width
                height: 10
                radius: Tokens.radiusFull
                color: Theme.alpha(Theme.surface, 0.8)
                clip: true

                Rectangle {
                    height: parent.height
                    width: root.isBrightAvailable
                        ? parent.width * (root.brightnessPct / 100)
                        : 0
                    radius: Tokens.radiusFull
                    color: Theme.accent
                }

                MouseArea {
                    id: sliderArea
                    anchors.fill: parent
                    hoverEnabled: root.isBrightAvailable
                    cursorShape: root.isBrightAvailable ? Qt.PointingHandCursor : Qt.ArrowCursor
                    preventStealing: true

                    function updateFromPosition(mouse) {
                        if (!root.isBrightAvailable || !root.brightnessService) return;
                        const r = Math.max(0.01, Math.min(1.0, mouse.x / width));
                        root.brightnessService.setBrightness(Math.round(r * 100));
                    }

                    onPressed: (mouse) => updateFromPosition(mouse)
                    onPositionChanged: (mouse) => {
                        if (pressed) updateFromPosition(mouse);
                    }
                }
            }
        }
    }
}
