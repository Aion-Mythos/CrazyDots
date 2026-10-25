import QtQuick
import Quickshell
import Quickshell.Wayland
import ".."
import "../components"
import "bar"

/**
 * Bar.qml
 * Desktop bar and edge bezel panel window for crazydots.
 *
 * Responsibilities:
 * - Operates as a dedicated layer-shell surface on WlrLayer.Top.
 * - Claims precise layer-shell exclusive zone so Hyprland tiles windows cleanly.
 * - Manages input masking so clicks outside the floating island pass through to windows.
 * - Accommodates top, bottom, and left (vertical dock) positions, custom heights, and docked vs floating geometry.
 * - Orchestrates Iris branding launcher trigger, workspaces, active title, tray, audio, battery, network, quick toggles, clock, and dashboard.
 */
PanelWindow {
    id: root

    // =========================================================================
    // PUBLIC PROPERTIES & SCREEN BINDING
    // =========================================================================
    required property var screen

    // Signals for coordinating shell drawers and popovers
    signal launcherTriggered()
    signal dashboardTriggered()
    signal connectivityTriggered()
    signal volumeTriggered()
    signal quickTogglesTriggered()

    readonly property bool isVertical: Config.barPosition === "left"

    // =========================================================================
    // WAYLAND LAYER-SHELL CONFIGURATION
    // =========================================================================
    WlrLayershell.namespace: "crazydots-bar"
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    // Dynamically calculate exclusive space for Hyprland window tiling
    WlrLayershell.exclusiveZone: Config.barHeight + (Config.barFloating ? Config.barMargin * 2 : 0)

    // Anchors determine top/bottom vs left positioning
    anchors {
        top: root.isVertical || Config.barPosition === "top"
        bottom: root.isVertical || Config.barPosition === "bottom"
        left: true
        right: !root.isVertical
    }

    implicitWidth: root.isVertical ? (Config.barHeight + (Config.barFloating ? Config.barMargin * 2 : 0)) : 0
    implicitHeight: root.isVertical ? 0 : (Config.barHeight + (Config.barFloating ? Config.barMargin * 2 : 0))
    color: "transparent"

    // =========================================================================
    // DYNAMIC INPUT MASK
    // =========================================================================
    mask: Region {
        item: barCard
    }

    // =========================================================================
    // BAR CARD SURFACE
    // Supports floating island capsule or docked screen edge.
    // =========================================================================
    Rectangle {
        id: barCard

        // Vertical positioning
        anchors.top: root.isVertical ? parent.top : (Config.barPosition === "top" ? parent.top : undefined)
        anchors.bottom: root.isVertical ? parent.bottom : (Config.barPosition === "bottom" ? parent.bottom : undefined)
        anchors.topMargin: root.isVertical
            ? (Config.barFloating ? Config.barMargin : 0)
            : (Config.barPosition === "top" ? (Config.barFloating ? Config.barMargin : 0) : 0)
        anchors.bottomMargin: root.isVertical
            ? (Config.barFloating ? Config.barMargin : 0)
            : (Config.barPosition === "bottom" ? (Config.barFloating ? Config.barMargin : 0) : 0)

        // Horizontal positioning
        anchors.left: parent.left
        anchors.right: root.isVertical ? undefined : parent.right
        anchors.leftMargin: Config.barFloating ? Config.barMargin : 0
        anchors.rightMargin: root.isVertical ? 0 : (Config.barFloating ? Config.barMargin : 0)

        width: root.isVertical ? Config.barHeight : undefined
        height: root.isVertical ? undefined : Config.barHeight
        radius: Config.barFloating ? Tokens.radiusLg : 0

        // Theme-derived background with user opacity preference
        color: Theme.alpha(Theme.surface, Config.themeOpacity)
        border.width: Tokens.borderWidthThin
        border.color: Theme.border

        Behavior on color {
            ColorAnimation { duration: Tokens.durationNormal }
        }

        Behavior on border.color {
            ColorAnimation { duration: Tokens.durationNormal }
        }

        // =====================================================================
        // HORIZONTAL BAR: SECTION 1 (LEFT CONTROLS)
        // =====================================================================
        Row {
            id: leftSection
            anchors.left: parent.left
            anchors.leftMargin: Tokens.spaceSm
            anchors.verticalCenter: parent.verticalCenter
            spacing: Tokens.spaceSm
            visible: !root.isVertical

            // Iris Branding Launcher Trigger Button
            Rectangle {
                id: launcherBtn
                anchors.verticalCenter: parent.verticalCenter
                width: 30
                height: 30
                radius: Tokens.radiusFull
                color: launcherMouse.containsMouse ? Theme.alpha(Theme.accent, 0.25) : Theme.alpha(Theme.surfaceElevated, 0.7)
                border.width: Tokens.borderWidthThin
                border.color: launcherMouse.containsMouse ? Theme.accent : Theme.border

                Behavior on color {
                    ColorAnimation { duration: Tokens.durationFast }
                }

                Image {
                    anchors.centerIn: parent
                    width: 20
                    height: 20
                    source: Qt.resolvedUrl("../../assets/iris_logo/iris-small.svg")
                    sourceSize.width: 20
                    sourceSize.height: 20
                }

                MouseArea {
                    id: launcherMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.launcherTriggered()
                }
            }

            // Workspaces Indicator
            Workspaces {
                id: workspacesWidget
                anchors.verticalCenter: parent.verticalCenter
                screen: root.screen
                vertical: false
                visible: Config.barShowWorkspaces
            }
        }

        // =====================================================================
        // HORIZONTAL BAR: SECTION 2 (CENTER ACTIVE TITLE)
        // =====================================================================
        Item {
            id: centerSection
            anchors.centerIn: parent
            width: activeTitleWidget.implicitWidth
            height: parent.height
            visible: !root.isVertical && Config.barShowTitle

            ActiveWindow {
                id: activeTitleWidget
                anchors.centerIn: parent
            }
        }

        // =====================================================================
        // HORIZONTAL BAR: SECTION 3 (RIGHT CONTROLS)
        // =====================================================================
        Row {
            id: rightSection
            anchors.right: parent.right
            anchors.rightMargin: Tokens.spaceSm
            anchors.verticalCenter: parent.verticalCenter
            spacing: Tokens.spaceXs
            visible: !root.isVertical

            // System Tray
            TrayWidget {
                id: trayWidget
                anchors.verticalCenter: parent.verticalCenter
                visible: Config.barShowTray
            }

            // Connectivity / Network Widget Pill
            BarPill {
                id: netPill
                anchors.verticalCenter: parent.verticalCenter
                onClicked: root.connectivityTriggered()

                Row {
                    spacing: Tokens.spaceXs

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "󰖩"
                        font.family: Tokens.fontFamilyMono
                        font.pixelSize: Tokens.fontSm
                        color: Theme.accent
                        renderType: Text.NativeRendering
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "Net"
                        font.family: Tokens.fontFamilySans
                        font.pixelSize: Tokens.fontXs
                        font.weight: Tokens.weightMedium
                        color: Theme.foreground
                        renderType: Text.NativeRendering
                    }
                }
            }

            // Audio Volume Meter & Popover Trigger
            AudioWidget {
                id: audioWidget
                anchors.verticalCenter: parent.verticalCenter
                visible: Config.barShowAudio
                onVolumePopoverRequested: root.volumeTriggered()
            }

            // Battery Status Meter
            BatteryWidget {
                id: batteryWidget
                anchors.verticalCenter: parent.verticalCenter
                visible: Config.barShowBattery
            }

            // Digital Clock & Calendar Date
            ClockWidget {
                id: clockWidget
                anchors.verticalCenter: parent.verticalCenter
                visible: Config.barShowClock
            }

            // Quick Toggles Button
            Rectangle {
                id: quickTogglesBtn
                anchors.verticalCenter: parent.verticalCenter
                width: 30
                height: 30
                radius: Tokens.radiusSm
                color: qtMouse.containsMouse ? Theme.alpha(Theme.accent, 0.25) : Theme.alpha(Theme.surfaceElevated, 0.7)
                border.width: Tokens.borderWidthThin
                border.color: qtMouse.containsMouse ? Theme.accent : Theme.border

                Behavior on color {
                    ColorAnimation { duration: Tokens.durationFast }
                }

                Text {
                    anchors.centerIn: parent
                    text: "󱐋"
                    font.family: Tokens.fontFamilyMono
                    font.pixelSize: Tokens.fontBase
                    color: qtMouse.containsMouse ? Theme.accent : Theme.foreground
                    renderType: Text.NativeRendering
                }

                MouseArea {
                    id: qtMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.quickTogglesTriggered()
                }
            }

            // Full Corner Dashboard Toggle Button
            Rectangle {
                id: dashboardBtn
                anchors.verticalCenter: parent.verticalCenter
                width: 30
                height: 30
                radius: Tokens.radiusSm
                color: dashMouse.containsMouse ? Theme.alpha(Theme.accentSecondary, 0.25) : Theme.alpha(Theme.surfaceElevated, 0.7)
                border.width: Tokens.borderWidthThin
                border.color: dashMouse.containsMouse ? Theme.accentSecondary : Theme.border

                Behavior on color {
                    ColorAnimation { duration: Tokens.durationFast }
                }

                Text {
                    anchors.centerIn: parent
                    text: "󰍜"
                    font.family: Tokens.fontFamilyMono
                    font.pixelSize: Tokens.fontBase
                    color: dashMouse.containsMouse ? Theme.accentSecondary : Theme.foreground
                    renderType: Text.NativeRendering
                }

                MouseArea {
                    id: dashMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.dashboardTriggered()
                }
            }
        }

        // =====================================================================
        // VERTICAL DOCK LAYOUT (when Config.barPosition === "left")
        // Matching launcher_desktop_context.png and edge_controls_reference.png
        // =====================================================================
        Column {
            id: vertTopSection
            anchors.top: parent.top
            anchors.topMargin: Tokens.spaceSm
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: Tokens.spaceSm
            visible: root.isVertical

            // Top Iris Logo Launcher Button
            Rectangle {
                width: 32
                height: 32
                radius: Tokens.radiusFull
                color: vertLauncherMouse.containsMouse ? Theme.alpha(Theme.accent, 0.25) : Theme.alpha(Theme.surfaceElevated, 0.7)
                border.width: Tokens.borderWidthThin
                border.color: vertLauncherMouse.containsMouse ? Theme.accent : Theme.border

                Image {
                    anchors.centerIn: parent
                    width: 22
                    height: 22
                    source: Qt.resolvedUrl("../../assets/iris_logo/iris-small.svg")
                    sourceSize.width: 22
                    sourceSize.height: 22
                }

                MouseArea {
                    id: vertLauncherMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.launcherTriggered()
                }
            }

            // Vertical Workspaces Indicator
            Workspaces {
                anchors.horizontalCenter: parent.horizontalCenter
                screen: root.screen
                vertical: true
                visible: Config.barShowWorkspaces
            }
        }

        Column {
            id: vertBottomSection
            anchors.bottom: parent.bottom
            anchors.bottomMargin: Tokens.spaceSm
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: Tokens.spaceSm
            visible: root.isVertical

            // Net Hotspot Button
            Rectangle {
                width: 32
                height: 32
                radius: Tokens.radiusSm
                color: vertNetMouse.containsMouse ? Theme.alpha(Theme.accent, 0.25) : Theme.alpha(Theme.surfaceElevated, 0.7)
                border.width: Tokens.borderWidthThin
                border.color: vertNetMouse.containsMouse ? Theme.accent : Theme.border

                Text {
                    anchors.centerIn: parent
                    text: "󰖩"
                    font.family: Tokens.fontFamilyMono
                    font.pixelSize: Tokens.fontSm
                    color: Theme.accent
                }

                MouseArea {
                    id: vertNetMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.connectivityTriggered()
                }
            }

            // Volume Hotspot Button
            Rectangle {
                width: 32
                height: 32
                radius: Tokens.radiusSm
                color: vertVolMouse.containsMouse ? Theme.alpha(Theme.accent, 0.25) : Theme.alpha(Theme.surfaceElevated, 0.7)
                border.width: Tokens.borderWidthThin
                border.color: vertVolMouse.containsMouse ? Theme.accent : Theme.border

                Text {
                    anchors.centerIn: parent
                    text: "󰕾"
                    font.family: Tokens.fontFamilyMono
                    font.pixelSize: Tokens.fontSm
                    color: Theme.foreground
                }

                MouseArea {
                    id: vertVolMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.volumeTriggered()
                }
            }

            // Battery / Power Hotspot Button
            Rectangle {
                width: 32
                height: 32
                radius: Tokens.radiusSm
                color: vertBatMouse.containsMouse ? Theme.alpha(Theme.accent, 0.25) : Theme.alpha(Theme.surfaceElevated, 0.7)
                border.width: Tokens.borderWidthThin
                border.color: vertBatMouse.containsMouse ? Theme.accent : Theme.border

                Text {
                    anchors.centerIn: parent
                    text: "󰂄"
                    font.family: Tokens.fontFamilyMono
                    font.pixelSize: Tokens.fontSm
                    color: Theme.success
                }

                MouseArea {
                    id: vertBatMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.quickTogglesTriggered()
                }
            }

            // Quick Toggles Hotspot Button
            Rectangle {
                width: 32
                height: 32
                radius: Tokens.radiusSm
                color: vertQtMouse.containsMouse ? Theme.alpha(Theme.accent, 0.25) : Theme.alpha(Theme.surfaceElevated, 0.7)
                border.width: Tokens.borderWidthThin
                border.color: vertQtMouse.containsMouse ? Theme.accent : Theme.border

                Text {
                    anchors.centerIn: parent
                    text: "󱐋"
                    font.family: Tokens.fontFamilyMono
                    font.pixelSize: Tokens.fontBase
                    color: Theme.accent
                }

                MouseArea {
                    id: vertQtMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.quickTogglesTriggered()
                }
            }

            // Dashboard Hotspot Button
            Rectangle {
                width: 32
                height: 32
                radius: Tokens.radiusSm
                color: vertDashMouse.containsMouse ? Theme.alpha(Theme.accentSecondary, 0.25) : Theme.alpha(Theme.surfaceElevated, 0.7)
                border.width: Tokens.borderWidthThin
                border.color: vertDashMouse.containsMouse ? Theme.accentSecondary : Theme.border

                Text {
                    anchors.centerIn: parent
                    text: "󰍜"
                    font.family: Tokens.fontFamilyMono
                    font.pixelSize: Tokens.fontBase
                    color: Theme.accentSecondary
                }

                MouseArea {
                    id: vertDashMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.dashboardTriggered()
                }
            }
        }
    }
}
