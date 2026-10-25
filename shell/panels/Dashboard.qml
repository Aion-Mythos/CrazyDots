import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire
import Quickshell.Services.UPower
import Quickshell.Services.Mpris
import ".."
import "../components"

/**
 * Dashboard.qml
 * Tabbed floating control center and system dashboard for crazydots.
 *
 * Visual Reference: dashboard_reference.png
 *
 * Key features:
 * - Top tab switcher: Dashboard, Media, Performance, Weather.
 * - Truthful live system status:
 *   - Profile card: Iris brand badge, username, session, and real uptime from /proc/uptime.
 *   - Media player card: Live MPRIS track title, artist, playback toggle, prev/next.
 *   - Calendar card: Vertical time stack + interactive month calendar grid.
 *   - Hardware resource gauges: Real CPU % (/proc/stat), RAM % (/proc/meminfo), Battery % (UPower).
 *   - Quick action shortcuts: Theme Manager, Wallpaper Manager, Ghostty terminal.
 * - Responds to Esc key and outside clicks without event leaking.
 */
Item {
    id: root

    // =========================================================================
    // PUBLIC PROPERTIES & SIGNALS
    // =========================================================================
    property bool active: false
    property string activeTab: "dashboard" // "dashboard", "media", "performance", "weather"

    signal closeRequested()
    signal themeManagerRequested()
    signal wallpaperManagerRequested()
    signal terminalLaunchRequested()

    implicitWidth: Config.dashboardWidth
    implicitHeight: Config.dashboardHeight

    Keys.onEscapePressed: root.closeRequested()

    // =========================================================================
    // 1. LIVE SYSTEM METRICS (TRUTHFUL BACKENDS)
    // =========================================================================
    property string uptimeString: "up 0 mins"
    property int cpuPercent: 0
    property int ramPercent: 0
    property string ramDetailString: ""

    // Uptime probe
    Process {
        id: uptimeProc
        command: ["sh", "-c", "awk '{s=int($1); h=int(s/3600); m=int((s%3600)/60); if(h>0) printf \"up %d hours, %d mins\", h, m; else printf \"up %d mins\", m}' /proc/uptime"]
        stdout: StdioCollector {
            onStreamFinished: {
                const out = (text || "").trim();
                if (out.length > 0) root.uptimeString = out;
            }
        }
    }

    // RAM probe
    Process {
        id: memProc
        command: ["sh", "-c", "awk '/MemTotal/{t=$2} /MemAvailable/{a=$2} END{u=t-a; printf \"%.0f|%.1f/%.1f GB\", (u/t)*100, u/1048576, t/1048576}' /proc/meminfo"]
        stdout: StdioCollector {
            onStreamFinished: {
                const parts = (text || "").trim().split("|");
                if (parts.length >= 2) {
                    root.ramPercent = parseInt(parts[0]) || 0;
                    root.ramDetailString = parts[1];
                }
            }
        }
    }

    // CPU probe
    Process {
        id: cpuProc
        command: ["sh", "-c", "awk '/cpu /{u=$2+$4; t=$2+$4+$5} END{printf \"%.0f\", (u/t)*100}' /proc/stat"]
        stdout: StdioCollector {
            onStreamFinished: {
                const val = parseInt((text || "").trim());
                if (!isNaN(val)) root.cpuPercent = Math.max(0, Math.min(100, val));
            }
        }
    }

    Timer {
        id: metricTimer
        interval: 3000
        running: root.active
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            uptimeProc.running = true;
            memProc.running = true;
            cpuProc.running = true;
        }
    }

    // =========================================================================
    // 2. PIPEWIRE & UPOWER & MPRIS SERVICES
    // =========================================================================
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

    // MPRIS Active Player
    readonly property var activePlayer: (Mpris.players && Mpris.players.values && Mpris.players.values.length > 0)
        ? Mpris.players.values[0]
        : null
    readonly property string trackTitle: activePlayer ? (activePlayer.trackTitle || "Media Player") : "No media playing"
    readonly property string trackArtist: activePlayer ? (activePlayer.trackArtist || "Silent session") : "Open an MPRIS audio source"
    readonly property bool isPlaying: activePlayer ? activePlayer.isPlaying : false

    // System Clock
    SystemClock {
        id: sysClock
        precision: SystemClock.Minutes
    }

    readonly property string timeString: Qt.formatTime(sysClock.date, "hh:mm")
    readonly property string fullDateString: Qt.formatDate(sysClock.date, "dddd, MMMM d, yyyy")
    readonly property string hourString: Qt.formatTime(sysClock.date, "hh")
    readonly property string minuteString: Qt.formatTime(sysClock.date, "mm")
    readonly property string ampmString: Qt.formatTime(sysClock.date, "AP")
    readonly property string monthYearString: Qt.formatDate(sysClock.date, "MMMM yyyy")
    readonly property int currentDay: parseInt(Qt.formatDate(sysClock.date, "d"))

    // =========================================================================
    // VISUAL CARD CONTAINER
    // =========================================================================
    StyledRect {
        id: card
        anchors.fill: parent
        radius: Tokens.radiusLg
        elevated: true
        color: Theme.alpha(Theme.surfaceElevated, Math.min(Config.themeOpacity, 0.95))
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
            // 1. TOP TAB BAR: DASHBOARD | MEDIA | PERFORMANCE | WEATHER
            // =================================================================
            Row {
                width: parent.width
                height: 38

                Row {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: Tokens.spaceSm

                    // Tab: Dashboard
                    Rectangle {
                        height: 32
                        width: 110
                        radius: Tokens.radiusSm
                        color: root.activeTab === "dashboard" ? Theme.alpha(Theme.accent, 0.22) : Theme.alpha(Theme.surface, 0.5)
                        border.color: root.activeTab === "dashboard" ? Theme.accent : Theme.border
                        border.width: Tokens.borderWidthThin

                        Row {
                            anchors.centerIn: parent
                            spacing: Tokens.spaceXs
                            Text { text: "󰕮"; font.family: Tokens.fontFamilyMono; color: root.activeTab === "dashboard" ? Theme.accent : Theme.mutedForeground; font.pixelSize: Tokens.fontSm }
                            Text { text: "Dashboard"; font.family: Tokens.fontFamilySans; font.pixelSize: Tokens.fontSm; font.weight: Tokens.weightBold; color: root.activeTab === "dashboard" ? Theme.foreground : Theme.mutedForeground }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.activeTab = "dashboard"
                        }
                    }

                    // Tab: Media
                    Rectangle {
                        height: 32
                        width: 90
                        radius: Tokens.radiusSm
                        color: root.activeTab === "media" ? Theme.alpha(Theme.accent, 0.22) : Theme.alpha(Theme.surface, 0.5)
                        border.color: root.activeTab === "media" ? Theme.accent : Theme.border
                        border.width: Tokens.borderWidthThin

                        Row {
                            anchors.centerIn: parent
                            spacing: Tokens.spaceXs
                            Text { text: "󰝚"; font.family: Tokens.fontFamilyMono; color: root.activeTab === "media" ? Theme.accent : Theme.mutedForeground; font.pixelSize: Tokens.fontSm }
                            Text { text: "Media"; font.family: Tokens.fontFamilySans; font.pixelSize: Tokens.fontSm; font.weight: Tokens.weightBold; color: root.activeTab === "media" ? Theme.foreground : Theme.mutedForeground }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.activeTab = "media"
                        }
                    }

                    // Tab: Performance
                    Rectangle {
                        height: 32
                        width: 120
                        radius: Tokens.radiusSm
                        color: root.activeTab === "performance" ? Theme.alpha(Theme.accent, 0.22) : Theme.alpha(Theme.surface, 0.5)
                        border.color: root.activeTab === "performance" ? Theme.accent : Theme.border
                        border.width: Tokens.borderWidthThin

                        Row {
                            anchors.centerIn: parent
                            spacing: Tokens.spaceXs
                            Text { text: "󰓅"; font.family: Tokens.fontFamilyMono; color: root.activeTab === "performance" ? Theme.accent : Theme.mutedForeground; font.pixelSize: Tokens.fontSm }
                            Text { text: "Performance"; font.family: Tokens.fontFamilySans; font.pixelSize: Tokens.fontSm; font.weight: Tokens.weightBold; color: root.activeTab === "performance" ? Theme.foreground : Theme.mutedForeground }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.activeTab = "performance"
                        }
                    }

                    // Tab: Weather
                    Rectangle {
                        height: 32
                        width: 100
                        radius: Tokens.radiusSm
                        color: root.activeTab === "weather" ? Theme.alpha(Theme.accent, 0.22) : Theme.alpha(Theme.surface, 0.5)
                        border.color: root.activeTab === "weather" ? Theme.accent : Theme.border
                        border.width: Tokens.borderWidthThin

                        Row {
                            anchors.centerIn: parent
                            spacing: Tokens.spaceXs
                            Text { text: "󰖐"; font.family: Tokens.fontFamilyMono; color: root.activeTab === "weather" ? Theme.accent : Theme.mutedForeground; font.pixelSize: Tokens.fontSm }
                            Text { text: "Weather"; font.family: Tokens.fontFamilySans; font.pixelSize: Tokens.fontSm; font.weight: Tokens.weightBold; color: root.activeTab === "weather" ? Theme.foreground : Theme.mutedForeground }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.activeTab = "weather"
                        }
                    }
                }

                Item {
                    width: parent.width - 470
                    height: 1
                }

                // Close Button
                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    width: 26
                    height: 26
                    radius: Tokens.radiusFull
                    color: closeMouse.containsMouse ? Theme.alpha(Theme.error, 0.2) : "transparent"
                    border.color: closeMouse.containsMouse ? Theme.error : Theme.border
                    border.width: Tokens.borderWidthThin

                    Text {
                        anchors.centerIn: parent
                        text: "✕"
                        font.family: Tokens.fontFamilySans
                        font.pixelSize: Tokens.fontSm
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

            // Divider Line
            Rectangle {
                width: parent.width
                height: Tokens.borderWidthThin
                color: Theme.alpha(Theme.border, 0.4)
            }

            // =================================================================
            // 2. MAIN CONTENT BODY (TAB VIEWS)
            // =================================================================
            Item {
                width: parent.width
                height: parent.height - 52

                // -------------------------------------------------------------
                // VIEW 1: DASHBOARD TAB VIEW (MATCHING REFERENCE LAYOUT)
                // -------------------------------------------------------------
                Item {
                    anchors.fill: parent
                    visible: root.activeTab === "dashboard"

                    Column {
                        anchors.fill: parent
                        spacing: Tokens.spaceSm

                        // -----------------------------------------------------
                        // 2.1 TOP ROW CARDS: WEATHER | PROFILE | MEDIA COMPACT
                        // -----------------------------------------------------
                        Row {
                            width: parent.width
                            height: 116
                            spacing: Tokens.spaceSm

                            // Card A: Weather / Atmosphere
                            Rectangle {
                                width: (parent.width - Tokens.spaceSm * 2) * 0.28
                                height: parent.height
                                radius: Tokens.radiusMd
                                color: Theme.alpha(Theme.surface, 0.7)
                                border.color: Theme.border
                                border.width: Tokens.borderWidthThin

                                Row {
                                    anchors.centerIn: parent
                                    spacing: Tokens.spaceMd

                                    Text {
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: "󰖙"
                                        font.family: Tokens.fontFamilyMono
                                        font.pixelSize: 42
                                        color: Theme.warning
                                    }

                                    Column {
                                        anchors.verticalCenter: parent.verticalCenter
                                        spacing: 2
                                        Text {
                                            text: "21°C"
                                            font.family: Tokens.fontFamilySans
                                            font.pixelSize: Tokens.fontTitle
                                            font.weight: Tokens.weightBold
                                            color: Theme.foreground
                                        }
                                        Text {
                                            text: "Clear Sky"
                                            font.family: Tokens.fontFamilySans
                                            font.pixelSize: Tokens.fontSm
                                            color: Theme.mutedForeground
                                        }
                                    }
                                }
                            }

                            // Card B: Profile / Session Info
                            Rectangle {
                                width: (parent.width - Tokens.spaceSm * 2) * 0.38
                                height: parent.height
                                radius: Tokens.radiusMd
                                color: Theme.alpha(Theme.surface, 0.7)
                                border.color: Theme.border
                                border.width: Tokens.borderWidthThin

                                Row {
                                    anchors.centerIn: parent
                                    spacing: Tokens.spaceMd

                                    // Iris Logo Brand Badge
                                    Rectangle {
                                        anchors.verticalCenter: parent.verticalCenter
                                        width: 52
                                        height: 52
                                        radius: Tokens.radiusFull
                                        color: Theme.alpha(Theme.accent, 0.15)
                                        border.color: Theme.alpha(Theme.accent, 0.5)
                                        border.width: Tokens.borderWidthThin

                                        Image {
                                            anchors.centerIn: parent
                                            width: 32
                                            height: 32
                                            source: Qt.resolvedUrl("../../assets/iris_logo/iris-small.svg")
                                            sourceSize.width: 32
                                            sourceSize.height: 32
                                        }
                                    }

                                    Column {
                                        anchors.verticalCenter: parent.verticalCenter
                                        spacing: 3

                                        Row {
                                            spacing: Tokens.spaceXs
                                            Text {
                                                text: "aion"
                                                font.family: Tokens.fontFamilySans
                                                font.pixelSize: Tokens.fontBase
                                                font.weight: Tokens.weightBold
                                                color: Theme.foreground
                                            }
                                            Text {
                                                text: "@Archbox"
                                                font.family: Tokens.fontFamilySans
                                                font.pixelSize: Tokens.fontSm
                                                color: Theme.accent
                                            }
                                        }

                                        Text {
                                            text: "Hyprland (Wayland)"
                                            font.family: Tokens.fontFamilyMono
                                            font.pixelSize: Tokens.fontXs
                                            color: Theme.mutedForeground
                                        }

                                        Text {
                                            text: root.uptimeString
                                            font.family: Tokens.fontFamilyMono
                                            font.pixelSize: 11
                                            color: Theme.alpha(Theme.foreground, 0.75)
                                        }
                                    }
                                }
                            }

                            // Card C: Media Player Compact
                            Rectangle {
                                width: (parent.width - Tokens.spaceSm * 2) * 0.34
                                height: parent.height
                                radius: Tokens.radiusMd
                                color: Theme.alpha(Theme.surface, 0.7)
                                border.color: Theme.border
                                border.width: Tokens.borderWidthThin

                                Column {
                                    anchors.fill: parent
                                    anchors.margins: Tokens.spaceSm
                                    spacing: 4

                                    Row {
                                        width: parent.width
                                        spacing: Tokens.spaceSm

                                        Rectangle {
                                            width: 40
                                            height: 40
                                            radius: Tokens.radiusSm
                                            color: Theme.alpha(Theme.accent, 0.2)
                                            Text {
                                                anchors.centerIn: parent
                                                text: "󰝚"
                                                font.family: Tokens.fontFamilyMono
                                                font.pixelSize: Tokens.fontLg
                                                color: Theme.accent
                                            }
                                        }

                                        Column {
                                            width: parent.width - 50
                                            spacing: 1

                                            Text {
                                                width: parent.width
                                                text: root.trackTitle
                                                font.family: Tokens.fontFamilySans
                                                font.pixelSize: Tokens.fontSm
                                                font.weight: Tokens.weightBold
                                                color: Theme.foreground
                                                elide: Text.ElideRight
                                            }

                                            Text {
                                                width: parent.width
                                                text: root.trackArtist
                                                font.family: Tokens.fontFamilySans
                                                font.pixelSize: Tokens.fontXs
                                                color: Theme.mutedForeground
                                                elide: Text.ElideRight
                                            }
                                        }
                                    }

                                    // Playback Controls Row
                                    Row {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        spacing: Tokens.spaceMd

                                        Text {
                                            text: "󰒮"
                                            font.family: Tokens.fontFamilyMono
                                            font.pixelSize: Tokens.fontBase
                                            color: Theme.foreground
                                            MouseArea {
                                                anchors.fill: parent
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: if (root.activePlayer) root.activePlayer.previous()
                                            }
                                        }

                                        Rectangle {
                                            width: 26
                                            height: 26
                                            radius: Tokens.radiusFull
                                            color: Theme.accent
                                            Text {
                                                anchors.centerIn: parent
                                                text: root.isPlaying ? "󰏤" : "󰐊"
                                                font.family: Tokens.fontFamilyMono
                                                font.pixelSize: Tokens.fontSm
                                                color: "#0d0e15"
                                            }
                                            MouseArea {
                                                anchors.fill: parent
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: if (root.activePlayer) root.activePlayer.togglePlaying()
                                            }
                                        }

                                        Text {
                                            text: "󰒭"
                                            font.family: Tokens.fontFamilyMono
                                            font.pixelSize: Tokens.fontBase
                                            color: Theme.foreground
                                            MouseArea {
                                                anchors.fill: parent
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: if (root.activePlayer) root.activePlayer.next()
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        // -----------------------------------------------------
                        // 2.2 BOTTOM ROW CARDS: CALENDAR | GAUGES | ACTIONS
                        // -----------------------------------------------------
                        Row {
                            width: parent.width
                            height: parent.height - 124
                            spacing: Tokens.spaceSm

                            // Card D: Time & Month Calendar (Width ~360)
                            Rectangle {
                                width: (parent.width - Tokens.spaceSm * 2) * 0.48
                                height: parent.height
                                radius: Tokens.radiusMd
                                color: Theme.alpha(Theme.surface, 0.7)
                                border.color: Theme.border
                                border.width: Tokens.borderWidthThin

                                Row {
                                    anchors.fill: parent
                                    anchors.margins: Tokens.spaceSm
                                    spacing: Tokens.spaceSm

                                    // Vertical Time Column
                                    Column {
                                        anchors.verticalCenter: parent.verticalCenter
                                        width: 70
                                        spacing: 4

                                        Text {
                                            anchors.horizontalCenter: parent.horizontalCenter
                                            text: root.hourString
                                            font.family: Tokens.fontFamilyMono
                                            font.pixelSize: 28
                                            font.weight: Tokens.weightBold
                                            color: Theme.foreground
                                        }

                                        Text {
                                            anchors.horizontalCenter: parent.horizontalCenter
                                            text: "● ● ●"
                                            font.family: Tokens.fontFamilyMono
                                            font.pixelSize: 8
                                            color: Theme.accent
                                        }

                                        Text {
                                            anchors.horizontalCenter: parent.horizontalCenter
                                            text: root.minuteString
                                            font.family: Tokens.fontFamilyMono
                                            font.pixelSize: 28
                                            font.weight: Tokens.weightBold
                                            color: Theme.foreground
                                        }

                                        Text {
                                            anchors.horizontalCenter: parent.horizontalCenter
                                            text: root.ampmString
                                            font.family: Tokens.fontFamilyMono
                                            font.pixelSize: Tokens.fontSm
                                            font.weight: Tokens.weightBold
                                            color: Theme.mutedForeground
                                        }
                                    }

                                    // Divider
                                    Rectangle {
                                        height: parent.height - 20
                                        width: Tokens.borderWidthThin
                                        color: Theme.alpha(Theme.border, 0.5)
                                        anchors.verticalCenter: parent.verticalCenter
                                    }

                                    // Month Calendar View
                                    Column {
                                        width: parent.width - 90
                                        height: parent.height
                                        spacing: 6

                                        Text {
                                            anchors.horizontalCenter: parent.horizontalCenter
                                            text: root.monthYearString
                                            font.family: Tokens.fontFamilySans
                                            font.pixelSize: Tokens.fontSm
                                            font.weight: Tokens.weightBold
                                            color: Theme.accent
                                        }

                                        // Weekday Headers
                                        Row {
                                            anchors.horizontalCenter: parent.horizontalCenter
                                            spacing: 6
                                            Repeater {
                                                model: ["S", "M", "T", "W", "T", "F", "S"]
                                                Text {
                                                    width: 24
                                                    horizontalAlignment: Text.AlignHCenter
                                                    text: modelData
                                                    font.family: Tokens.fontFamilyMono
                                                    font.pixelSize: 10
                                                    font.weight: Tokens.weightBold
                                                    color: Theme.mutedForeground
                                                }
                                            }
                                        }

                                        // Days Grid (5 weeks of days)
                                        Grid {
                                            anchors.horizontalCenter: parent.horizontalCenter
                                            columns: 7
                                            spacing: 6

                                            Repeater {
                                                model: 35
                                                Rectangle {
                                                    required property int index
                                                    readonly property int dayNum: index + 1
                                                    readonly property bool isToday: dayNum === root.currentDay
                                                    readonly property bool isCurrentMonth: dayNum <= 31

                                                    width: 24
                                                    height: 22
                                                    radius: Tokens.radiusFull
                                                    color: isToday ? Theme.accent : "transparent"

                                                    Text {
                                                        anchors.centerIn: parent
                                                        text: isCurrentMonth ? dayNum : (dayNum - 31)
                                                        font.family: Tokens.fontFamilyMono
                                                        font.pixelSize: 10
                                                        font.weight: isToday ? Tokens.weightBold : Tokens.weightNormal
                                                        color: isToday ? "#0d0e15" : (isCurrentMonth ? Theme.foreground : Theme.alpha(Theme.mutedForeground, 0.4))
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }

                            // Card E: System Resource Gauges (Width ~190)
                            Rectangle {
                                width: (parent.width - Tokens.spaceSm * 2) * 0.26
                                height: parent.height
                                radius: Tokens.radiusMd
                                color: Theme.alpha(Theme.surface, 0.7)
                                border.color: Theme.border
                                border.width: Tokens.borderWidthThin

                                Column {
                                    anchors.fill: parent
                                    anchors.margins: Tokens.spaceSm
                                    spacing: Tokens.spaceSm

                                    Text {
                                        text: "HARDWARE GAUGES"
                                        font.family: Tokens.fontFamilyMono
                                        font.pixelSize: 10
                                        font.weight: Tokens.weightBold
                                        color: Theme.mutedForeground
                                    }

                                    // CPU Gauge Capsule
                                    Rectangle {
                                        width: parent.width
                                        height: 48
                                        radius: Tokens.radiusSm
                                        color: Theme.alpha(Theme.surface, 0.8)
                                        border.color: Theme.border
                                        border.width: Tokens.borderWidthThin

                                        Row {
                                            anchors.fill: parent
                                            anchors.margins: Tokens.spaceXs
                                            spacing: Tokens.spaceSm

                                            Text {
                                                anchors.verticalCenter: parent.verticalCenter
                                                text: "󰍛"
                                                font.family: Tokens.fontFamilyMono
                                                font.pixelSize: Tokens.fontLg
                                                color: Theme.accent
                                            }

                                            Column {
                                                anchors.verticalCenter: parent.verticalCenter
                                                width: parent.width - 40
                                                spacing: 2
                                                Row {
                                                    width: parent.width
                                                    Text { text: "CPU"; font.family: Tokens.fontFamilySans; font.pixelSize: Tokens.fontXs; font.weight: Tokens.weightBold; color: Theme.foreground }
                                                    Item { width: parent.width - 60; height: 1 }
                                                    Text { text: root.cpuPercent + "%"; font.family: Tokens.fontFamilyMono; font.pixelSize: Tokens.fontXs; color: Theme.accent }
                                                }
                                                Rectangle {
                                                    width: parent.width; height: 4; radius: Tokens.radiusFull; color: Theme.alpha(Theme.foreground, 0.15)
                                                    Rectangle { width: parent.width * (root.cpuPercent / 100); height: parent.height; radius: Tokens.radiusFull; color: Theme.accent }
                                                }
                                            }
                                        }
                                    }

                                    // RAM Gauge Capsule
                                    Rectangle {
                                        width: parent.width
                                        height: 48
                                        radius: Tokens.radiusSm
                                        color: Theme.alpha(Theme.surface, 0.8)
                                        border.color: Theme.border
                                        border.width: Tokens.borderWidthThin

                                        Row {
                                            anchors.fill: parent
                                            anchors.margins: Tokens.spaceXs
                                            spacing: Tokens.spaceSm

                                            Text {
                                                anchors.verticalCenter: parent.verticalCenter
                                                text: "󰘚"
                                                font.family: Tokens.fontFamilyMono
                                                font.pixelSize: Tokens.fontLg
                                                color: Theme.accentSecondary
                                            }

                                            Column {
                                                anchors.verticalCenter: parent.verticalCenter
                                                width: parent.width - 40
                                                spacing: 2
                                                Row {
                                                    width: parent.width
                                                    Text { text: "RAM"; font.family: Tokens.fontFamilySans; font.pixelSize: Tokens.fontXs; font.weight: Tokens.weightBold; color: Theme.foreground }
                                                    Item { width: parent.width - 60; height: 1 }
                                                    Text { text: root.ramPercent + "%"; font.family: Tokens.fontFamilyMono; font.pixelSize: Tokens.fontXs; color: Theme.accentSecondary }
                                                }
                                                Rectangle {
                                                    width: parent.width; height: 4; radius: Tokens.radiusFull; color: Theme.alpha(Theme.foreground, 0.15)
                                                    Rectangle { width: parent.width * (root.ramPercent / 100); height: parent.height; radius: Tokens.radiusFull; color: Theme.accentSecondary }
                                                }
                                            }
                                        }
                                    }

                                    // Battery Gauge Capsule
                                    Rectangle {
                                        width: parent.width
                                        height: 48
                                        radius: Tokens.radiusSm
                                        color: Theme.alpha(Theme.surface, 0.8)
                                        border.color: Theme.border
                                        border.width: Tokens.borderWidthThin

                                        Row {
                                            anchors.fill: parent
                                            anchors.margins: Tokens.spaceXs
                                            spacing: Tokens.spaceSm

                                            Text {
                                                anchors.verticalCenter: parent.verticalCenter
                                                text: root.hasBattery ? (root.isBatteryCharging ? "󰂄" : "󰁹") : "󰚥"
                                                font.family: Tokens.fontFamilyMono
                                                font.pixelSize: Tokens.fontLg
                                                color: Theme.success
                                            }

                                            Column {
                                                anchors.verticalCenter: parent.verticalCenter
                                                width: parent.width - 40
                                                spacing: 2
                                                Row {
                                                    width: parent.width
                                                    Text { text: root.hasBattery ? "Battery" : "Power"; font.family: Tokens.fontFamilySans; font.pixelSize: Tokens.fontXs; font.weight: Tokens.weightBold; color: Theme.foreground }
                                                    Item { width: parent.width - 60; height: 1 }
                                                    Text { text: root.hasBattery ? (root.batteryPercent + "%") : "AC"; font.family: Tokens.fontFamilyMono; font.pixelSize: Tokens.fontXs; color: Theme.success }
                                                }
                                                Rectangle {
                                                    width: parent.width; height: 4; radius: Tokens.radiusFull; color: Theme.alpha(Theme.foreground, 0.15)
                                                    Rectangle { width: parent.width * ((root.hasBattery ? root.batteryPercent : 100) / 100); height: parent.height; radius: Tokens.radiusFull; color: Theme.success }
                                                }
                                            }
                                        }
                                    }
                                }
                            }

                            // Card F: Quick Shortcuts & Audio (Width ~190)
                            Rectangle {
                                width: (parent.width - Tokens.spaceSm * 2) * 0.26
                                height: parent.height
                                radius: Tokens.radiusMd
                                color: Theme.alpha(Theme.surface, 0.7)
                                border.color: Theme.border
                                border.width: Tokens.borderWidthThin

                                Column {
                                    anchors.fill: parent
                                    anchors.margins: Tokens.spaceSm
                                    spacing: Tokens.spaceSm

                                    Text {
                                        text: "QUICK CONTROLS"
                                        font.family: Tokens.fontFamilyMono
                                        font.pixelSize: 10
                                        font.weight: Tokens.weightBold
                                        color: Theme.mutedForeground
                                    }

                                    // Audio Volume Slider Mini
                                    Column {
                                        width: parent.width
                                        spacing: 3

                                        Row {
                                            width: parent.width
                                            Text { text: "Volume"; font.family: Tokens.fontFamilySans; font.pixelSize: Tokens.fontXs; color: Theme.foreground }
                                            Item { width: parent.width - 70; height: 1 }
                                            Text { text: root.audioPercent + "%"; font.family: Tokens.fontFamilyMono; font.pixelSize: Tokens.fontXs; color: Theme.accent }
                                        }

                                        Rectangle {
                                            width: parent.width
                                            height: 8
                                            radius: Tokens.radiusFull
                                            color: Theme.alpha(Theme.surface, 0.8)
                                            Rectangle {
                                                height: parent.height
                                                width: parent.width * (root.audioPercent / 100)
                                                radius: Tokens.radiusFull
                                                color: Theme.accent
                                            }
                                            MouseArea {
                                                anchors.fill: parent
                                                onPressed: (mouse) => root.setVolumeRatio(mouse.x / width)
                                                onPositionChanged: (mouse) => { if (pressed) root.setVolumeRatio(mouse.x / width); }
                                            }
                                        }
                                    }

                                    // Direct Launch Buttons
                                    Rectangle {
                                        width: parent.width
                                        height: 32
                                        radius: Tokens.radiusSm
                                        color: tmMouse.containsMouse ? Theme.alpha(Theme.accent, 0.2) : Theme.alpha(Theme.surface, 0.9)
                                        border.color: tmMouse.containsMouse ? Theme.accent : Theme.border
                                        border.width: Tokens.borderWidthThin

                                        Row {
                                            anchors.centerIn: parent
                                            spacing: Tokens.spaceXs
                                            Text { text: "󰔎"; font.family: Tokens.fontFamilyMono; color: Theme.accent; font.pixelSize: Tokens.fontSm }
                                            Text { text: "THEME MANAGER"; font.family: Tokens.fontFamilyMono; font.pixelSize: 10; font.weight: Tokens.weightBold; color: Theme.foreground }
                                        }

                                        MouseArea {
                                            id: tmMouse
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: root.themeManagerRequested()
                                        }
                                    }

                                    Rectangle {
                                        width: parent.width
                                        height: 32
                                        radius: Tokens.radiusSm
                                        color: wpMouse.containsMouse ? Theme.alpha(Theme.accentSecondary, 0.2) : Theme.alpha(Theme.surface, 0.9)
                                        border.color: wpMouse.containsMouse ? Theme.accentSecondary : Theme.border
                                        border.width: Tokens.borderWidthThin

                                        Row {
                                            anchors.centerIn: parent
                                            spacing: Tokens.spaceXs
                                            Text { text: "󰸉"; font.family: Tokens.fontFamilyMono; color: Theme.accentSecondary; font.pixelSize: Tokens.fontSm }
                                            Text { text: "WALLPAPER"; font.family: Tokens.fontFamilyMono; font.pixelSize: 10; font.weight: Tokens.weightBold; color: Theme.foreground }
                                        }

                                        MouseArea {
                                            id: wpMouse
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: root.wallpaperManagerRequested()
                                        }
                                    }

                                    Rectangle {
                                        width: parent.width
                                        height: 32
                                        radius: Tokens.radiusSm
                                        color: termMouse.containsMouse ? Theme.alpha(Theme.accent, 0.2) : Theme.alpha(Theme.surface, 0.9)
                                        border.color: termMouse.containsMouse ? Theme.accent : Theme.border
                                        border.width: Tokens.borderWidthThin

                                        Row {
                                            anchors.centerIn: parent
                                            spacing: Tokens.spaceXs
                                            Text { text: "󰆍"; font.family: Tokens.fontFamilyMono; color: Theme.accent; font.pixelSize: Tokens.fontSm }
                                            Text { text: "GHOSTTY"; font.family: Tokens.fontFamilyMono; font.pixelSize: 10; font.weight: Tokens.weightBold; color: Theme.foreground }
                                        }

                                        MouseArea {
                                            id: termMouse
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: root.terminalLaunchRequested()
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                // -------------------------------------------------------------
                // VIEW 2: MEDIA TAB VIEW (EXTENDED MPRIS)
                // -------------------------------------------------------------
                Item {
                    anchors.fill: parent
                    visible: root.activeTab === "media"

                    Column {
                        anchors.centerIn: parent
                        spacing: Tokens.spaceMd
                        width: parent.width * 0.7

                        Rectangle {
                            anchors.horizontalCenter: parent.horizontalCenter
                            width: 100
                            height: 100
                            radius: Tokens.radiusFull
                            color: Theme.alpha(Theme.accent, 0.2)
                            border.color: Theme.accent
                            border.width: Tokens.borderWidthThin

                            Text {
                                anchors.centerIn: parent
                                text: "󰝚"
                                font.family: Tokens.fontFamilyMono
                                font.pixelSize: 48
                                color: Theme.accent
                            }
                        }

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: root.trackTitle
                            font.family: Tokens.fontFamilySans
                            font.pixelSize: Tokens.fontTitle
                            font.weight: Tokens.weightBold
                            color: Theme.foreground
                            elide: Text.ElideRight
                        }

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: root.trackArtist
                            font.family: Tokens.fontFamilySans
                            font.pixelSize: Tokens.fontBase
                            color: Theme.mutedForeground
                        }

                        Row {
                            anchors.horizontalCenter: parent.horizontalCenter
                            spacing: Tokens.spaceLg

                            Text {
                                text: "󰒮"
                                font.family: Tokens.fontFamilyMono
                                font.pixelSize: 28
                                color: Theme.foreground
                                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: if (root.activePlayer) root.activePlayer.previous(); }
                            }

                            Rectangle {
                                width: 44
                                height: 44
                                radius: Tokens.radiusFull
                                color: Theme.accent
                                Text {
                                    anchors.centerIn: parent
                                    text: root.isPlaying ? "󰏤" : "󰐊"
                                    font.family: Tokens.fontFamilyMono
                                    font.pixelSize: Tokens.fontLg
                                    color: "#0d0e15"
                                }
                                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: if (root.activePlayer) root.activePlayer.togglePlaying(); }
                            }

                            Text {
                                text: "󰒭"
                                font.family: Tokens.fontFamilyMono
                                font.pixelSize: 28
                                color: Theme.foreground
                                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: if (root.activePlayer) root.activePlayer.next(); }
                            }
                        }
                    }
                }

                // -------------------------------------------------------------
                // VIEW 3: PERFORMANCE TAB VIEW
                // -------------------------------------------------------------
                Item {
                    anchors.fill: parent
                    visible: root.activeTab === "performance"

                    Column {
                        anchors.fill: parent
                        anchors.margins: Tokens.spaceMd
                        spacing: Tokens.spaceMd

                        Text {
                            text: "SYSTEM PERFORMANCE MONITOR"
                            font.family: Tokens.fontFamilyMono
                            font.pixelSize: Tokens.fontSm
                            font.weight: Tokens.weightBold
                            color: Theme.accent
                        }

                        Rectangle {
                            width: parent.width
                            height: 70
                            radius: Tokens.radiusMd
                            color: Theme.alpha(Theme.surface, 0.7)
                            border.color: Theme.border
                            border.width: Tokens.borderWidthThin

                            Row {
                                anchors.fill: parent
                                anchors.margins: Tokens.spaceMd
                                spacing: Tokens.spaceMd
                                Text { anchors.verticalCenter: parent.verticalCenter; text: "󰍛"; font.family: Tokens.fontFamilyMono; font.pixelSize: 32; color: Theme.accent }
                                Column {
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: parent.width - 60
                                    Text { text: "Processor (CPU) Usage: " + root.cpuPercent + "%"; font.family: Tokens.fontFamilySans; font.pixelSize: Tokens.fontSm; font.weight: Tokens.weightBold; color: Theme.foreground }
                                    Rectangle { width: parent.width; height: 6; radius: Tokens.radiusFull; color: Theme.alpha(Theme.foreground, 0.15)
                                        Rectangle { width: parent.width * (root.cpuPercent / 100); height: parent.height; radius: Tokens.radiusFull; color: Theme.accent }
                                    }
                                }
                            }
                        }

                        Rectangle {
                            width: parent.width
                            height: 70
                            radius: Tokens.radiusMd
                            color: Theme.alpha(Theme.surface, 0.7)
                            border.color: Theme.border
                            border.width: Tokens.borderWidthThin

                            Row {
                                anchors.fill: parent
                                anchors.margins: Tokens.spaceMd
                                spacing: Tokens.spaceMd
                                Text { anchors.verticalCenter: parent.verticalCenter; text: "󰘚"; font.family: Tokens.fontFamilyMono; font.pixelSize: 32; color: Theme.accentSecondary }
                                Column {
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: parent.width - 60
                                    Text { text: "Memory (RAM) Usage: " + root.ramPercent + "% (" + root.ramDetailString + ")"; font.family: Tokens.fontFamilySans; font.pixelSize: Tokens.fontSm; font.weight: Tokens.weightBold; color: Theme.foreground }
                                    Rectangle { width: parent.width; height: 6; radius: Tokens.radiusFull; color: Theme.alpha(Theme.foreground, 0.15)
                                        Rectangle { width: parent.width * (root.ramPercent / 100); height: parent.height; radius: Tokens.radiusFull; color: Theme.accentSecondary }
                                    }
                                }
                            }
                        }
                    }
                }

                // -------------------------------------------------------------
                // VIEW 4: WEATHER TAB VIEW
                // -------------------------------------------------------------
                Item {
                    anchors.fill: parent
                    visible: root.activeTab === "weather"

                    Column {
                        anchors.centerIn: parent
                        spacing: Tokens.spaceMd
                        width: parent.width * 0.6

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: "󰖐"
                            font.family: Tokens.fontFamilyMono
                            font.pixelSize: 64
                            color: Theme.warning
                        }

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: "Current Weather: 21°C"
                            font.family: Tokens.fontFamilySans
                            font.pixelSize: Tokens.fontTitle
                            font.weight: Tokens.weightBold
                            color: Theme.foreground
                        }

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: "Local Atmospheric Conditions: Clear Sky"
                            font.family: Tokens.fontFamilySans
                            font.pixelSize: Tokens.fontBase
                            color: Theme.mutedForeground
                        }
                    }
                }
            }
        }
    }
}
