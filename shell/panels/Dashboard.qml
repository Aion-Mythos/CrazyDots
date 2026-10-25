import QtQuick
import Quickshell
import Quickshell.Services.Pipewire
import Quickshell.Services.UPower
import ".."
import "../components"

/**
 * Dashboard.qml
 * Native corner dashboard and quick settings panel for crazydots.
 *
 * Responsibilities:
 * - Slides in from the configured corner (top-right, top-left, bottom-right, bottom-left).
 * - Displays truthful system status:
 *   - Pipewire audio volume slider, percentage, and mute toggle.
 *   - UPower battery percentage, charging state, or AC power fallback.
 *   - Current time and full calendar date via SystemClock.
 *   - Built-in theme selector with instant switching and persistence.
 *   - Current wallpaper information and quick launcher for WallpaperManager.
 *   - Animation enable/disable toggle and speed multiplier controls.
 * - Handles missing or unavailable hardware/services gracefully.
 * - Restores focus and passes keyboard/mouse events when closed.
 */
Item {
    id: root

    // =========================================================================
    // PUBLIC PROPERTIES & SIGNALS
    // =========================================================================
    property bool active: false

    signal closeRequested()
    signal themeManagerRequested()
    signal wallpaperManagerRequested()
    signal terminalLaunchRequested()

    implicitWidth: Config.dashboardWidth
    implicitHeight: Config.dashboardHeight

    // Keyboard focus & escape key handling
    Keys.onEscapePressed: root.closeRequested()

    // =========================================================================
    // SERVICE INTEGRATIONS (TRUTHFUL BINDINGS)
    // =========================================================================

    // 1. Pipewire Audio
    readonly property var audioSink: Pipewire.defaultAudioSink
    readonly property bool isAudioReady: Pipewire.ready && audioSink !== null && audioSink.audio !== null
    readonly property real audioVolume: isAudioReady ? audioSink.audio.volume : 0.0
    readonly property bool isAudioMuted: isAudioReady ? audioSink.audio.muted : false
    readonly property int audioPercent: Math.round(root.audioVolume * 100)

    function toggleAudioMute() {
        if (!root.isAudioReady) return;
        root.audioSink.audio.muted = !root.audioSink.audio.muted;
    }

    function setVolumeRatio(ratio: real) {
        if (!root.isAudioReady) return;
        const clamped = Math.max(0.0, Math.min(1.0, ratio));
        root.audioSink.audio.volume = Math.round(clamped * 100) / 100;
        if (root.audioSink.audio.muted && clamped > 0) {
            root.audioSink.audio.muted = false;
        }
    }

    readonly property string volumeGlyph: {
        if (!root.isAudioReady) return "󰝟";
        if (root.isAudioMuted) return "󰝟";
        if (root.audioPercent <= 0) return "󰕿";
        if (root.audioPercent < 33) return "󰕿";
        if (root.audioPercent < 66) return "󰖀";
        return "󰕾";
    }

    // 2. UPower Battery
    readonly property var batteryDev: UPower.displayDevice
    readonly property bool hasBattery: batteryDev !== null && batteryDev.isPresent
    readonly property real batteryRaw: hasBattery ? batteryDev.percentage : 0.0
    readonly property int batteryPercent: Math.round(root.batteryRaw * 100)
    readonly property int batteryState: hasBattery ? batteryDev.state : 0
    readonly property bool isBatteryCharging: root.batteryState === 1
    readonly property bool isBatteryLow: !root.isBatteryCharging && root.batteryPercent <= 20

    readonly property string batteryGlyph: {
        if (!root.hasBattery) return "󰚥";
        if (root.isBatteryCharging) return "󰂄";
        if (root.batteryPercent >= 95) return "󰂅";
        if (root.batteryPercent >= 85) return "󰁹";
        if (root.batteryPercent >= 70) return "󰂁";
        if (root.batteryPercent >= 50) return "󰁿";
        if (root.batteryPercent >= 30) return "󰁽";
        if (root.batteryPercent >= 15) return "󰁻";
        return "󰁺";
    }

    // 3. System Clock
    SystemClock {
        id: sysClock
        precision: SystemClock.Minutes
    }

    readonly property string timeString: Qt.formatTime(sysClock.date, "hh:mm")
    readonly property string fullDateString: Qt.formatDate(sysClock.date, "dddd, MMMM d, yyyy")

    // =========================================================================
    // VISUAL CONTAINER CARD
    // =========================================================================
    StyledRect {
        id: card
        anchors.fill: parent
        radius: Tokens.radiusLg
        elevated: true
        color: Theme.alpha(Theme.surfaceElevated, Config.themeOpacity)
        border.color: Theme.alpha(Theme.accent, 0.4)
        border.width: Tokens.borderWidthThin

        // MouseArea consumes clicks to prevent fall-through to backdrop scrim
        MouseArea {
            anchors.fill: parent
        }

        // Scrollable content area to prevent viewport overflow
        Flickable {
            id: scrollArea
            anchors.fill: parent
            anchors.margins: Tokens.spaceMd
            contentHeight: contentCol.height + Tokens.spaceMd
            clip: true
            boundsBehavior: Flickable.StopAtBounds

            Column {
                id: contentCol
                width: scrollArea.width
                spacing: Tokens.spaceMd

                // -------------------------------------------------------------
                // 1. HEADER ROW: TIME, DATE & DISMISS BUTTON
                // -------------------------------------------------------------
                Row {
                    width: parent.width
                    height: 48

                    Column {
                        width: parent.width - 40
                        spacing: 2

                        Text {
                            text: root.timeString
                            font.family: Tokens.fontFamilyMono
                            font.pixelSize: Tokens.fontXl
                            font.weight: Tokens.weightBold
                            color: Theme.foreground
                            renderType: Text.NativeRendering
                        }

                        Text {
                            text: root.fullDateString
                            font.family: Tokens.fontFamilySans
                            font.pixelSize: Tokens.fontXs
                            color: Theme.mutedForeground
                            renderType: Text.NativeRendering
                        }
                    }

                    // Close Button
                    Rectangle {
                        width: 32
                        height: 32
                        radius: Tokens.radiusFull
                        color: closeMouse.containsMouse ? Theme.alpha(Theme.foreground, 0.15) : "transparent"

                        Text {
                            anchors.centerIn: parent
                            text: "✕"
                            font.family: Tokens.fontFamilySans
                            font.pixelSize: Tokens.fontSm
                            color: Theme.mutedForeground
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
                    color: Theme.alpha(Theme.border, 0.5)
                }

                // -------------------------------------------------------------
                // 2. QUICK STATUS OVERVIEW: AUDIO & BATTERY
                // -------------------------------------------------------------
                Column {
                    width: parent.width
                    spacing: Tokens.spaceSm

                    // Section Title
                    Text {
                        text: "AUDIO & HARDWARE"
                        font.family: Tokens.fontFamilyMono
                        font.pixelSize: Tokens.fontXs
                        font.weight: Tokens.weightBold
                        color: Theme.mutedForeground
                    }

                    // Audio Volume Card
                    Rectangle {
                        width: parent.width
                        height: 64
                        radius: Tokens.radiusSm
                        color: Theme.alpha(Theme.surface, 0.7)
                        border.color: Theme.border
                        border.width: Tokens.borderWidthThin

                        Column {
                            anchors.fill: parent
                            anchors.margins: Tokens.spaceSm
                            spacing: Tokens.spaceXs

                            // Label & Mute Button Row
                            Row {
                                width: parent.width
                                height: 22

                                Row {
                                    width: parent.width - 64
                                    spacing: Tokens.spaceXs
                                    anchors.verticalCenter: parent.verticalCenter

                                    Text {
                                        text: root.volumeGlyph
                                        font.family: Tokens.fontFamilyMono
                                        font.pixelSize: Tokens.fontSm
                                        color: root.isAudioMuted ? Theme.warning : Theme.accent
                                    }

                                    Text {
                                        text: {
                                            if (!root.isAudioReady) return "Pipewire Unavailable";
                                            if (root.isAudioMuted) return "Volume Muted";
                                            return "Volume: " + root.audioPercent + "%";
                                        }
                                        font.family: Tokens.fontFamilySans
                                        font.pixelSize: Tokens.fontXs
                                        font.weight: Tokens.weightMedium
                                        color: Theme.foreground
                                    }
                                }

                                // Mute Toggle Pill
                                Rectangle {
                                    width: 58
                                    height: 20
                                    radius: Tokens.radiusFull
                                    anchors.verticalCenter: parent.verticalCenter
                                    color: root.isAudioMuted ? Theme.warning : (muteMouse.containsMouse ? Theme.alpha(Theme.foreground, 0.1) : "transparent")
                                    border.color: root.isAudioMuted ? Theme.warning : Theme.border
                                    border.width: Tokens.borderWidthThin

                                    Text {
                                        anchors.centerIn: parent
                                        text: root.isAudioMuted ? "UNMUTE" : "MUTE"
                                        font.family: Tokens.fontFamilyMono
                                        font.pixelSize: 9
                                        font.weight: Tokens.weightBold
                                        color: root.isAudioMuted ? "#0d0e15" : Theme.foreground
                                    }

                                    MouseArea {
                                        id: muteMouse
                                        anchors.fill: parent
                                        hoverEnabled: root.isAudioReady
                                        cursorShape: root.isAudioReady ? Qt.PointingHandCursor : Qt.ArrowCursor
                                        onClicked: root.toggleAudioMute()
                                    }
                                }
                            }

                            // Interactive Volume Slider Track
                            Rectangle {
                                id: sliderTrack
                                width: parent.width
                                height: 8
                                radius: Tokens.radiusFull
                                color: Theme.alpha(Theme.surfaceElevated, 0.8)
                                clip: true

                                // Filled Portion
                                Rectangle {
                                    height: parent.height
                                    width: parent.width * Math.max(0.0, Math.min(1.0, root.audioVolume))
                                    radius: Tokens.radiusFull
                                    color: root.isAudioMuted ? Theme.mutedForeground : Theme.accent

                                    Behavior on width {
                                        NumberAnimation {
                                            duration: Tokens.durationFast * (Config.animationsEnabled ? Config.animationSpeed : 0)
                                        }
                                    }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    hoverEnabled: root.isAudioReady
                                    cursorShape: root.isAudioReady ? Qt.PointingHandCursor : Qt.ArrowCursor

                                    onClicked: (mouse) => {
                                        if (root.isAudioReady) {
                                            root.setVolumeRatio(mouse.x / width);
                                        }
                                    }

                                    onPositionChanged: (mouse) => {
                                        if (pressed && root.isAudioReady) {
                                            root.setVolumeRatio(mouse.x / width);
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // Battery / Power Status Card
                    Rectangle {
                        width: parent.width
                        height: 44
                        radius: Tokens.radiusSm
                        color: Theme.alpha(Theme.surface, 0.7)
                        border.color: root.isBatteryLow ? Theme.error : Theme.border
                        border.width: Tokens.borderWidthThin

                        Row {
                            anchors.fill: parent
                            anchors.margins: Tokens.spaceSm
                            spacing: Tokens.spaceSm

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: root.batteryGlyph
                                font.family: Tokens.fontFamilyMono
                                font.pixelSize: Tokens.fontBase
                                color: {
                                    if (root.isBatteryLow) return Theme.error;
                                    if (root.isBatteryCharging) return Theme.accent;
                                    return Theme.foreground;
                                }
                            }

                            Column {
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 2

                                Text {
                                    text: {
                                        if (!root.hasBattery) return "AC Power Connected";
                                        return "Battery: " + root.batteryPercent + "%" + (root.isBatteryCharging ? " (Charging)" : "");
                                    }
                                    font.family: Tokens.fontFamilySans
                                    font.pixelSize: Tokens.fontXs
                                    font.weight: Tokens.weightMedium
                                    color: root.isBatteryLow ? Theme.error : Theme.foreground
                                }

                                Text {
                                    text: {
                                        if (!root.hasBattery) return "Desktop Workstation (No battery)";
                                        if (root.isBatteryCharging) return "Power adapter connected";
                                        if (root.isBatteryLow) return "Low battery warning";
                                        return "Discharging on battery power";
                                    }
                                    font.family: Tokens.fontFamilySans
                                    font.pixelSize: 10
                                    color: Theme.mutedForeground
                                }
                            }
                        }
                    }
                }

                // Divider
                Rectangle {
                    width: parent.width
                    height: Tokens.borderWidthThin
                    color: Theme.alpha(Theme.border, 0.5)
                }

                // -------------------------------------------------------------
                // 3. APPEARANCE & THEME SECTION
                // -------------------------------------------------------------
                Column {
                    width: parent.width
                    spacing: Tokens.spaceSm

                    Row {
                        width: parent.width
                        Text {
                            text: "APPEARANCE & THEME"
                            font.family: Tokens.fontFamilyMono
                            font.pixelSize: Tokens.fontXs
                            font.weight: Tokens.weightBold
                            color: Theme.mutedForeground
                        }

                        Item { width: 1; height: 1 }

                        Text {
                            text: Theme.activeThemeDisplayName
                            font.family: Tokens.fontFamilySans
                            font.pixelSize: Tokens.fontXs
                            color: Theme.accent
                            elide: Text.ElideRight
                            width: parent.width - 140
                            horizontalAlignment: Text.AlignRight
                        }
                    }

                    Rectangle {
                        width: parent.width
                        height: 48
                        radius: Tokens.radiusSm
                        color: Theme.alpha(Theme.surface, 0.7)
                        border.color: Theme.border
                        border.width: Tokens.borderWidthThin

                        Row {
                            anchors.fill: parent
                            anchors.margins: Tokens.spaceSm
                            spacing: Tokens.spaceSm

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: "󰔎"
                                font.family: Tokens.fontFamilyMono
                                font.pixelSize: Tokens.fontLg
                                color: Theme.accent
                            }

                            Column {
                                anchors.verticalCenter: parent.verticalCenter
                                width: parent.width - 150
                                spacing: 1

                                Text {
                                    text: "Theme Manager"
                                    font.family: Tokens.fontFamilySans
                                    font.pixelSize: Tokens.fontSm
                                    font.weight: Tokens.weightBold
                                    color: Theme.foreground
                                }

                                Text {
                                    text: "Presets, swatches & dynamic palettes"
                                    font.family: Tokens.fontFamilySans
                                    font.pixelSize: 10
                                    color: Theme.mutedForeground
                                }
                            }

                            // Open Button
                            Rectangle {
                                anchors.verticalCenter: parent.verticalCenter
                                width: 70
                                height: 26
                                radius: Tokens.radiusFull
                                color: tmBtnMouse.containsMouse ? Theme.alpha(Theme.accent, 0.2) : Theme.surface
                                border.color: tmBtnMouse.containsMouse ? Theme.accent : Theme.border
                                border.width: Tokens.borderWidthThin

                                Text {
                                    anchors.centerIn: parent
                                    text: "MANAGE"
                                    font.family: Tokens.fontFamilyMono
                                    font.pixelSize: 9
                                    font.weight: Tokens.weightBold
                                    color: Theme.accent
                                }

                                MouseArea {
                                    id: tmBtnMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        root.closeRequested();
                                        root.themeManagerRequested();
                                    }
                                }
                            }
                        }
                    }
                }

                // Divider
                Rectangle {
                    width: parent.width
                    height: Tokens.borderWidthThin
                    color: Theme.alpha(Theme.border, 0.5)
                }

                // -------------------------------------------------------------
                // 4. WALLPAPER & DYNAMIC THEME ACCESS
                // -------------------------------------------------------------
                Column {
                    width: parent.width
                    spacing: Tokens.spaceSm

                    Text {
                        text: "WALLPAPER & BACKGROUND"
                        font.family: Tokens.fontFamilyMono
                        font.pixelSize: Tokens.fontXs
                        font.weight: Tokens.weightBold
                        color: Theme.mutedForeground
                    }

                    Rectangle {
                        width: parent.width
                        height: 48
                        radius: Tokens.radiusSm
                        color: Theme.alpha(Theme.surface, 0.7)
                        border.color: Theme.border
                        border.width: Tokens.borderWidthThin

                        Row {
                            anchors.fill: parent
                            anchors.margins: Tokens.spaceSm
                            spacing: Tokens.spaceSm

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: "󰸉"
                                font.family: Tokens.fontFamilyMono
                                font.pixelSize: Tokens.fontLg
                                color: Theme.accent
                            }

                            Column {
                                anchors.verticalCenter: parent.verticalCenter
                                width: parent.width - 130
                                spacing: 2

                                Text {
                                    text: Config.wallpaperCurrent ? Config.wallpaperCurrent.split("/").pop() : "Solid Theme Background"
                                    font.family: Tokens.fontFamilySans
                                    font.pixelSize: Tokens.fontXs
                                    font.weight: Tokens.weightMedium
                                    color: Theme.foreground
                                    elide: Text.ElideMiddle
                                    width: parent.width
                                }

                                Text {
                                    text: "Mode: " + Config.wallpaperMode.toUpperCase()
                                    font.family: Tokens.fontFamilyMono
                                    font.pixelSize: 10
                                    color: Theme.mutedForeground
                                }
                            }

                            // Open Wallpaper Manager Button
                            ButtonBase {
                                anchors.verticalCenter: parent.verticalCenter
                                text: "Manage..."
                                primary: false
                                onClicked: {
                                    root.closeRequested();
                                    root.wallpaperManagerRequested();
                                }
                            }
                        }
                    }
                }

                // Divider
                Rectangle {
                    width: parent.width
                    height: Tokens.borderWidthThin
                    color: Theme.alpha(Theme.border, 0.5)
                }

                // -------------------------------------------------------------
                // 5. TERMINAL INTEGRATION (GHOSTTY)
                // -------------------------------------------------------------
                Column {
                    width: parent.width
                    spacing: Tokens.spaceSm

                    Text {
                        text: "TERMINAL EMULATOR"
                        font.family: Tokens.fontFamilyMono
                        font.pixelSize: Tokens.fontXs
                        font.weight: Tokens.weightBold
                        color: Theme.mutedForeground
                    }

                    Rectangle {
                        width: parent.width
                        height: 48
                        radius: Tokens.radiusSm
                        color: Theme.alpha(Theme.surface, 0.7)
                        border.color: Theme.border
                        border.width: Tokens.borderWidthThin

                        Row {
                            anchors.fill: parent
                            anchors.margins: Tokens.spaceSm
                            spacing: Tokens.spaceSm

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: "󰞷"
                                font.family: Tokens.fontFamilyMono
                                font.pixelSize: Tokens.fontLg
                                color: Theme.accent
                            }

                            Column {
                                anchors.verticalCenter: parent.verticalCenter
                                width: parent.width - 130
                                spacing: 2

                                Text {
                                    text: Config.terminalCommand === "ghostty" ? "Ghostty Terminal" : Config.terminalCommand
                                    font.family: Tokens.fontFamilySans
                                    font.pixelSize: Tokens.fontXs
                                    font.weight: Tokens.weightMedium
                                    color: Theme.foreground
                                    elide: Text.ElideRight
                                    width: parent.width
                                }

                                Text {
                                    text: "Command: " + Config.terminalCommand
                                    font.family: Tokens.fontFamilyMono
                                    font.pixelSize: 10
                                    color: Theme.mutedForeground
                                }
                            }

                            // Launch Terminal Button
                            ButtonBase {
                                anchors.verticalCenter: parent.verticalCenter
                                text: "Launch"
                                primary: false
                                onClicked: {
                                    root.closeRequested();
                                    root.terminalLaunchRequested();
                                }
                            }
                        }
                    }
                }

                // Divider
                Rectangle {
                    width: parent.width
                    height: Tokens.borderWidthThin
                    color: Theme.alpha(Theme.border, 0.5)
                }

                // -------------------------------------------------------------
                // 6. MOTION & ANIMATION PREFERENCES
                // -------------------------------------------------------------
                Column {
                    width: parent.width
                    spacing: Tokens.spaceSm

                    Text {
                        text: "MOTION & ANIMATIONS"
                        font.family: Tokens.fontFamilyMono
                        font.pixelSize: Tokens.fontXs
                        font.weight: Tokens.weightBold
                        color: Theme.mutedForeground
                    }

                    // Enable/Disable Toggle Row
                    Row {
                        width: parent.width
                        height: 32

                        Column {
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.width - 80

                            Text {
                                text: "Interface Animations"
                                font.family: Tokens.fontFamilySans
                                font.pixelSize: Tokens.fontXs
                                font.weight: Tokens.weightMedium
                                color: Theme.foreground
                            }

                            Text {
                                text: Config.animationsEnabled ? "Smooth transitions enabled" : "Reduced motion active"
                                font.family: Tokens.fontFamilySans
                                font.pixelSize: 10
                                color: Theme.mutedForeground
                            }
                        }

                        // Toggle Pill
                        Rectangle {
                            anchors.verticalCenter: parent.verticalCenter
                            width: 68
                            height: 26
                            radius: Tokens.radiusFull
                            color: Config.animationsEnabled ? Theme.accent : Theme.surface
                            border.color: Config.animationsEnabled ? Theme.accent : Theme.border
                            border.width: Tokens.borderWidthThin

                            Text {
                                anchors.centerIn: parent
                                text: Config.animationsEnabled ? "ENABLED" : "OFF"
                                font.family: Tokens.fontFamilyMono
                                font.pixelSize: 10
                                font.weight: Tokens.weightBold
                                color: Config.animationsEnabled ? "#0d0e15" : Theme.mutedForeground
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: Config.setAnimationsEnabled(!Config.animationsEnabled)
                            }
                        }
                    }

                    // Speed Multiplier Pills Row
                    Row {
                        width: parent.width
                        height: 32
                        opacity: Config.animationsEnabled ? 1.0 : 0.4
                        enabled: Config.animationsEnabled

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            width: 120
                            text: "Speed Multiplier"
                            font.family: Tokens.fontFamilySans
                            font.pixelSize: Tokens.fontXs
                            color: Theme.foreground
                        }

                        Row {
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: Tokens.spaceXxs

                            Repeater {
                                model: [
                                    { speed: 0.5, label: "0.5x" },
                                    { speed: 1.0, label: "1.0x" },
                                    { speed: 1.5, label: "1.5x" }
                                ]

                                delegate: Rectangle {
                                    id: speedPill
                                    required property var modelData
                                    required property int index

                                    readonly property bool isSelected: Math.abs(Config.animationSpeed - modelData.speed) < 0.05
                                    width: 52
                                    height: 24
                                    radius: Tokens.radiusSm
                                    color: isSelected ? Theme.accent : (speedMouse.containsMouse ? Theme.alpha(Theme.surface, 0.8) : Theme.surface)
                                    border.color: isSelected ? Theme.accent : Theme.border
                                    border.width: Tokens.borderWidthThin

                                    Text {
                                        anchors.centerIn: parent
                                        text: speedPill.modelData.label
                                        font.family: Tokens.fontFamilyMono
                                        font.pixelSize: Tokens.fontXs
                                        font.weight: speedPill.isSelected ? Tokens.weightBold : Tokens.weightNormal
                                        color: speedPill.isSelected ? "#0d0e15" : Theme.foreground
                                    }

                                    MouseArea {
                                        id: speedMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: Config.setAnimationSpeed(speedPill.modelData.speed)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
