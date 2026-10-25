import QtQuick
import Quickshell
import Quickshell.Services.UPower
import "../.."
import "../../components"

/**
 * BatteryWidget.qml
 * Battery level and charge state indicator backed by UPower.
 *
 * Responsibilities:
 * - Reactive binding to UPower.displayDevice.
 * - Automatically collapses and hides on desktop systems without battery hardware.
 * - Displays battery status icons reflecting charging state and capacity thresholds.
 * - Triggers visual warning when battery level falls below critical threshold.
 */
BarPill {
    id: root

    readonly property var dev: UPower.displayDevice
    readonly property bool isPresent: dev !== null && dev.isPresent
    readonly property real rawPercentage: dev ? dev.percentage : 0.0
    readonly property int batteryPercent: Math.round(root.rawPercentage * 100)
    readonly property int deviceState: dev ? dev.state : 0
    readonly property bool isCharging: root.deviceState === 1 // UPowerDeviceState.Charging
    readonly property bool isLow: !root.isCharging && root.batteryPercent <= 20

    // Gracefully hide on desktops without battery
    visible: root.isPresent

    // Highlight pill on low battery
    highlighted: root.isLow

    // Battery Icon Lookup
    readonly property string batteryIcon: {
        if (root.isCharging) return "󰂄";
        if (root.batteryPercent >= 95) return "󰂅";
        if (root.batteryPercent >= 85) return "󰁹";
        if (root.batteryPercent >= 70) return "󰂁";
        if (root.batteryPercent >= 50) return "󰁿";
        if (root.batteryPercent >= 30) return "󰁽";
        if (root.batteryPercent >= 15) return "󰁻";
        return "󰁺";
    }

    // Pill content
    Row {
        spacing: Tokens.spaceXs

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: root.batteryIcon
            font.family: Tokens.fontFamilyMono
            font.pixelSize: Tokens.fontSm
            color: {
                if (root.isCharging) return Theme.accent;
                if (root.isLow) return Theme.error;
                return Theme.foreground;
            }
            renderType: Text.NativeRendering
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: root.batteryPercent + "%"
            font.family: Tokens.fontFamilyMono
            font.pixelSize: Tokens.fontSm
            font.weight: Tokens.weightMedium
            color: root.isLow ? Theme.error : Theme.foreground
            renderType: Text.NativeRendering
        }
    }
}
