import QtQuick
import Quickshell
import Quickshell.Io
import ".."
import "../components"

/**
 * WallpaperManager.qml
 * Native visual wallpaper selector and dynamic theming control panel for crazydots.
 *
 * Responsibilities:
 * - Asynchronously scans configured user directories and bundled assets for wallpaper files.
 * - Displays wallpaper thumbnails with loading, selection, and active state indicators.
 * - Supports searching and filtering wallpapers by filename.
 * - Provides mode selector (fill, fit, center, tile) bound to Config.qml.
 * - Triggers wallpaper persistence and dynamic color extraction via ThemeEngine.
 * - Gracefully handles missing, deleted, or corrupted images without UI blocking.
 */
Item {
    id: root

    // =========================================================================
    // PUBLIC PROPERTIES & SIGNALS
    // =========================================================================
    property bool active: false
    property string selectedPath: Config.wallpaperCurrent
    property string selectedMode: Config.wallpaperMode
    property string searchQuery: searchInput.text
    property bool isScanning: false
    property var discoveredWallpapers: []

    signal closeRequested()
    signal wallpaperApplied(string path, string mode)
    signal dynamicColorsExtracted(string path)

    // Sizing
    implicitWidth: 800
    implicitHeight: 580

    // =========================================================================
    // ASYNCHRONOUS WALLPAPER DISCOVERY
    // Scans directories for image assets without blocking the UI thread.
    // =========================================================================
    function scanDirectories() {
        if (root.isScanning) return;
        root.isScanning = true;

        const rawPaths = [
            Config.wallpaperDirectory,
            Quickshell.env("HOME") + "/Pictures/Wallpapers",
            Quickshell.env("HOME") + "/Pictures",
            Quickshell.env("HOME") + "/.config/crazydots/wallpapers",
            Quickshell.env("CRAZYDOTS_ASSETS_DIR"),
            Quickshell.env("HOME") + "/.local/share/crazydots/assets/wallpapers",
            Quickshell.env("HOME") + "/crazydots/assets/wallpapers",
            "/usr/share/crazydots/assets/wallpapers"
        ];

        const scanPaths = [];
        for (let i = 0; i < rawPaths.length; i++) {
            const p = rawPaths[i];
            if (p && typeof p === "string" && p.trim().length > 0 && scanPaths.indexOf(p.trim()) === -1) {
                scanPaths.push(p.trim());
            }
        }

        scannerProc.command = ["find"].concat(scanPaths).concat([
            "-maxdepth", "2",
            "-type", "f",
            "-regextype", "posix-extended",
            "-iregex", ".*\\.(jpg|jpeg|png|webp|bmp|svg)"
        ]);
        scannerProc.running = true;
    }

    Process {
        id: scannerProc
        running: false

        stdout: StdioCollector {
            onStreamFinished: {
                root.isScanning = false;
                const raw = (text || "").trim().split("\n");
                const uniqueMap = {};
                const list = [];

                for (let i = 0; i < raw.length; i++) {
                    const line = raw[i].trim();
                    if (line.length > 0 && !uniqueMap[line]) {
                        uniqueMap[line] = true;
                        const filename = line.split("/").pop();
                        list.push({
                            path: line,
                            name: filename
                        });
                    }
                }

                // Sort alphabetically by filename
                list.sort((a, b) => a.name.localeCompare(b.name));
                root.discoveredWallpapers = list;

                // Default selection to current wallpaper or first discovered
                if (!root.selectedPath && list.length > 0) {
                    root.selectedPath = list[0].path;
                }
            }
        }
    }

    // Filtered list matching search query
    readonly property var filteredWallpapers: {
        const q = root.searchQuery.trim().toLowerCase();
        const raw = root.discoveredWallpapers;
        if (!raw || raw.length === 0) return [];
        if (q === "") return raw;

        return raw.filter(item => item.name.toLowerCase().indexOf(q) !== -1);
    }

    onActiveChanged: {
        if (active) {
            root.selectedPath = Config.wallpaperCurrent;
            root.selectedMode = Config.wallpaperMode;
            root.scanDirectories();
            searchInput.forceActiveFocus();
        }
    }

    Component.onCompleted: {
        root.scanDirectories();
    }

    // =========================================================================
    // WALLPAPER APPLICATION & COLOR EXTRACTION
    // =========================================================================
    function applyCurrentSelection() {
        if (!root.selectedPath) return;

        Config.setWallpaper(root.selectedPath, root.selectedMode);
        root.wallpaperApplied(root.selectedPath, root.selectedMode);
    }

    function extractColorsFromSelection() {
        if (!root.selectedPath) return;

        applyCurrentSelection();
        root.dynamicColorsExtracted(root.selectedPath);
    }

    // =========================================================================
    // MODAL DIALOG CONTAINER
    // =========================================================================
    StyledRect {
        id: managerCard
        anchors.fill: parent
        radius: Tokens.radiusLg
        elevated: true
        color: Theme.alpha(Theme.surfaceElevated, 0.95)
        border.color: Theme.alpha(Theme.accent, 0.4)
        border.width: Tokens.borderWidthThin

        Column {
            anchors.fill: parent
            anchors.margins: Tokens.spaceLg
            spacing: Tokens.spaceMd

            // -----------------------------------------------------------------
            // 1. HEADER ROW: TITLE & SEARCH
            // -----------------------------------------------------------------
            Row {
                width: parent.width
                height: 40
                spacing: Tokens.spaceMd

                // Title Icon & Label
                Row {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: Tokens.spaceSm

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "󰸉"
                        font.family: Tokens.fontFamilyMono
                        font.pixelSize: Tokens.fontTitle
                        color: Theme.accent
                        renderType: Text.NativeRendering
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "Wallpaper Manager"
                        font.family: Tokens.fontFamilySans
                        font.pixelSize: Tokens.fontLg
                        font.weight: Tokens.weightBold
                        color: Theme.foreground
                        renderType: Text.NativeRendering
                    }
                }

                Item { width: 10; height: 1 }

                // Search Bar
                Rectangle {
                    id: searchBox
                    property bool hasFocus: false
                    anchors.verticalCenter: parent.verticalCenter
                    width: 260
                    height: 36
                    radius: Tokens.radiusSm
                    color: Theme.alpha(Theme.surface, 0.8)
                    border.color: hasFocus ? Theme.accent : Theme.border
                    border.width: Tokens.borderWidthThin

                    Row {
                        anchors.fill: parent
                        anchors.leftMargin: Tokens.spaceSm
                        anchors.rightMargin: Tokens.spaceSm
                        spacing: Tokens.spaceXs

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "󰍉"
                            font.family: Tokens.fontFamilyMono
                            font.pixelSize: Tokens.fontSm
                            color: Theme.mutedForeground
                        }

                        TextInput {
                            id: searchInput
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.width - 40
                            font.family: Tokens.fontFamilySans
                            font.pixelSize: Tokens.fontSm
                            color: Theme.foreground
                            clip: true
                            onActiveFocusChanged: searchBox.hasFocus = activeFocus

                            Text {
                                anchors.fill: parent
                                text: "Filter wallpapers..."
                                font.family: Tokens.fontFamilySans
                                font.pixelSize: Tokens.fontSm
                                color: Theme.alpha(Theme.mutedForeground, 0.6)
                                visible: searchInput.text.length === 0
                            }

                            Keys.onEscapePressed: root.closeRequested()
                        }
                    }
                }

                // Mode Selector Pills
                Row {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: Tokens.spaceXxs

                    Repeater {
                        model: ["fill", "fit", "center", "tile"]

                        delegate: Rectangle {
                            id: modePill
                            required property var modelData
                            required property int index

                            readonly property bool isSelected: root.selectedMode === modelData
                            width: 60
                            height: 32
                            radius: Tokens.radiusSm
                            color: isSelected ? Theme.accent : (modeMouse.containsMouse ? Theme.alpha(Theme.surface, 0.8) : "transparent")
                            border.color: isSelected ? Theme.accent : Theme.border
                            border.width: Tokens.borderWidthThin

                            Text {
                                anchors.centerIn: parent
                                text: modePill.modelData.toUpperCase()
                                font.family: Tokens.fontFamilyMono
                                font.pixelSize: Tokens.fontXs
                                font.weight: modePill.isSelected ? Tokens.weightBold : Tokens.weightNormal
                                color: modePill.isSelected ? "#0d0e15" : Theme.foreground
                            }

                            MouseArea {
                                id: modeMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.selectedMode = modePill.modelData
                            }
                        }
                    }
                }

                // Close Button
                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
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

            // Divider Line
            Rectangle {
                width: parent.width
                height: Tokens.borderWidthThin
                color: Theme.alpha(Theme.border, 0.5)
            }

            // -----------------------------------------------------------------
            // 2. THUMBNAIL GRID VIEW
            // -----------------------------------------------------------------
            Item {
                width: parent.width
                height: parent.height - 120

                GridView {
                    id: gridView
                    anchors.fill: parent
                    clip: true
                    cellWidth: 245
                    cellHeight: 165
                    model: root.filteredWallpapers
                    visible: root.filteredWallpapers.length > 0

                    delegate: Item {
                        id: cellDelegate
                        required property var modelData
                        required property int index

                        readonly property bool isCurrent: root.selectedPath === modelData.path
                        readonly property bool isActiveWallpaper: Config.wallpaperCurrent === modelData.path

                        width: 235
                        height: 155

                        Rectangle {
                            id: card
                            anchors.fill: parent
                            radius: Tokens.radiusMd
                            color: Theme.surface
                            border.width: (cellDelegate.isCurrent || cellDelegate.isActiveWallpaper) ? 2 : Tokens.borderWidthThin
                            border.color: {
                                if (cellDelegate.isCurrent) return Theme.accent;
                                if (cellDelegate.isActiveWallpaper) return Theme.success;
                                if (cardMouse.containsMouse) return Theme.alpha(Theme.accent, 0.6);
                                return Theme.border;
                            }

                            Behavior on border.color {
                                ColorAnimation { duration: Tokens.durationFast }
                            }

                            // Thumbnail Image
                            Image {
                                id: thumbImg
                                anchors.top: parent.top
                                anchors.left: parent.left
                                anchors.right: parent.right
                                height: 115
                                fillMode: Image.PreserveAspectCrop
                                source: "file://" + cellDelegate.modelData.path
                                asynchronous: true
                                cache: true
                                visible: status === Image.Ready
                            }

                            // Loading state / Fallback placeholder
                            Rectangle {
                                anchors.fill: thumbImg
                                color: Theme.alpha(Theme.background, 0.6)
                                visible: thumbImg.status !== Image.Ready

                                Text {
                                    anchors.centerIn: parent
                                    text: thumbImg.status === Image.Error ? "󰅙 Error" : "󰑐 Loading..."
                                    font.family: Tokens.fontFamilySans
                                    font.pixelSize: Tokens.fontSm
                                    color: thumbImg.status === Image.Error ? Theme.error : Theme.mutedForeground
                                }
                            }

                            // Active Wallpaper Badge
                            Rectangle {
                                anchors.top: parent.top
                                anchors.right: parent.right
                                anchors.margins: Tokens.spaceSm
                                width: 56
                                height: 20
                                radius: Tokens.radiusFull
                                color: Theme.success
                                visible: cellDelegate.isActiveWallpaper

                                Text {
                                    anchors.centerIn: parent
                                    text: "ACTIVE"
                                    font.family: Tokens.fontFamilyMono
                                    font.pixelSize: Tokens.fontXs
                                    font.weight: Tokens.weightBold
                                    color: "#0d0e15"
                                }
                            }

                            // Filename Label
                            Text {
                                anchors.bottom: parent.bottom
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.margins: Tokens.spaceSm
                                text: cellDelegate.modelData.name
                                font.family: Tokens.fontFamilySans
                                font.pixelSize: Tokens.fontXs
                                font.weight: cellDelegate.isCurrent ? Tokens.weightBold : Tokens.weightNormal
                                color: cellDelegate.isCurrent ? Theme.accent : Theme.foreground
                                elide: Text.ElideMiddle
                                renderType: Text.NativeRendering
                            }

                            MouseArea {
                                id: cardMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    root.selectedPath = cellDelegate.modelData.path;
                                }
                                onDoubleClicked: {
                                    root.selectedPath = cellDelegate.modelData.path;
                                    root.applyCurrentSelection();
                                }
                            }
                        }
                    }
                }

                // Empty / Loading Message
                Column {
                    anchors.centerIn: parent
                    spacing: Tokens.spaceSm
                    visible: root.filteredWallpapers.length === 0

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: root.isScanning ? "󰑐" : "󰸉"
                        font.family: Tokens.fontFamilyMono
                        font.pixelSize: 36
                        color: Theme.mutedForeground
                    }

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: root.isScanning ? "Scanning wallpaper directories..." : "No wallpapers found"
                        font.family: Tokens.fontFamilySans
                        font.pixelSize: Tokens.fontBase
                        font.weight: Tokens.weightMedium
                        color: Theme.foreground
                    }

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "Place .jpg, .png, or .svg files in " + Config.wallpaperDirectory
                        font.family: Tokens.fontFamilyMono
                        font.pixelSize: Tokens.fontXs
                        color: Theme.mutedForeground
                    }
                }
            }

            // -----------------------------------------------------------------
            // 3. ACTION BAR FOOTER
            // -----------------------------------------------------------------
            Row {
                width: parent.width
                height: 40
                spacing: Tokens.spaceMd

                // Selected File Path Label
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width - 340
                    text: root.selectedPath ? root.selectedPath.split("/").pop() : "No wallpaper selected"
                    font.family: Tokens.fontFamilySans
                    font.pixelSize: Tokens.fontSm
                    color: Theme.mutedForeground
                    elide: Text.ElideMiddle
                }

                // Apply Wallpaper Button
                ButtonBase {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Apply Wallpaper"
                    primary: false
                    disabled: !root.selectedPath
                    onClicked: root.applyCurrentSelection()
                }

                // Extract & Apply Dynamic Colors Button
                ButtonBase {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "󰌁 Dynamic Theme"
                    primary: true
                    disabled: !root.selectedPath
                    onClicked: root.extractColorsFromSelection()
                }
            }
        }
    }
}
