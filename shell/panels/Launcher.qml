import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import ".."
import "../components"

/**
 * Launcher.qml
 * Native application launcher modal for crazydots.
 *
 * Visual & Interactive Reference: launcher_primary_reference.png (image(9).png)
 *
 * Design features:
 * - Floating lower-middle rounded translucent panel themed with crazydots design tokens.
 * - Application list on top with full unconstrained catalog displayed immediately.
 * - Rows display app icon (32px), bold app name, and secondary description/comment.
 * - Understated selection highlight with smooth keyboard-first navigation (Up/Down/Return).
 * - Integrated search & command capsule pinned at the bottom with placeholder `Type ">" for commands`.
 * - Real command mode: typing `> <cmd>` runs the command in Ghostty/configured terminal emulator.
 * - Subtle Iris brand badge integrated into the search capsule.
 */
Item {
    id: root

    // =========================================================================
    // PUBLIC PROPERTIES & SIGNALS
    // =========================================================================
    property bool active: false
    property alias searchQuery: searchInput.text
    property int selectedIndex: 0
    property bool isLaunching: false

    signal closeRequested()
    signal appLaunched(var app)
    signal commandLaunched(string command)

    // Sizing matching primary visual reference
    implicitWidth: 540
    implicitHeight: 480

    // Command Mode Detection
    readonly property bool isCommandMode: root.searchQuery.trim().startsWith(">")
    readonly property string commandText: {
        const trimmed = root.searchQuery.trim();
        if (!trimmed.startsWith(">")) return "";
        return trimmed.substring(1).trim();
    }

    // =========================================================================
    // DESKTOP APPLICATION SEARCH ENGINE
    // =========================================================================
    readonly property var allApplications: {
        const raw = DesktopEntries.applications ? DesktopEntries.applications.values : [];
        if (!raw || raw.length === 0) return [];

        const list = [];
        for (let i = 0; i < raw.length; i++) {
            const entry = raw[i];
            if (!entry.noDisplay) {
                list.push(entry);
            }
        }
        return list;
    }

    readonly property var filteredApplications: {
        // In command mode, we do not filter apps
        if (root.isCommandMode) return [];

        const q = root.searchQuery.trim().toLowerCase();
        const raw = root.allApplications;
        if (!raw || raw.length === 0) return [];

        if (q === "") {
            // Default: complete alphabetical list of all installed applications
            const sorted = raw.slice();
            sorted.sort((a, b) => (a.name || "").localeCompare(b.name || ""));
            return sorted;
        }

        const scored = [];
        for (let i = 0; i < raw.length; i++) {
            const app = raw[i];
            const name = (app.name || "").toLowerCase();
            const generic = (app.genericName || "").toLowerCase();
            const comment = (app.comment || "").toLowerCase();
            const id = (app.id || "").toLowerCase();

            let score = 0;
            if (name.startsWith(q)) {
                score = 100;
            } else if (name.includes(q)) {
                score = 75;
            } else if (generic.includes(q)) {
                score = 50;
            } else if (id.includes(q)) {
                score = 40;
            } else if (comment.includes(q)) {
                score = 25;
            } else if (app.keywords) {
                for (let k = 0; k < app.keywords.length; k++) {
                    if (app.keywords[k].toLowerCase().includes(q)) {
                        score = 20;
                        break;
                    }
                }
            }

            if (score > 0) {
                scored.push({ app: app, score: score, name: app.name || "" });
            }
        }

        scored.sort((a, b) => {
            if (b.score !== a.score) return b.score - a.score;
            return a.name.localeCompare(b.name);
        });

        const results = [];
        for (let i = 0; i < scored.length; i++) {
            results.push(scored[i].app);
        }
        return results;
    }

    onFilteredApplicationsChanged: {
        if (root.selectedIndex >= root.filteredApplications.length) {
            root.selectedIndex = Math.max(0, root.filteredApplications.length - 1);
        }
    }

    // =========================================================================
    // SEARCH & FOCUS CONTROL
    // =========================================================================
    function focusSearch() {
        searchInput.forceActiveFocus();
    }

    function resetSearch() {
        searchInput.text = "";
        root.selectedIndex = 0;
    }

    function launchSelected() {
        if (root.isCommandMode) {
            if (root.commandText.length > 0) {
                root.launchCommand(root.commandText);
            }
            return;
        }

        if (root.filteredApplications.length > 0 && root.selectedIndex >= 0 && root.selectedIndex < root.filteredApplications.length) {
            root.launchApp(root.filteredApplications[root.selectedIndex]);
        }
    }

    function launchApp(app) {
        if (!app || root.isLaunching) return;
        root.isLaunching = true;

        console.log("crazydots: Launching application:", app.name, "(id: " + app.id + ")");
        try {
            if (typeof app.execute === "function") {
                app.execute();
            }
        } catch (e) {
            console.error("crazydots: Application execution failed:", e);
        }

        root.appLaunched(app);
        root.closeRequested();
        cooldownTimer.restart();
    }

    // Safe command execution in terminal
    Process {
        id: commandRunner
        running: false
    }

    function launchCommand(cmd) {
        if (!cmd || root.isLaunching) return;
        root.isLaunching = true;

        console.log("crazydots: Launching shell command in terminal:", cmd);
        try {
            commandRunner.command = [Config.terminalCommand, "-e", "sh", "-c", cmd];
            commandRunner.running = true;
        } catch (e) {
            console.error("crazydots: Failed to run command:", e);
        }

        root.commandLaunched(cmd);
        root.closeRequested();
        cooldownTimer.restart();
    }

    Timer {
        id: cooldownTimer
        interval: 400
        repeat: false
        onTriggered: {
            root.isLaunching = false;
        }
    }

    // Helper to resolve icon source cleanly
    function resolveIconSource(icon) {
        if (!icon || icon.length === 0) return "";
        if (icon.startsWith("/") || icon.startsWith("file://") || icon.startsWith("image://")) {
            return icon;
        }
        return "image://icon/" + icon;
    }

    // Reset state on active visibility change
    onActiveChanged: {
        if (active) {
            root.focusSearch();
        } else {
            root.resetSearch();
        }
    }

    // =========================================================================
    // LAUNCHER MODAL CARD
    // =========================================================================
    StyledRect {
        id: launcherCard
        anchors.fill: parent
        radius: Tokens.radiusLg
        elevated: true
        color: Theme.alpha(Theme.surfaceElevated, Math.min(Config.themeOpacity, 0.94))
        border.color: Theme.alpha(Theme.accent, 0.35)
        border.width: Tokens.borderWidthThin

        // MouseArea to consume background clicks
        MouseArea {
            anchors.fill: parent
        }

        // =====================================================================
        // 1. APPLICATION RESULTS LIST (Takes all space above search)
        // =====================================================================
        Item {
            id: listContainer
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: searchFooter.top
            anchors.margins: Tokens.spaceSm
            clip: true

            // Standard Application List
            ListView {
                id: listView
                anchors.fill: parent
                model: root.filteredApplications
                currentIndex: root.selectedIndex
                spacing: Tokens.spaceXxs
                visible: !root.isCommandMode && root.filteredApplications.length > 0
                boundsBehavior: Flickable.StopAtBounds

                delegate: Rectangle {
                    id: delegateCard
                    required property var modelData
                    required property int index

                    readonly property bool isSelected: index === root.selectedIndex
                    readonly property bool isHovered: itemMouse.containsMouse

                    width: listView.width
                    height: 52
                    radius: Tokens.radiusMd

                    color: {
                        if (delegateCard.isSelected) return Theme.alpha(Theme.selection, 0.45);
                        if (delegateCard.isHovered) return Theme.alpha(Theme.surface, 0.5);
                        return "transparent";
                    }

                    border.width: delegateCard.isSelected ? Tokens.borderWidthThin : 0
                    border.color: Theme.alpha(Theme.accent, 0.6)

                    Row {
                        anchors.fill: parent
                        anchors.leftMargin: Tokens.spaceMd
                        anchors.rightMargin: Tokens.spaceMd
                        spacing: Tokens.spaceMd

                        // Application Icon (32px)
                        Item {
                            anchors.verticalCenter: parent.verticalCenter
                            width: 32
                            height: 32

                            IconImage {
                                id: appIcon
                                anchors.fill: parent
                                source: root.resolveIconSource(delegateCard.modelData ? delegateCard.modelData.icon : "")
                                visible: appIcon.status === Image.Ready
                            }

                            Text {
                                anchors.centerIn: parent
                                visible: appIcon.status !== Image.Ready
                                text: "󰣇"
                                font.family: Tokens.fontFamilyMono
                                font.pixelSize: Tokens.fontXl
                                color: delegateCard.isSelected ? Theme.accent : Theme.foreground
                            }
                        }

                        // Application Name and Description
                        Column {
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.width - 80
                            spacing: 2

                            Text {
                                width: parent.width
                                text: delegateCard.modelData ? (delegateCard.modelData.name || "") : ""
                                font.family: Tokens.fontFamilySans
                                font.pixelSize: Tokens.fontSm
                                font.weight: Tokens.weightBold
                                color: delegateCard.isSelected ? Theme.accent : Theme.foreground
                                elide: Text.ElideRight
                            }

                            Text {
                                width: parent.width
                                text: {
                                    if (!delegateCard.modelData) return "";
                                    return delegateCard.modelData.genericName || delegateCard.modelData.comment || delegateCard.modelData.id || "";
                                }
                                font.family: Tokens.fontFamilySans
                                font.pixelSize: 11
                                color: Theme.mutedForeground
                                elide: Text.ElideRight
                            }
                        }

                        // Return Hint on Selected
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "↵"
                            font.family: Tokens.fontFamilySans
                            font.pixelSize: Tokens.fontSm
                            color: Theme.accent
                            visible: delegateCard.isSelected
                        }
                    }

                    MouseArea {
                        id: itemMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onEntered: root.selectedIndex = delegateCard.index
                        onClicked: root.launchApp(delegateCard.modelData)
                    }
                }
            }

            // Command Mode View
            Rectangle {
                anchors.fill: parent
                visible: root.isCommandMode
                color: "transparent"

                Column {
                    anchors.centerIn: parent
                    spacing: Tokens.spaceMd
                    width: parent.width - Tokens.spaceXl

                    Rectangle {
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: parent.width
                        height: 64
                        radius: Tokens.radiusMd
                        color: Theme.alpha(Theme.accent, 0.15)
                        border.color: Theme.accent
                        border.width: Tokens.borderWidthThin

                        Row {
                            anchors.fill: parent
                            anchors.margins: Tokens.spaceMd
                            spacing: Tokens.spaceMd

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: "󰆍"
                                font.family: Tokens.fontFamilyMono
                                font.pixelSize: 24
                                color: Theme.accent
                            }

                            Column {
                                anchors.verticalCenter: parent.verticalCenter
                                width: parent.width - 60
                                spacing: 2

                                Text {
                                    text: root.commandText.length > 0 ? ("Run: " + root.commandText) : "Terminal Command Mode"
                                    font.family: Tokens.fontFamilyMono
                                    font.pixelSize: Tokens.fontSm
                                    font.weight: Tokens.weightBold
                                    color: Theme.foreground
                                    elide: Text.ElideRight
                                    width: parent.width
                                }

                                Text {
                                    text: root.commandText.length > 0
                                        ? ("Press Enter to execute in " + Config.terminalCommand)
                                        : "Type a command to execute in terminal..."
                                    font.family: Tokens.fontFamilySans
                                    font.pixelSize: 11
                                    color: Theme.mutedForeground
                                }
                            }
                        }
                    }
                }
            }

            // Empty Search State
            Column {
                anchors.centerIn: parent
                spacing: Tokens.spaceSm
                visible: !root.isCommandMode && root.filteredApplications.length === 0

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "󰮗"
                    font.family: Tokens.fontFamilyMono
                    font.pixelSize: Tokens.fontTitle
                    color: Theme.mutedForeground
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: root.searchQuery.length > 0 ? "No applications found" : "No applications available"
                    font.family: Tokens.fontFamilySans
                    font.pixelSize: Tokens.fontSm
                    font.weight: Tokens.weightMedium
                    color: Theme.mutedForeground
                }
            }
        }

        // =====================================================================
        // 2. SEARCH & COMMAND INPUT CAPSULE (Pinned at the bottom)
        // Matching primary visual reference: Type ">" for commands
        // =====================================================================
        Rectangle {
            id: searchFooter
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.margins: Tokens.spaceSm
            height: 48
            radius: Tokens.radiusFull
            color: Theme.alpha(Theme.surface, 0.75)
            border.color: (searchInput && searchInput.activeFocus) ? Theme.accent : (Theme.border ? Theme.alpha(Theme.border, 0.5) : "#313244")
            border.width: Tokens.borderWidthThin

            Row {
                anchors.fill: parent
                anchors.leftMargin: Tokens.spaceMd
                anchors.rightMargin: Tokens.spaceMd
                spacing: Tokens.spaceSm

                // Search / Command Glyph
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.isCommandMode ? "󰆍" : "󰍉"
                    font.family: Tokens.fontFamilyMono
                    font.pixelSize: Tokens.fontBase
                    color: (searchInput && searchInput.activeFocus) ? Theme.accent : (Theme.mutedForeground || "#a6adc8")

                    Behavior on color {
                        ColorAnimation { duration: Tokens.durationFast }
                    }
                }

                // Search TextInput
                TextInput {
                    id: searchInput
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width - 80
                    font.family: Tokens.fontFamilySans
                    font.pixelSize: Tokens.fontSm
                    color: Theme.foreground
                    clip: true
                    selectByMouse: true

                    // Placeholder Text
                    Text {
                        anchors.fill: parent
                        text: 'Type ">" for commands'
                        font.family: Tokens.fontFamilySans
                        font.pixelSize: Tokens.fontSm
                        color: Theme.alpha(Theme.mutedForeground, 0.6)
                        visible: searchInput.text.length === 0
                    }

                    // Keyboard Navigation Handlers
                    Keys.onDownPressed: {
                        if (root.filteredApplications.length > 0) {
                            root.selectedIndex = (root.selectedIndex + 1) % root.filteredApplications.length;
                            listView.positionViewAtIndex(root.selectedIndex, ListView.Contain);
                        }
                    }

                    Keys.onUpPressed: {
                        if (root.filteredApplications.length > 0) {
                            root.selectedIndex = (root.selectedIndex - 1 + root.filteredApplications.length) % root.filteredApplications.length;
                            listView.positionViewAtIndex(root.selectedIndex, ListView.Contain);
                        }
                    }

                    Keys.onReturnPressed: root.launchSelected()
                    Keys.onEnterPressed: root.launchSelected()
                    Keys.onEscapePressed: root.closeRequested()
                }

                // Clear Button (visible when text is entered)
                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    width: 20
                    height: 20
                    radius: Tokens.radiusFull
                    visible: searchInput.text.length > 0
                    color: clearMouse.containsMouse ? Theme.alpha(Theme.foreground, 0.2) : "transparent"

                    Text {
                        anchors.centerIn: parent
                        text: "✕"
                        font.family: Tokens.fontFamilySans
                        font.pixelSize: Tokens.fontXs
                        color: Theme.mutedForeground
                    }

                    MouseArea {
                        id: clearMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            searchInput.text = "";
                            searchInput.forceActiveFocus();
                        }
                    }
                }

                // Iris Branding Logo Badge
                Image {
                    anchors.verticalCenter: parent.verticalCenter
                    width: 18
                    height: 18
                    source: Qt.resolvedUrl("../../assets/iris_logo/iris-small.svg")
                    sourceSize.width: 18
                    sourceSize.height: 18
                    opacity: 0.65
                }
            }
        }
    }
}
