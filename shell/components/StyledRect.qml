import QtQuick
import ".."

/**
 * StyledRect.qml
 * Themed container primitive for crazydots.
 *
 * Responsibilities:
 * - Provides consistent card and panel styling using Theme semantic tokens.
 * - Supports elevated background mode for modals, dropdowns, and highlighted surfaces.
 * - Smoothly animates color and border transitions when theme palettes shift.
 */
Rectangle {
    id: root

    // =========================================================================
    // PUBLIC PROPERTIES
    // =========================================================================
    property bool elevated: false
    property bool bordered: true
    property bool clickable: false

    // Geometry & visual defaults from design tokens
    radius: Tokens.radiusMd
    color: root.elevated ? Theme.surfaceElevated : Theme.surface
    border.color: Theme.border
    border.width: root.bordered ? Tokens.borderWidthThin : 0

    // =========================================================================
    // REACTIVE COLOR TRANSITIONS
    // Interpolates color changes smoothly across palette shifts.
    // =========================================================================
    Behavior on color {
        ColorAnimation {
            duration: Tokens.durationNormal
            easing.type: Tokens.easingStandard.type
            easing.bezierCurve: Tokens.easingStandard.bezierCurve
        }
    }

    Behavior on border.color {
        ColorAnimation {
            duration: Tokens.durationNormal
            easing.type: Tokens.easingStandard.type
            easing.bezierCurve: Tokens.easingStandard.bezierCurve
        }
    }
}
