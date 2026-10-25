import QtQuick
import Quickshell
import ".."
import "../components"

/**
 * ThemeManager.qml
 * Dedicated appearance and theme management dialog for crazydots.
 *
 * Responsibilities:
 * - Completely separated from the bar and dashboard's main scroll view.
 * - Displays active theme palette swatches with live color transitions.
 * - Provides one-click switching across all 8 built-in themes.
 * - Exposes dynamic color synthesis status and actions.
 * - Seamlessly integrates entry points to WallpaperManager with mutual exclusivity.
 */
Item {
    id: root

    property bool active: false

    signal closeRequested()
    signal wallpaperManagerRequested()
    signal dynamicColorsRequested(string path)

    implicitWidth: 620
    implicitHeight: 520

    Keys.onEscapePressed: root.closeRequested()

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
            acceptedButtons: Qt.LeftButton | Qt.RightButton
        }

        Column {
            anchors.fill: parent
            anchors.margins: Tokens.spaceLg
            spacing: Tokens.spaceMd

            // =================================================================
            // 1. HEADER ROW: TITLE & CLOSE BUTTON
            // =================================================================
            Row {
                width: parent.width
                height: 36

                Row {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: Tokens.spaceSm

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "󰔎"
                        font.family: Tokens.fontFamilyMono
                        font.pixelSize: Tokens.fontLg
                        color: Theme.accent
                        renderType: Text.NativeRendering
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "THEME & APPEARANCE MANAGER"
                        font.family: Tokens.fontFamilyMono
                        font.pixelSize: Tokens.fontBase
                        font.weight: Tokens.weightBold
                        color: Theme.foreground
                        renderType: Text.NativeRendering
                    }
                }

                Item {
                    width: parent.width - 320
                    height: 1
                }

                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    width: 28
                    height: 28
                    radius: Tokens.radiusFull
                    color: closeMouse.containsMouse ? Theme.alpha(Theme.error, 0.2) : "transparent"
                    border.color: closeMouse.containsMouse ? Theme.error : Theme.border
                    border.width: Tokens.borderWidthThin

                    Text {
                        anchors.centerIn: parent
                        text: "✕"
                        font.family: Tokens.fontFamilySans
                        font.pixelSize: Tokens.fontSm
                        font.weight: Tokens.weightBold
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
                color: Theme.alpha(Theme.border, 0.5)
            }

            // =================================================================
            // 2. ACTIVE THEME SUMMARY & PALETTE SWATCHES
            // =================================================================
            Rectangle {
                width: parent.width
                height: 72
                radius: Tokens.radiusMd
                color: Theme.alpha(Theme.surface, 0.7)
                border.color: Theme.border
                border.width: Tokens.borderWidthThin

                Column {
                    anchors.fill: parent
                    anchors.margins: Tokens.spaceSm
                    spacing: Tokens.spaceXs

                    Row {
                        width: parent.width
                        spacing: Tokens.spaceSm

                        Text {
                            text: "Active Theme: "
                            font.family: Tokens.fontFamilySans
                            font.pixelSize: Tokens.fontSm
                            color: Theme.mutedForeground
                        }

                        Text {
                            text: Theme.activeThemeDisplayName
                            font.family: Tokens.fontFamilySans
                            font.pixelSize: Tokens.fontSm
                            font.weight: Tokens.weightBold
                            color: Theme.accent
                        }

                        Text {
                            text: Theme.isDynamic ? "(Dynamic Wallpaper Palette)" : "(Static Preset)"
                            font.family: Tokens.fontFamilySans
                            font.pixelSize: Tokens.fontXs
                            color: Theme.mutedForeground
                        }
                    }

                    // 8-Swatch Palette Strip
                    Row {
                        spacing: Tokens.spaceSm

                        Repeater {
                            model: [
                                { label: "BG", color: Theme.background },
                                { label: "Surface", color: Theme.surface },
                                { label: "Elevated", color: Theme.surfaceElevated },
                                { label: "Accent", color: Theme.accent },
                                { label: "Sec", color: Theme.accentSecondary },
                                { label: "Border", color: Theme.border },
                                { label: "Warn", color: Theme.warning },
                                { label: "Err", color: Theme.error }
                            ]

                            delegate: Rectangle {
                                required property var modelData
                                width: 58
                                height: 26
                                radius: Tokens.radiusSm
                                color: modelData.color
                                border.color: Theme.border
                                border.width: Tokens.borderWidthThin

                                Text {
                                    anchors.centerIn: parent
                                    text: parent.modelData.label
                                    font.family: Tokens.fontFamilyMono
                                    font.pixelSize: 9
                                    font.weight: Tokens.weightBold
                                    color: Theme.alpha(Theme.foreground, 0.85)
                                }
                            }
                        }
                    }
                }
            }

            // =================================================================
            // 3. BUILT-IN THEME PRESETS GRID (8 THEMES)
            // =================================================================
            Text {
                text: "BUILT-IN COLOR PRESETS"
                font.family: Tokens.fontFamilyMono
                font.pixelSize: Tokens.fontXs
                font.weight: Tokens.weightBold
                color: Theme.mutedForeground
            }

            Grid {
                width: parent.width
                columns: 2
                spacing: Tokens.spaceSm

                Repeater {
                    model: [
                        { id: "crazydots-default", label: "crazydots", color: "#2ee6ca", bg: "#0d0e15" },
                        { id: "catppuccin-mocha", label: "Catppuccin Mocha", color: "#89b4fa", bg: "#1e1e2e" },
                        { id: "tokyo-night", label: "Tokyo Night", color: "#7aa2f7", bg: "#1a1b26" },
                        { id: "nord", label: "Nord Frost", color: "#88c0d0", bg: "#2e3440" },
                        { id: "gruvbox-dark", label: "Gruvbox Dark", color: "#fe8019", bg: "#282828" },
                        { id: "dracula", label: "Dracula", color: "#bd93f9", bg: "#282a36" },
                        { id: "rose-pine", label: "Rosé Pine", color: "#ebbcba", bg: "#191724" },
                        { id: "everforest", label: "Everforest", color: "#a7c080", bg: "#2b3339" }
                    ]

                    delegate: Rectangle {
                        id: presetItem
                        required property var modelData
                        required property int index

                        readonly property bool isSelected: Theme.activeThemeName === modelData.id
                        width: (parent.width - Tokens.spaceSm) / 2
                        height: 40
                        radius: Tokens.radiusSm
                        color: isSelected ? Theme.alpha(modelData.color, 0.22) : (presetMouse.containsMouse ? Theme.alpha(Theme.surface, 0.9) : Theme.surface)
                        border.color: isSelected ? modelData.color : Theme.border
                        border.width: isSelected ? 2 : Tokens.borderWidthThin

                        Row {
                            anchors.fill: parent
                            anchors.margins: Tokens.spaceSm
                            spacing: Tokens.spaceSm

                            // Color Accent & Background Preview Dot
                            Rectangle {
                                anchors.verticalCenter: parent.verticalCenter
                                width: 20
                                height: 20
                                radius: Tokens.radiusFull
                                color: presetItem.modelData.bg
                                border.color: presetItem.modelData.color
                                border.width: 3
                            }

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: presetItem.modelData.label
                                font.family: Tokens.fontFamilySans
                                font.pixelSize: Tokens.fontSm
                                font.weight: presetItem.isSelected ? Tokens.weightBold : Tokens.weightNormal
                                color: presetItem.isSelected ? Theme.foreground : Theme.mutedForeground
                            }
                        }

                        MouseArea {
                            id: presetMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: Config.setThemeName(presetItem.modelData.id)
                        }
                    }
                }
            }

            // =================================================================
            // 4. WALLPAPER & DYNAMIC COLOR ACTIONS
            // =================================================================
            Rectangle {
                width: parent.width
                height: 52
                radius: Tokens.radiusMd
                color: Theme.alpha(Theme.surface, 0.5)
                border.color: Theme.border
                border.width: Tokens.borderWidthThin

                Row {
                    anchors.centerIn: parent
                    spacing: Tokens.spaceMd

                    // Button: Open Wallpaper Manager
                    Rectangle {
                        width: 220
                        height: 34
                        radius: Tokens.radiusSm
                        color: wpMouse.containsMouse ? Theme.alpha(Theme.accent, 0.2) : Theme.surface
                        border.color: wpMouse.containsMouse ? Theme.accent : Theme.border
                        border.width: Tokens.borderWidthThin

                        Row {
                            anchors.centerIn: parent
                            spacing: Tokens.spaceXs

                            Text {
                                text: "󰸉"
                                font.family: Tokens.fontFamilyMono
                                font.pixelSize: Tokens.fontSm
                                color: Theme.accent
                            }

                            Text {
                                text: "WALLPAPER MANAGER"
                                font.family: Tokens.fontFamilyMono
                                font.pixelSize: Tokens.fontXs
                                font.weight: Tokens.weightBold
                                color: Theme.foreground
                            }
                        }

                        MouseArea {
                            id: wpMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                root.closeRequested();
                                root.wallpaperManagerRequested();
                            }
                        }
                    }

                    // Button: Re-extract from active wallpaper
                    Rectangle {
                        width: 220
                        height: 34
                        radius: Tokens.radiusSm
                        color: extractMouse.containsMouse ? Theme.alpha(Theme.accentSecondary, 0.2) : Theme.surface
                        border.color: extractMouse.containsMouse ? Theme.accentSecondary : Theme.border
                        border.width: Tokens.borderWidthThin

                        Row {
                            anchors.centerIn: parent
                            spacing: Tokens.spaceXs

                            Text {
                                text: "󰦛"
                                font.family: Tokens.fontFamilyMono
                                font.pixelSize: Tokens.fontSm
                                color: Theme.accentSecondary
                            }

                            Text {
                                text: "EXTRACT FROM WALLPAPER"
                                font.family: Tokens.fontFamilyMono
                                font.pixelSize: Tokens.fontXs
                                font.weight: Tokens.weightBold
                                color: Theme.foreground
                            }
                        }

                        MouseArea {
                            id: extractMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (Config.wallpaperCurrent && Config.wallpaperCurrent.length > 0) {
                                    root.dynamicColorsRequested(Config.wallpaperCurrent);
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
