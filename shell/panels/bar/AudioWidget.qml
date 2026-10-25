import QtQuick
import Quickshell
import Quickshell.Services.Pipewire
import "../.."
import "../../components"

/**
 * AudioWidget.qml
 * Audio volume meter and mute toggle widget backed by Pipewire.
 *
 * Responsibilities:
 * - Reactive binding to Pipewire.defaultAudioSink.
 * - Single-click mute / unmute toggle.
 * - Mouse wheel scrolling to adjust output volume in increments.
 * - Visual status glyphs corresponding to volume range and mute state.
 */
BarPill {
    id: root

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property bool isReady: Pipewire.ready && sink !== null
    readonly property real volume: (sink && sink.audio) ? sink.audio.volume : 0.0
    readonly property bool isMuted: (sink && sink.audio) ? sink.audio.muted : false
    readonly property int volumePercent: Math.round(root.volume * 100)

    // Highlight pill when muted
    highlighted: root.isMuted

    // Click toggles mute
    onClicked: {
        if (root.sink && root.sink.audio) {
            root.sink.audio.muted = !root.sink.audio.muted;
        }
    }

    // Wheel adjusts volume
    onWheelScrolled: (wheel) => {
        if (!root.sink || !root.sink.audio) return;
        const step = 0.05;
        const current = root.sink.audio.volume;
        const next = wheel.angleDelta.y > 0 ? (current + step) : (current - step);
        const clamped = Math.max(0.0, Math.min(1.5, Math.round(next * 100) / 100));

        root.sink.audio.volume = clamped;
        if (root.sink.audio.muted && wheel.angleDelta.y > 0) {
            root.sink.audio.muted = false;
        }
    }

    // Dynamic Volume Glyph
    readonly property string volumeIcon: {
        if (root.isMuted) return "󰝟";
        if (root.volumePercent <= 0) return "󰕿";
        if (root.volumePercent < 33) return "󰕿";
        if (root.volumePercent < 66) return "󰖀";
        return "󰕾";
    }

    // Pill content
    Row {
        spacing: Tokens.spaceXs

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: root.volumeIcon
            font.family: Tokens.fontFamilyMono
            font.pixelSize: Tokens.fontSm
            color: root.isMuted ? Theme.warning : Theme.accent
            renderType: Text.NativeRendering
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: {
                if (!root.isReady) return "--%";
                if (root.isMuted) return "Muted";
                return root.volumePercent + "%";
            }
            font.family: Tokens.fontFamilyMono
            font.pixelSize: Tokens.fontSm
            font.weight: Tokens.weightMedium
            color: root.isMuted ? Theme.mutedForeground : Theme.foreground
            renderType: Text.NativeRendering
        }
    }
}
