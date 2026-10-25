import QtQuick
import ".."

/**
 * ButtonBase.qml
 * Accessible base button primitive for crazydots.
 *
 * Responsibilities:
 * - Provides interactive button surface with clear hover, press, and keyboard focus states.
 * - Supports primary (accent-filled) and secondary (outline/elevated) visual styles.
 * - Full keyboard navigation (focus navigation via Tab, activation via Enter or Space).
 * - Smooth state transitions using Tokens.durationFast for immediate tactile feedback.
 */
FocusScope {
    id: root

    // =========================================================================
    // PUBLIC PROPERTIES & SIGNALS
    // =========================================================================
    property string text: ""
    property bool primary: false
    property bool disabled: false

    readonly property bool hovered: mouseArea.containsMouse && !root.disabled
    readonly property bool pressed: mouseArea.pressed && !root.disabled
    readonly property bool focused: root.activeFocus

    signal clicked()

    // Sizing
    implicitWidth: Math.max(88, contentRow.implicitWidth + Tokens.spaceMd * 2)
    implicitHeight: 36
    activeFocusOnTab: !root.disabled

    // =========================================================================
    // BACKGROUND SURFACE
    // =========================================================================
    Rectangle {
        id: bg
        anchors.fill: parent
        radius: Tokens.radiusSm

        // Dynamic background calculation
        color: {
            if (root.disabled) return Theme.alpha(Theme.surface, 0.4);
            if (root.primary) {
                if (root.pressed) return Theme.darken(Theme.accent, 0.15);
                if (root.hovered) return Theme.lighten(Theme.accent, 0.10);
                return Theme.accent;
            } else {
                if (root.pressed) return Theme.darken(Theme.surfaceElevated, 0.10);
                if (root.hovered) return Theme.lighten(Theme.surfaceElevated, 0.08);
                return Theme.surfaceElevated;
            }
        }

        // Dynamic border calculation
        border.width: (root.focused || root.hovered) ? Tokens.borderWidthThick : Tokens.borderWidthThin
        border.color: {
            if (root.focused) return Theme.borderFocus;
            if (root.hovered) return Theme.accent;
            return root.primary ? Theme.accent : Theme.border;
        }

        Behavior on color {
            ColorAnimation { duration: Tokens.durationFast }
        }
        Behavior on border.color {
            ColorAnimation { duration: Tokens.durationFast }
        }
    }

    // =========================================================================
    // BUTTON CONTENT
    // =========================================================================
    Row {
        id: contentRow
        anchors.centerIn: parent
        spacing: Tokens.spaceSm

        Text {
            id: label
            anchors.verticalCenter: parent.verticalCenter
            text: root.text
            font.family: Tokens.fontFamilySans
            font.pixelSize: Tokens.fontBase
            font.weight: root.primary ? Tokens.weightMedium : Tokens.weightNormal
            renderType: Text.NativeRendering

            color: {
                if (root.disabled) return Theme.mutedForeground;
                if (root.primary) return "#0d0e15"; // High contrast text on accent
                if (root.hovered) return Theme.foreground;
                return Theme.foreground;
            }

            Behavior on color {
                ColorAnimation { duration: Tokens.durationFast }
            }
        }
    }

    // =========================================================================
    // INTERACTION HANDLING
    // =========================================================================
    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        enabled: !root.disabled
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            root.forceActiveFocus();
            root.clicked();
        }
    }

    Keys.onReturnPressed: event => {
        if (!root.disabled) {
            root.clicked();
            event.accepted = true;
        }
    }

    Keys.onSpacePressed: event => {
        if (!root.disabled) {
            root.clicked();
            event.accepted = true;
        }
    }
}
