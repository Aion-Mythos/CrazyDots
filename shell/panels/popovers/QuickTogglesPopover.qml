import QtQuick
import Quickshell
import Quickshell.Services.Pipewire
import "../.."
import "../../components"
import "../../services"

/**
 * QuickTogglesPopover.qml
 * Compact unified quick toggles card for system settings.
 *
 * Responsibilities:
 * - Provides compact interactive toggle capsules for Wi-Fi, Bluetooth, Audio, Mic, and Animations.
 * - Mini-sliders for Volume and Brightness.
 * - Quick launch buttons for Theme Manager and Wallpaper Manager.
 * - Truthfully reflects system status without simulated behavior.
 */
Item {
    id: root

    property bool active: false
    property var networkService: null
    property var brightnessService: null

    readonly property bool isNetAvailable: root.networkService ? root.networkService.isAvailable : false
    readonly property bool isWifiOn: root.networkService ? root.networkService.wifiEnabled : false
    readonly property bool isNetConnected: root.networkService ? root.networkService.isConnected : false
    readonly property string netConnectedSsid: root.networkService ? root.networkService.connectedSsid : ""
    readonly property bool isBtAvailable: root.networkService ? root.networkService.bluetoothAvailable : false
    readonly property bool isBrightAvailable: root.brightnessService ? root.brightnessService.isAvailable : false
    readonly property int brightnessPct: (root.brightnessService && root.isBrightAvailable) ? root.brightnessService.brightnessPercent : 0

    signal closeRequested()
    signal themeManagerRequested()
    signal wallpaperManagerRequested()

    implicitWidth: 350
    implicitHeight: 330

    Keys.onEscapePressed: root.closeRequested()

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property bool isSinkReady: Pipewire.ready && sink !== null && sink.audio !== null
    readonly property real volume: isSinkReady ? sink.audio.volume : 0.0
    readonly property bool isMuted: isSinkReady ? sink.audio.muted : false

    readonly property var source: Pipewire.defaultAudioSource
    readonly property bool isSourceReady: Pipewire.ready && source !== null && source.audio !== null
    readonly property bool isMicMuted: isSourceReady ? source.audio.muted : false

    StyledRect {
        id: card
        anchors.fill: parent
        radius: Tokens.radiusLg
        elevated: true
        color: Theme.alpha(Theme.surfaceElevated, Config.themeOpacity)
        border.color: Theme.alpha(Theme.accent, 0.4)
        border.width: Tokens.borderWidthThin

        MouseArea {
            anchors.fill: parent
        }

        Column {
            anchors.fill: parent
            anchors.margins: Tokens.spaceMd
            spacing: Tokens.spaceSm

            // =================================================================
            // 1. HEADER ROW
            // =================================================================
            Row {
                width: parent.width
                height: 28

                Row {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: Tokens.spaceXs

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "󱐋"
                        font.family: Tokens.fontFamilyMono
                        font.pixelSize: Tokens.fontBase
                        color: Theme.accent
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "QUICK SETTINGS"
                        font.family: Tokens.fontFamilyMono
                        font.pixelSize: Tokens.fontSm
                        font.weight: Tokens.weightBold
                        color: Theme.foreground
                    }
                }

                Item {
                    width: parent.width - 190
                    height: 1
                }

                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    width: 22
                    height: 22
                    radius: Tokens.radiusFull
                    color: closeMouse.containsMouse ? Theme.alpha(Theme.error, 0.2) : "transparent"
                    border.color: closeMouse.containsMouse ? Theme.error : Theme.border
                    border.width: Tokens.borderWidthThin

                    Text {
                        anchors.centerIn: parent
                        text: "✕"
                        font.family: Tokens.fontFamilySans
                        font.pixelSize: Tokens.fontXs
                        color: closeMouse.containsMouse ? Theme.error : Theme.mutedForeground
                    }

                    MouseArea {
                        id: closeMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.closeRequested()
                    }
                }
            }

            // Divider
            Rectangle {
                width: parent.width
                height: Tokens.borderWidthThin
                color: Theme.alpha(Theme.border, 0.4)
            }

            // =================================================================
            // 2. TOGGLE CAPSULES (2x2 GRID)
            // =================================================================
            Grid {
                width: parent.width
                columns: 2
                spacing: Tokens.spaceSm

                // 2.1 Wi-Fi Toggle Capsule
                Rectangle {
                    width: (parent.width - Tokens.spaceSm) / 2
                    height: 44
                    radius: Tokens.radiusMd
                    color: root.isWifiOn ? Theme.alpha(Theme.accent, 0.22) : Theme.alpha(Theme.surface, 0.7)
                    border.color: root.isWifiOn ? Theme.accent : Theme.border
                    border.width: Tokens.borderWidthThin

                    Row {
                        anchors.fill: parent
                        anchors.margins: Tokens.spaceSm
                        spacing: Tokens.spaceSm

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: root.isNetConnected ? "󰤨" : (root.isWifiOn ? "󰤯" : "󰖪")
                            font.family: Tokens.fontFamilyMono
                            font.pixelSize: Tokens.fontBase
                            color: root.isWifiOn ? Theme.accent : Theme.mutedForeground
                        }

                        Column {
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 1
                            width: parent.width - 32

                            Text {
                                text: "Wi-Fi"
                                font.family: Tokens.fontFamilySans
                                font.pixelSize: Tokens.fontSm
                                font.weight: Tokens.weightBold
                                color: root.isWifiOn ? Theme.foreground : Theme.mutedForeground
                            }

                            Text {
                                text: root.isNetConnected ? root.netConnectedSsid : (root.isWifiOn ? "Enabled" : "Off")
                                font.family: Tokens.fontFamilySans
                                font.pixelSize: 10
                                color: Theme.mutedForeground
                                elide: Text.ElideRight
                                width: parent.width
                            }
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (root.networkService) root.networkService.toggleWifi();
                        }
                    }
                }

                // 2.2 Bluetooth Capsule (Truthful status)
                Rectangle {
                    width: (parent.width - Tokens.spaceSm) / 2
                    height: 44
                    radius: Tokens.radiusMd
                    color: root.isBtAvailable ? Theme.alpha(Theme.accent, 0.22) : Theme.alpha(Theme.surface, 0.4)
                    border.color: root.isBtAvailable ? Theme.accent : Theme.border
                    border.width: Tokens.borderWidthThin

                    Row {
                        anchors.fill: parent
                        anchors.margins: Tokens.spaceSm
                        spacing: Tokens.spaceSm

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "󰂯"
                            font.family: Tokens.fontFamilyMono
                            font.pixelSize: Tokens.fontBase
                            color: root.isBtAvailable ? Theme.accent : Theme.mutedForeground
                        }

                        Column {
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 1
                            width: parent.width - 32

                            Text {
                                text: "Bluetooth"
                                font.family: Tokens.fontFamilySans
                                font.pixelSize: Tokens.fontSm
                                font.weight: Tokens.weightBold
                                color: root.isBtAvailable ? Theme.foreground : Theme.mutedForeground
                            }

                            Text {
                                text: root.isBtAvailable ? "Active" : "Inactive"
                                font.family: Tokens.fontFamilySans
                                font.pixelSize: 10
                                color: Theme.mutedForeground
                            }
                        }
                    }
                }

                // 2.3 Audio Mute Capsule
                Rectangle {
                    width: (parent.width - Tokens.spaceSm) / 2
                    height: 44
                    radius: Tokens.radiusMd
                    color: root.isMuted ? Theme.alpha(Theme.warning, 0.22) : Theme.alpha(Theme.surface, 0.7)
                    border.color: root.isMuted ? Theme.warning : Theme.border
                    border.width: Tokens.borderWidthThin

                    Row {
                        anchors.fill: parent
                        anchors.margins: Tokens.spaceSm
                        spacing: Tokens.spaceSm

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: root.isMuted ? "󰝟" : "󰕾"
                            font.family: Tokens.fontFamilyMono
                            font.pixelSize: Tokens.fontBase
                            color: root.isMuted ? Theme.warning : Theme.accent
                        }

                        Column {
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 1
                            width: parent.width - 32

                            Text {
                                text: "Volume"
                                font.family: Tokens.fontFamilySans
                                font.pixelSize: Tokens.fontSm
                                font.weight: Tokens.weightBold
                                color: Theme.foreground
                            }

                            Text {
                                text: root.isMuted ? "Muted" : Math.round(root.volume * 100) + "%"
                                font.family: Tokens.fontFamilySans
                                font.pixelSize: 10
                                color: root.isMuted ? Theme.warning : Theme.mutedForeground
                            }
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (root.isSinkReady) root.sink.audio.muted = !root.sink.audio.muted;
                        }
                    }
                }

                // 2.4 Animations Capsule
                Rectangle {
                    width: (parent.width - Tokens.spaceSm) / 2
                    height: 44
                    radius: Tokens.radiusMd
                    color: Config.animationsEnabled ? Theme.alpha(Theme.accentSecondary, 0.22) : Theme.alpha(Theme.surface, 0.7)
                    border.color: Config.animationsEnabled ? Theme.accentSecondary : Theme.border
                    border.width: Tokens.borderWidthThin

                    Row {
                        anchors.fill: parent
                        anchors.margins: Tokens.spaceSm
                        spacing: Tokens.spaceSm

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: Config.animationsEnabled ? "󰑮" : "󰑯"
                            font.family: Tokens.fontFamilyMono
                            font.pixelSize: Tokens.fontBase
                            color: Config.animationsEnabled ? Theme.accentSecondary : Theme.mutedForeground
                        }

                        Column {
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 1
                            width: parent.width - 32

                            Text {
                                text: "Animations"
                                font.family: Tokens.fontFamilySans
                                font.pixelSize: Tokens.fontSm
                                font.weight: Tokens.weightBold
                                color: Theme.foreground
                            }

                            Text {
                                text: Config.animationsEnabled ? Config.animationSpeed.toFixed(1) + "x Speed" : "Disabled"
                                font.family: Tokens.fontFamilySans
                                font.pixelSize: 10
                                color: Theme.mutedForeground
                            }
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Config.setAnimationsEnabled(!Config.animationsEnabled)
                    }
                }
            }

            // =================================================================
            // 3. MINI SLIDERS (VOLUME & BRIGHTNESS)
            // =================================================================
            Column {
                width: parent.width
                spacing: Tokens.spaceXs

                // Volume mini-track
                Row {
                    width: parent.width
                    spacing: Tokens.spaceSm

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "󰕾"
                        font.family: Tokens.fontFamilyMono
                        font.pixelSize: Tokens.fontSm
                        color: Theme.accent
                    }

                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width - 32
                        height: 8
                        radius: Tokens.radiusFull
                        color: Theme.alpha(Theme.surface, 0.8)
                        clip: true

                        Rectangle {
                            height: parent.height
                            width: parent.width * Math.min(1.0, root.volume)
                            radius: Tokens.radiusFull
                            color: root.isMuted ? Theme.mutedForeground : Theme.accent
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: root.isSinkReady ? Qt.PointingHandCursor : Qt.ArrowCursor
                            onPressed: (mouse) => {
                                if (!root.isSinkReady) return;
                                root.sink.audio.volume = Math.max(0.0, Math.min(1.0, mouse.x / width));
                                if (root.sink.audio.muted) root.sink.audio.muted = false;
                            }
                        }
                    }
                }

                // Brightness mini-track
                Row {
                    width: parent.width
                    spacing: Tokens.spaceSm

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "󰃠"
                        font.family: Tokens.fontFamilyMono
                        font.pixelSize: Tokens.fontSm
                        color: root.isBrightAvailable ? Theme.accent : Theme.mutedForeground
                    }

                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width - 32
                        height: 8
                        radius: Tokens.radiusFull
                        color: Theme.alpha(Theme.surface, 0.8)
                        clip: true

                        Rectangle {
                            height: parent.height
                            width: root.isBrightAvailable ? parent.width * (root.brightnessPct / 100) : 0
                            radius: Tokens.radiusFull
                            color: Theme.accentSecondary
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: root.isBrightAvailable ? Qt.PointingHandCursor : Qt.ArrowCursor
                            onPressed: (mouse) => {
                                if (!root.isBrightAvailable || !root.brightnessService) return;
                                const pct = Math.max(1, Math.min(100, Math.round((mouse.x / width) * 100)));
                                root.brightnessService.setBrightness(pct);
                            }
                        }
                    }
                }
            }

            // =================================================================
            // 4. APPEARANCE ENTRY POINTS
            // =================================================================
            Row {
                width: parent.width
                spacing: Tokens.spaceSm

                Rectangle {
                    width: (parent.width - Tokens.spaceSm) / 2
                    height: 32
                    radius: Tokens.radiusSm
                    color: tmMouse.containsMouse ? Theme.alpha(Theme.accent, 0.2) : Theme.surface
                    border.color: tmMouse.containsMouse ? Theme.accent : Theme.border
                    border.width: Tokens.borderWidthThin

                    Row {
                        anchors.centerIn: parent
                        spacing: Tokens.spaceXs
                        Text { text: "󰔎"; font.family: Tokens.fontFamilyMono; color: Theme.accent; font.pixelSize: Tokens.fontSm }
                        Text { text: "THEMES"; font.family: Tokens.fontFamilyMono; font.pixelSize: 10; font.weight: Tokens.weightBold; color: Theme.foreground }
                    }

                    MouseArea {
                        id: tmMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            root.closeRequested();
                            root.themeManagerRequested();
                        }
                    }
                }

                Rectangle {
                    width: (parent.width - Tokens.spaceSm) / 2
                    height: 32
                    radius: Tokens.radiusSm
                    color: wpmMouse.containsMouse ? Theme.alpha(Theme.accentSecondary, 0.2) : Theme.surface
                    border.color: wpmMouse.containsMouse ? Theme.accentSecondary : Theme.border
                    border.width: Tokens.borderWidthThin

                    Row {
                        anchors.centerIn: parent
                        spacing: Tokens.spaceXs
                        Text { text: "󰸉"; font.family: Tokens.fontFamilyMono; color: Theme.accentSecondary; font.pixelSize: Tokens.fontSm }
                        Text { text: "WALLPAPERS"; font.family: Tokens.fontFamilyMono; font.pixelSize: 10; font.weight: Tokens.weightBold; color: Theme.foreground }
                    }

                    MouseArea {
                        id: wpmMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            root.closeRequested();
                            root.wallpaperManagerRequested();
                        }
                    }
                }
            }
        }
    }
}
