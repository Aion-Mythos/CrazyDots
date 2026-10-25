import QtQuick
import "../.."
import "../../components"

/**
 * BarPill.qml
 * Unified interactive capsule/pill container for desktop bar widgets.
 *
 * Responsibilities:
 * - Provides consistent capsule styling for status meters, clock, and controls.
 * - Handles hover, press, click, and mouse wheel events.
 * - Adapts dynamically to semantic theme tokens with smooth transitions.
 */
Rectangle {
    id: root

    // =========================================================================
    // PUBLIC PROPERTIES & SIGNALS
    // =========================================================================
    property bool active: false
    property bool interactive: true
    property bool highlighted: false
    property color activeColor: Theme.accent
    property color surfaceColor: Theme.alpha(Theme.surfaceElevated, 0.85)
    property int horizontalPadding: Tokens.spaceSm
    property int verticalPadding: Tokens.spaceXs

    default property alias content: contentSlot.data
    readonly property bool hovered: mouseArea.containsMouse && root.interactive
    readonly property bool pressed: mouseArea.pressed && root.interactive

    signal clicked(var mouse)
    signal wheelScrolled(var wheel)

    // Visual Styling
    radius: Tokens.radiusSm
    implicitHeight: Math.max(28, contentSlot.implicitHeight + root.verticalPadding * 2)
    implicitWidth: contentSlot.implicitWidth + root.horizontalPadding * 2

    color: {
        if (root.active) return root.activeColor;
        if (root.highlighted) return Theme.alpha(Theme.accent, 0.18);
        if (root.pressed) return Theme.darken(root.surfaceColor, 0.12);
        if (root.hovered) return Theme.lighten(root.surfaceColor, 0.08);
        return root.surfaceColor;
    }

    border.width: Tokens.borderWidthThin
    border.color: {
        if (root.active) return root.activeColor;
        if (root.hovered || root.highlighted) return Theme.alpha(Theme.accent, 0.6);
        return Theme.border;
    }

    Behavior on color {
        ColorAnimation {
            duration: Tokens.durationFast
            easing.type: Tokens.easingStandard.type
            easing.bezierCurve: Tokens.easingStandard.bezierCurve
        }
    }

    Behavior on border.color {
        ColorAnimation {
            duration: Tokens.durationFast
            easing.type: Tokens.easingStandard.type
            easing.bezierCurve: Tokens.easingStandard.bezierCurve
        }
    }

    // =========================================================================
    // INNER CONTENT SLOT
    // =========================================================================
    Item {
        id: contentSlot
        anchors.centerIn: parent
        width: childrenRect.width
        height: childrenRect.height
        implicitWidth: childrenRect.width
        implicitHeight: childrenRect.height
    }

    // =========================================================================
    // POINTER INTERACTION AREA
    // =========================================================================
    MouseArea {
        id: mouseArea
        anchors.fill: parent
        enabled: root.interactive
        hoverEnabled: root.interactive
        cursorShape: root.interactive ? Qt.PointingHandCursor : Qt.ArrowCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton

        onClicked: (mouse) => {
            root.clicked(mouse);
        }

        onWheel: (wheel) => {
            root.wheelScrolled(wheel);
        }
    }
}
