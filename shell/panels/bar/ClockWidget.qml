import QtQuick
import Quickshell
import "../.."
import "../../components"

/**
 * ClockWidget.qml
 * Digital clock and date widget with zero-jitter monospace layout.
 *
 * Responsibilities:
 * - Uses Quickshell.SystemClock with minute-level precision.
 * - Formats time and calendar date cleanly.
 * - Displays glyph and tooltip information on hover.
 */
BarPill {
    id: root

    // =========================================================================
    // SYSTEM CLOCK
    // =========================================================================
    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    readonly property string timeString: Qt.formatTime(clock.date, "hh:mm")
    readonly property string dateString: Qt.formatDate(clock.date, "ddd, MMM d")
    readonly property string fullDateString: Qt.formatDate(clock.date, "dddd, MMMM d, yyyy")

    // Pill content
    Row {
        spacing: Tokens.spaceXs

        // Clock Icon
        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: "󰥔"
            font.family: Tokens.fontFamilyMono
            font.pixelSize: Tokens.fontSm
            color: Theme.accent
            renderType: Text.NativeRendering
        }

        // Time String (Monospace prevents layout jitter)
        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: root.timeString
            font.family: Tokens.fontFamilyMono
            font.pixelSize: Tokens.fontSm
            font.weight: Tokens.weightBold
            color: Theme.foreground
            renderType: Text.NativeRendering
        }

        // Divider
        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: "•"
            font.pixelSize: Tokens.fontXs
            color: Theme.alpha(Theme.mutedForeground, 0.5)
            renderType: Text.NativeRendering
        }

        // Date String
        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: root.dateString
            font.family: Tokens.fontFamilySans
            font.pixelSize: Tokens.fontSm
            color: Theme.mutedForeground
            renderType: Text.NativeRendering
        }
    }
}
