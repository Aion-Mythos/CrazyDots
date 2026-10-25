import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import "."
import "components"
import "panels"

/**
 * ScreenCanvas.qml
 * Per-monitor static fullscreen layer-shell surface for crazydots.
 *
 * Responsibilities:
 * - Spans the full dimensions of a designated monitor (screen: modelData).
 * - Avoids continuous Wayland window reconfiguration by keeping the layer-shell
 *   surface dimensions permanently static (ExclusionMode.Ignore).
 * - Manages input region masking via Quickshell's Region API:
 *   - Empty regions pass pointer clicks straight through to desktop windows.
 *   - When modal drawers (Launcher, Dashboard) are active, the surface claims pointer
 *     and keyboard focus and displays a dismissible backdrop scrim.
 * - Prevents taking keyboard focus away from desktop windows when idle (keyboardFocus: None).
 */
PanelWindow {
    id: canvas

    // =========================================================================
    // PUBLIC PROPERTIES & SCREEN BINDING
    // =========================================================================
    required property var screen
    property bool launcherOpen: false
    property bool wallpaperManagerOpen: false
    property bool dashboardOpen: false

    signal launcherCloseRequested()
    signal wallpaperManagerCloseRequested()
    signal dashboardCloseRequested()
    signal dynamicColorsRequested(string path)
    signal wallpaperManagerRequested()
    signal terminalLaunchRequested()

    // Multi-monitor active screen coordination
    readonly property bool isCurrentMonitor: {
        if (!Hyprland.focusedMonitor) return true;
        const mon = Hyprland.monitorFor(canvas.screen);
        return mon ? (mon.id === Hyprland.focusedMonitor.id) : true;
    }

    readonly property bool isLauncherActive: canvas.launcherOpen && canvas.isCurrentMonitor
    readonly property bool isWallpaperManagerActive: canvas.wallpaperManagerOpen && canvas.isCurrentMonitor
    readonly property bool isDashboardActive: canvas.dashboardOpen && canvas.isCurrentMonitor
    readonly property bool isModalActive: isLauncherActive || isWallpaperManagerActive || isDashboardActive

    // Geometry margins & bar collision detection
    readonly property int barOffsetTop: (Config.barPosition === "top")
        ? (Config.barHeight + (Config.barFloating ? Config.barMargin * 2 : 0) + Tokens.spaceSm)
        : Tokens.spaceMd

    readonly property int barOffsetBottom: (Config.barPosition === "bottom")
        ? (Config.barHeight + (Config.barFloating ? Config.barMargin * 2 : 0) + Tokens.spaceSm)
        : Tokens.spaceMd

    readonly property int marginHorizontal: Tokens.spaceMd

    // =========================================================================
    // WINDOW GEOMETRY & WAYLAND LAYER PROPERTIES
    // =========================================================================
    WlrLayershell.namespace: "crazydots-canvas"

    // Fill the target screen completely
    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    // Overlay layer with ignored exclusion mode (zero surface resizes)
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.exclusionMode: ExclusionMode.Ignore

    // Dynamic keyboard focus: Exclusive while launcher/wallpaper modal is active, None when idle
    WlrLayershell.keyboardFocus: canvas.isModalActive ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    // Transparent backdrop allows full desktop visibility
    color: "transparent"

    // =========================================================================
    // DYNAMIC INPUT MASK REGION
    // Controls which areas receive pointer events vs pass-through to apps.
    // When idle, mask is empty, guaranteeing 100% click-through to apps.
    // =========================================================================
    Region { id: emptyMask }
    Region {
        id: modalMask
        Region { item: modalScrim }
    }

    mask: canvas.isModalActive ? modalMask : emptyMask

    // =========================================================================
    // 1. MODAL SCRIM BACKDROP
    // Dims the screen and catches clicks outside active modals to close them.
    // =========================================================================
    Rectangle {
        id: modalScrim
        anchors.fill: parent
        color: Theme.alpha("#000000", 0.45)
        visible: canvas.isModalActive
        opacity: canvas.isModalActive ? 1.0 : 0.0

        Behavior on opacity {
            NumberAnimation {
                duration: Tokens.durationNormal * (Config.animationsEnabled ? Config.animationSpeed : 0)
                easing.type: Tokens.easingStandard.type
                easing.bezierCurve: Tokens.easingStandard.bezierCurve
            }
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.ArrowCursor
            onClicked: {
                if (canvas.isLauncherActive) canvas.launcherCloseRequested();
                if (canvas.isWallpaperManagerActive) canvas.wallpaperManagerCloseRequested();
                if (canvas.isDashboardActive) canvas.dashboardCloseRequested();
            }
        }
    }

    // =========================================================================
    // 2. SHELL SLOTS: LAUNCHER & WALLPAPER MANAGER MODALS
    // =========================================================================
    Item {
        id: centerSlot
        anchors.centerIn: parent
        width: canvas.isWallpaperManagerActive ? wallpaperManagerWidget.implicitWidth : launcherWidget.implicitWidth
        height: canvas.isWallpaperManagerActive ? wallpaperManagerWidget.implicitHeight : launcherWidget.implicitHeight

        Launcher {
            id: launcherWidget
            anchors.centerIn: parent
            active: canvas.isLauncherActive
            visible: canvas.isLauncherActive
            opacity: canvas.isLauncherActive ? 1.0 : 0.0
            scale: canvas.isLauncherActive ? 1.0 : 0.94

            Behavior on opacity {
                NumberAnimation {
                    duration: Tokens.durationNormal * (Config.animationsEnabled ? Config.animationSpeed : 0)
                    easing.type: Tokens.easingStandard.type
                    easing.bezierCurve: Tokens.easingStandard.bezierCurve
                }
            }

            Behavior on scale {
                NumberAnimation {
                    duration: Tokens.durationNormal * (Config.animationsEnabled ? Config.animationSpeed : 0)
                    easing.type: Tokens.easingSpring.type
                    easing.bezierCurve: Tokens.easingSpring.bezierCurve
                }
            }

            onCloseRequested: canvas.launcherCloseRequested()

            onActiveChanged: {
                if (active) {
                    resetSearch();
                    focusSearch();
                }
            }
        }

        WallpaperManager {
            id: wallpaperManagerWidget
            anchors.centerIn: parent
            active: canvas.isWallpaperManagerActive
            visible: canvas.isWallpaperManagerActive
            opacity: canvas.isWallpaperManagerActive ? 1.0 : 0.0
            scale: canvas.isWallpaperManagerActive ? 1.0 : 0.94

            Behavior on opacity {
                NumberAnimation {
                    duration: Tokens.durationNormal * (Config.animationsEnabled ? Config.animationSpeed : 0)
                    easing.type: Tokens.easingStandard.type
                    easing.bezierCurve: Tokens.easingStandard.bezierCurve
                }
            }

            Behavior on scale {
                NumberAnimation {
                    duration: Tokens.durationNormal * (Config.animationsEnabled ? Config.animationSpeed : 0)
                    easing.type: Tokens.easingSpring.type
                    easing.bezierCurve: Tokens.easingSpring.bezierCurve
                }
            }

            onCloseRequested: canvas.wallpaperManagerCloseRequested()
            onDynamicColorsExtracted: function(path) {
                canvas.dynamicColorsRequested(path);
            }
        }
    }

    // =========================================================================
    // 3. CORNER DASHBOARD DRAWER
    // Dynamically positioned according to Config.dashboardCorner.
    // =========================================================================
    Item {
        id: cornerSlot

        readonly property bool isTop: Config.dashboardCorner.indexOf("top") !== -1
        readonly property bool isLeft: Config.dashboardCorner.indexOf("left") !== -1

        anchors.top: isTop ? parent.top : undefined
        anchors.bottom: isTop ? undefined : parent.bottom
        anchors.left: isLeft ? parent.left : undefined
        anchors.right: isLeft ? undefined : parent.right

        anchors.topMargin: isTop ? canvas.barOffsetTop : 0
        anchors.bottomMargin: isTop ? 0 : canvas.barOffsetBottom
        anchors.leftMargin: isLeft ? canvas.marginHorizontal : 0
        anchors.rightMargin: isLeft ? 0 : canvas.marginHorizontal

        width: Math.min(Config.dashboardWidth, parent.width - canvas.marginHorizontal * 2)
        height: Math.min(Config.dashboardHeight, parent.height - canvas.barOffsetTop - canvas.barOffsetBottom)

        Dashboard {
            id: dashboardWidget
            anchors.fill: parent
            active: canvas.isDashboardActive
            visible: opacity > 0
            opacity: canvas.isDashboardActive ? 1.0 : 0.0
            y: canvas.isDashboardActive ? 0 : (cornerSlot.isTop ? -16 : 16)

            Behavior on opacity {
                NumberAnimation {
                    duration: Tokens.durationNormal * (Config.animationsEnabled ? Config.animationSpeed : 0)
                    easing.type: Tokens.easingStandard.type
                    easing.bezierCurve: Tokens.easingStandard.bezierCurve
                }
            }

            Behavior on y {
                NumberAnimation {
                    duration: Tokens.durationNormal * (Config.animationsEnabled ? Config.animationSpeed : 0)
                    easing.type: Tokens.easingSpring.type
                    easing.bezierCurve: Tokens.easingSpring.bezierCurve
                }
            }

            onCloseRequested: canvas.dashboardCloseRequested()
            onWallpaperManagerRequested: canvas.wallpaperManagerRequested()
            onTerminalLaunchRequested: canvas.terminalLaunchRequested()

            onActiveChanged: {
                if (active) {
                    forceActiveFocus();
                }
            }
        }
    }
}
