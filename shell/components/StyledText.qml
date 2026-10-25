import QtQuick
import ".."

/**
 * StyledText.qml
 * Themed typography primitive for crazydots.
 *
 * Responsibilities:
 * - Provides standardized text rendering across all UI components.
 * - Automatically applies high-contrast semantic foreground or muted labels.
 * - Supports monospace typography for clocks, code, resource meters, and stats.
 * - Smoothly interpolates color when the active theme changes.
 */
Text {
    id: root

    // =========================================================================
    // PUBLIC PROPERTIES
    // =========================================================================
    property bool muted: false
    property bool monospace: false
    property bool bold: false

    // Visual defaults bound to design tokens and active theme
    color: root.muted ? Theme.mutedForeground : Theme.foreground
    font.family: root.monospace ? Tokens.fontFamilyMono : Tokens.fontFamilySans
    font.pixelSize: Tokens.fontBase
    font.weight: root.bold ? Tokens.weightBold : Tokens.weightNormal
    renderType: Text.NativeRendering

    // Smooth color animation across theme switches
    Behavior on color {
        ColorAnimation {
            duration: Tokens.durationNormal
            easing.type: Tokens.easingStandard.type
            easing.bezierCurve: Tokens.easingStandard.bezierCurve
        }
    }
}
