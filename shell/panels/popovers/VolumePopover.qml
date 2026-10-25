import QtQuick
import Quickshell
import Quickshell.Services.Pipewire
import "../.."
import "../../components"

/**
 * VolumePopover.qml
 * Compact contextual popover for Pipewire audio volume and microphone controls.
 *
 * Responsibilities:
 * - Directly binds to Pipewire.defaultAudioSink and defaultAudioSource.
 * - Real-time synchronized volume slider with percentage and glyph feedback.
 * - Single-click output and microphone mute toggling.
 * - Graceful degradation when Pipewire daemon or audio sinks are unavailable.
 */
Item {
    id: root

    property bool active: false
    signal closeRequested()

    implicitWidth: 320
    implicitHeight: 220

    Keys.onEscapePressed: root.closeRequested()

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property bool isSinkReady: Pipewire.ready && sink !== null && sink.audio !== null
    readonly property real volume: isSinkReady ? sink.audio.volume : 0.0
    readonly property bool isMuted: isSinkReady ? sink.audio.muted : false
    readonly property int volumePercent: Math.round(root.volume * 100)

    readonly property var source: Pipewire.defaultAudioSource
    readonly property bool isSourceReady: Pipewire.ready && source !== null && source.audio !== null
    readonly property bool isMicMuted: isSourceReady ? source.audio.muted : false
    readonly property real micVolume: isSourceReady ? source.audio.volume : 0.0

    function toggleMute() {
        if (!root.isSinkReady) return;
        root.sink.audio.muted = !root.sink.audio.muted;
    }

    function toggleMicMute() {
        if (!root.isSourceReady) return;
        root.source.audio.muted = !root.source.audio.muted;
    }

    function setVolume(ratio: real) {
        if (!root.isSinkReady) return;
        const clamped = Math.max(0.0, Math.min(1.0, ratio));
        root.sink.audio.volume = Math.round(clamped * 100) / 100;
        if (root.sink.audio.muted && clamped > 0) {
            root.sink.audio.muted = false;
        }
    }

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
                        text: root.isMuted ? "󰝟" : "󰕾"
                        font.family: Tokens.fontFamilyMono
                        font.pixelSize: Tokens.fontBase
                        color: root.isMuted ? Theme.warning : Theme.accent
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "AUDIO & SOUND"
                        font.family: Tokens.fontFamilyMono
                        font.pixelSize: Tokens.fontSm
                        font.weight: Tokens.weightBold
                        color: Theme.foreground
                    }
                }

                Item {
                    width: parent.width - 180
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
            // 2. OUTPUT VOLUME SLIDER & MUTE
            // =================================================================
            Column {
                width: parent.width
                spacing: Tokens.spaceXs

                Row {
                    width: parent.width
                    Text {
                        text: "Output: " + (root.isSinkReady ? (root.isMuted ? "Muted" : root.volumePercent + "%") : "Unavailable")
                        font.family: Tokens.fontFamilySans
                        font.pixelSize: Tokens.fontSm
                        font.weight: Tokens.weightBold
                        color: root.isMuted ? Theme.warning : Theme.foreground
                    }

                    Item { width: parent.width - 160; height: 1 }

                    Rectangle {
                        width: 54
                        height: 22
                        radius: Tokens.radiusFull
                        color: root.isMuted ? Theme.warning : (muteMouse.containsMouse ? Theme.alpha(Theme.foreground, 0.1) : "transparent")
                        border.color: root.isMuted ? Theme.warning : Theme.border
                        border.width: Tokens.borderWidthThin

                        Text {
                            anchors.centerIn: parent
                            text: root.isMuted ? "UNMUTE" : "MUTE"
                            font.family: Tokens.fontFamilyMono
                            font.pixelSize: 9
                            font.weight: Tokens.weightBold
                            color: root.isMuted ? "#0d0e15" : Theme.foreground
                        }

                        MouseArea {
                            id: muteMouse
                            anchors.fill: parent
                            hoverEnabled: root.isSinkReady
                            cursorShape: root.isSinkReady ? Qt.PointingHandCursor : Qt.ArrowCursor
                            onClicked: root.toggleMute()
                        }
                    }
                }

                // Interactive Slider Track
                Rectangle {
                    id: sliderTrack
                    width: parent.width
                    height: 10
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
                        id: sliderArea
                        anchors.fill: parent
                        hoverEnabled: root.isSinkReady
                        cursorShape: root.isSinkReady ? Qt.PointingHandCursor : Qt.ArrowCursor
                        preventStealing: true

                        function updateFromPosition(mouse) {
                            if (!root.isSinkReady) return;
                            const r = Math.max(0.0, Math.min(1.0, mouse.x / width));
                            root.setVolume(r);
                        }

                        onPressed: (mouse) => updateFromPosition(mouse)
                        onPositionChanged: (mouse) => {
                            if (pressed) updateFromPosition(mouse);
                        }
                    }
                }
            }

            // =================================================================
            // 3. MICROPHONE INPUT MUTE & LEVEL
            // =================================================================
            Rectangle {
                width: parent.width
                height: 48
                radius: Tokens.radiusMd
                color: Theme.alpha(Theme.surface, 0.7)
                border.color: Theme.border
                border.width: Tokens.borderWidthThin

                Row {
                    anchors.fill: parent
                    anchors.margins: Tokens.spaceSm
                    spacing: Tokens.spaceSm

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: root.isMicMuted ? "󰍭" : "󰍬"
                        font.family: Tokens.fontFamilyMono
                        font.pixelSize: Tokens.fontBase
                        color: root.isMicMuted ? Theme.error : Theme.accent
                    }

                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width - 130
                        spacing: 2

                        Text {
                            text: "Microphone"
                            font.family: Tokens.fontFamilySans
                            font.pixelSize: Tokens.fontSm
                            font.weight: Tokens.weightBold
                            color: Theme.foreground
                        }

                        Text {
                            text: {
                                if (!root.isSourceReady) return "No input device";
                                if (root.isMicMuted) return "Microphone Muted";
                                return "Input Active (" + Math.round(root.micVolume * 100) + "%)";
                            }
                            font.family: Tokens.fontFamilySans
                            font.pixelSize: Tokens.fontXs
                            color: root.isMicMuted ? Theme.error : Theme.mutedForeground
                        }
                    }

                    // Mic Toggle Button
                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        width: 54
                        height: 22
                        radius: Tokens.radiusFull
                        color: root.isMicMuted ? Theme.error : (micMouse.containsMouse ? Theme.alpha(Theme.foreground, 0.1) : "transparent")
                        border.color: root.isMicMuted ? Theme.error : Theme.border
                        border.width: Tokens.borderWidthThin

                        Text {
                            anchors.centerIn: parent
                            text: root.isMicMuted ? "UNMUTE" : "MUTE"
                            font.family: Tokens.fontFamilyMono
                            font.pixelSize: 9
                            font.weight: Tokens.weightBold
                            color: root.isMicMuted ? "#ffffff" : Theme.foreground
                        }

                        MouseArea {
                            id: micMouse
                            anchors.fill: parent
                            hoverEnabled: root.isSourceReady
                            cursorShape: root.isSourceReady ? Qt.PointingHandCursor : Qt.ArrowCursor
                            onClicked: root.toggleMicMute()
                        }
                    }
                }
            }
        }
    }
}
