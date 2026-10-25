pragma Singleton
import QtQuick

/**
 * Tokens.qml
 * Centralized design tokens for crazydots.
 *
 * Responsibilities:
 * - Provides standardized spacing, sizing, corner radii, typography, durations, and easing curves.
 * - Guarantees visual consistency across bars, launchers, dashboards, and dialogs.
 * - Prevents arbitrary magic numbers from being scattered across QML components.
 *
 * All values are immutable read-only properties for predictable rendering and high performance.
 */
QtObject {
    id: root

    // =========================================================================
    // SPACING TOKENS (pixels)
    // Used for paddings, margins, and gaps in layouts.
    // =========================================================================
    readonly property int spaceXxs: 2
    readonly property int spaceXs: 4
    readonly property int spaceSm: 8
    readonly property int spaceMd: 12
    readonly property int spaceLg: 16
    readonly property int spaceXl: 24
    readonly property int spaceXxl: 32

    // =========================================================================
    // CORNER RADII (pixels)
    // Standardizes border curvatures across cards, buttons, and sliding panels.
    // =========================================================================
    readonly property int radiusXs: 4
    readonly property int radiusSm: 8
    readonly property int radiusMd: 12
    readonly property int radiusLg: 16
    readonly property int radiusXl: 24
    readonly property int radiusFull: 9999

    // =========================================================================
    // BORDER THICKNESS
    // =========================================================================
    readonly property int borderWidthThin: 1
    readonly property int borderWidthThick: 2

    // =========================================================================
    // TYPOGRAPHY TOKENS
    // Primary and secondary font families and scale hierarchy.
    // =========================================================================
    readonly property string fontFamilyMono: "JetBrainsMono Nerd Font, CaskaydiaCove Nerd Font, monospace"
    readonly property string fontFamilySans: "Adwaita Sans, sans-serif"

    readonly property int fontXs: 10
    readonly property int fontSm: 12
    readonly property int fontBase: 14
    readonly property int fontLg: 16
    readonly property int fontXl: 20
    readonly property int fontTitle: 24

    readonly property int weightNormal: Font.Normal
    readonly property int weightMedium: Font.Medium
    readonly property int weightBold: Font.Bold

    // =========================================================================
    // ANIMATION DURATIONS (milliseconds)
    // Strict, deterministic timing for all interface interactions.
    // =========================================================================
    readonly property int durationInstant: 0
    readonly property int durationFast: 150       // Fast micro-interactions, hover highlights
    readonly property int durationNormal: 280     // Standard palette shifts, fade transitions
    readonly property int durationSpatial: 420    // Geometric movements (sliding panels, list displacements)
    readonly property int durationSlow: 600       // Large surface transitions, full-screen fades

    // =========================================================================
    // EASING CURVES (Cubic Bezier Splines)
    // Bezier control points format: [c1x, c1y, c2x, c2y, endX, endY]
    // =========================================================================

    // Expressive spring with overshoot (y1 = 1.25) for delightful panel opening
    readonly property var springCurve: [0.38, 1.25, 0.22, 1.0, 1.0, 1.0]

    // Swift deceleration curve with zero overshoot for quick, non-distracting dismissal
    readonly property var exitCurve: [0.05, 0.70, 0.10, 1.0, 1.0, 1.0]

    // Standard smooth acceleration/deceleration curve
    readonly property var standardCurve: [0.20, 0.00, 0.00, 1.0, 1.0, 1.0]

    // Convenience objects for direct assignment to NumberAnimation easing
    readonly property var easingSpring: ({
        type: Easing.BezierSpline,
        bezierCurve: root.springCurve
    })

    readonly property var easingExit: ({
        type: Easing.BezierSpline,
        bezierCurve: root.exitCurve
    })

    readonly property var easingStandard: ({
        type: Easing.BezierSpline,
        bezierCurve: root.standardCurve
    })
}
