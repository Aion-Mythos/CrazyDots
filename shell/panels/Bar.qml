import QtQuick
import Quickshell
import Quickshell.Wayland
import ".."
import "../components"
import "bar"

/**
 * Bar.qml
 * Desktop bar panel window for crazydots.
 *
 * Responsibilities:
 * - Operates as a dedicated layer-shell surface on WlrLayer.Top.
 * - Claims precise layer-shell exclusive zone so Hyprland tiles windows cleanly.
 * - Manages input masking so clicks outside the floating island pass through to windows.
 * - Accommodates top/bottom position, custom heights, and docked vs floating geometry.
 * - Orchestrates left (launcher, workspaces), center (active title), and right (tray, audio, battery, clock, dashboard) sections.
 */
PanelWindow {
    id: root

    // =========================================================================
    // PUBLIC PROPERTIES & SCREEN BINDING
    // =========================================================================
    required property var screen

    // Signals for coordinating with future shell drawers (Launcher M5, Dashboard M7)
    signal launcherTriggered()
    signal dashboardTriggered()

    // =========================================================================
    // WAYLAND LAYER-SHELL CONFIGURATION
    // =========================================================================
    WlrLayershell.namespace: "crazydots-bar"
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    // Dynamically calculate exclusive space for Hyprland window tiling
    WlrLayershell.exclusiveZone: Config.barHeight + (Config.barFloating ? Config.barMargin * 2 : 0)

    // Anchors determine top vs bottom positioning
    anchors {
        top: Config.barPosition === "top"
        bottom: Config.barPosition === "bottom"
        left: true
        right: true
    }

    // Set implicit height (avoids Qt PanelWindow height deprecation warning)
    implicitHeight: Config.barHeight + (Config.barFloating ? Config.barMargin * 2 : 0)
    color: "transparent"

    // =========================================================================
    // DYNAMIC INPUT MASK
    // Ensures clicks in the floating margin around the island pass through
    // directly to underlying desktop windows.
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
        anchors.top: Config.barPosition === "top" ? parent.top : undefined
        anchors.bottom: Config.barPosition === "bottom" ? parent.bottom : undefined
        anchors.topMargin: Config.barPosition === "top" ? (Config.barFloating ? Config.barMargin : 0) : 0
        anchors.bottomMargin: Config.barPosition === "bottom" ? (Config.barFloating ? Config.barMargin : 0) : 0

        // Horizontal positioning
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: Config.barFloating ? Config.barMargin : 0
        anchors.rightMargin: Config.barFloating ? Config.barMargin : 0

        height: Config.barHeight
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
        // SECTION 1: LEFT CONTROLS (LAUNCHER & WORKSPACES)
        // =====================================================================
        Row {
            id: leftSection
            anchors.left: parent.left
            anchors.leftMargin: Tokens.spaceSm
            anchors.verticalCenter: parent.verticalCenter
            spacing: Tokens.spaceSm

            // Crazydots Launcher Trigger Button
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

                Text {
                    anchors.centerIn: parent
                    text: "󱄅"
                    font.family: Tokens.fontFamilyMono
                    font.pixelSize: Tokens.fontLg
                    color: launcherMouse.containsMouse ? Theme.accent : Theme.foreground
                    renderType: Text.NativeRendering
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
                visible: Config.barShowWorkspaces
            }
        }

        // =====================================================================
        // SECTION 2: CENTER TITLE (ACTIVE WINDOW)
        // =====================================================================
        Item {
            id: centerSection
            anchors.centerIn: parent
            width: activeTitleWidget.implicitWidth
            height: parent.height
            visible: Config.barShowTitle

            ActiveWindow {
                id: activeTitleWidget
                anchors.centerIn: parent
            }
        }

        // =====================================================================
        // SECTION 3: RIGHT CONTROLS (TRAY, AUDIO, BATTERY, CLOCK, DASHBOARD)
        // =====================================================================
        Row {
            id: rightSection
            anchors.right: parent.right
            anchors.rightMargin: Tokens.spaceSm
            anchors.verticalCenter: parent.verticalCenter
            spacing: Tokens.spaceXs

            // System Tray
            TrayWidget {
                id: trayWidget
                anchors.verticalCenter: parent.verticalCenter
                visible: Config.barShowTray
            }

            // Audio Volume Meter & Mute Toggle
            AudioWidget {
                id: audioWidget
                anchors.verticalCenter: parent.verticalCenter
                visible: Config.barShowAudio
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

            // Dashboard / Quick Settings Toggle Button
            Rectangle {
                id: dashboardBtn
                anchors.verticalCenter: parent.verticalCenter
                width: 30
                height: 30
                radius: Tokens.radiusSm
                color: dashMouse.containsMouse ? Theme.alpha(Theme.accent, 0.25) : Theme.alpha(Theme.surfaceElevated, 0.7)
                border.width: Tokens.borderWidthThin
                border.color: dashMouse.containsMouse ? Theme.accent : Theme.border

                Behavior on color {
                    ColorAnimation { duration: Tokens.durationFast }
                }

                Text {
                    anchors.centerIn: parent
                    text: "󰍜"
                    font.family: Tokens.fontFamilyMono
                    font.pixelSize: Tokens.fontBase
                    color: dashMouse.containsMouse ? Theme.accent : Theme.foreground
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
    }
}
