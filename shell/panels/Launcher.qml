import QtQuick
import Quickshell
import Quickshell.Widgets
import ".."
import "../components"

/**
 * Launcher.qml
 * Native application launcher modal for crazydots.
 *
 * Responsibilities:
 * - Enumerates installed desktop applications using Quickshell.DesktopEntries.
 * - Filters applications reactively by name, generic name, comment, id, and keywords.
 * - Supports keyboard navigation (Up/Down, Enter to launch, Escape to close).
 * - Displays application icons via Quickshell.Widgets.IconImage with graceful glyph fallbacks.
 * - Prevents duplicate activations with execution debouncing.
 * - Emits clean closeRequested() and appLaunched() signals.
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

    // Sizing
    implicitWidth: 580
    implicitHeight: launcherCard.height

    // =========================================================================
    // DESKTOP APPLICATION SEARCH ENGINE
    // =========================================================================
    readonly property var allApplications: {
        const raw = DesktopEntries.applications ? DesktopEntries.applications.values : [];
        if (!raw || raw.length === 0) return [];

        const list = [];
        for (let i = 0; i < raw.length; i++) {
            const entry = raw[i];
            // Expose only user-visible desktop entries
            if (!entry.noDisplay) {
                list.push(entry);
            }
        }
        return list;
    }

    readonly property var filteredApplications: {
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

    // Keep selected index within bounds when results change
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

    // =========================================================================
    // LAUNCHER MODAL CARD
    // =========================================================================
    StyledRect {
        id: launcherCard
        anchors.horizontalCenter: parent.horizontalCenter
        width: parent.width
        height: contentColumn.height
        radius: Tokens.radiusLg
        elevated: true
        color: Theme.alpha(Theme.surfaceElevated, 0.95)
        border.color: Theme.alpha(Theme.accent, 0.4)
        border.width: Tokens.borderWidthThin

        Column {
            id: contentColumn
            width: parent.width
            spacing: 0

            // -----------------------------------------------------------------
            // 1. SEARCH INPUT HEADER
            // -----------------------------------------------------------------
            Item {
                id: searchHeader
                width: parent.width
                height: 64

                Row {
                    anchors.fill: parent
                    anchors.leftMargin: Tokens.spaceLg
                    anchors.rightMargin: Tokens.spaceLg
                    spacing: Tokens.spaceMd

                    // Search Glyph
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "󰍉"
                        font.family: Tokens.fontFamilyMono
                        font.pixelSize: Tokens.fontTitle
                        color: searchInput.activeFocus ? Theme.accent : Theme.mutedForeground
                        renderType: Text.NativeRendering

                        Behavior on color {
                            ColorAnimation { duration: Tokens.durationFast }
                        }
                    }

                    // Search TextInput
                    TextInput {
                        id: searchInput
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width - 90
                        font.family: Tokens.fontFamilySans
                        font.pixelSize: Tokens.fontLg
                        color: Theme.foreground
                        clip: true
                        selectByMouse: true
                        renderType: Text.NativeRendering

                        // Placeholder Text
                        Text {
                            anchors.fill: parent
                            text: "Search applications..."
                            font.family: Tokens.fontFamilySans
                            font.pixelSize: Tokens.fontLg
                            color: Theme.alpha(Theme.mutedForeground, 0.6)
                            visible: searchInput.text.length === 0
                            renderType: Text.NativeRendering
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

                    // Clear Search Button
                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        width: 24
                        height: 24
                        radius: Tokens.radiusFull
                        visible: searchInput.text.length > 0
                        color: clearMouse.containsMouse ? Theme.alpha(Theme.foreground, 0.2) : "transparent"

                        Text {
                            anchors.centerIn: parent
                            text: "✕"
                            font.family: Tokens.fontFamilySans
                            font.pixelSize: Tokens.fontSm
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
                }

                // Divider line below search bar
                Rectangle {
                    anchors.bottom: parent.bottom
                    anchors.left: parent.left
                    anchors.right: parent.right
                    height: Tokens.borderWidthThin
                    color: Theme.alpha(Theme.border, 0.6)
                }
            }

            // -----------------------------------------------------------------
            // 2. RESULTS LIST
            // -----------------------------------------------------------------
            Item {
                id: resultsArea
                width: parent.width
                height: root.filteredApplications.length > 0
                        ? Math.min(root.filteredApplications.length * Config.launcherItemHeight, 420)
                        : (root.searchQuery.length > 0 ? 120 : 60)

                Behavior on height {
                    NumberAnimation {
                        duration: Tokens.durationFast
                        easing.type: Tokens.easingStandard.type
                        easing.bezierCurve: Tokens.easingStandard.bezierCurve
                    }
                }

                // Applications List View with full scrolling support
                ListView {
                    id: listView
                    anchors.fill: parent
                    anchors.margins: Tokens.spaceSm
                    clip: true
                    model: root.filteredApplications
                    currentIndex: root.selectedIndex
                    spacing: Tokens.spaceXxs
                    visible: root.filteredApplications.length > 0
                    boundsBehavior: Flickable.StopAtBounds

                    delegate: Rectangle {
                        id: delegateCard
                        required property var modelData
                        required property int index

                        readonly property bool isSelected: index === root.selectedIndex
                        readonly property bool isHovered: itemMouse.containsMouse

                        width: listView.width
                        height: Config.launcherItemHeight
                        radius: Tokens.radiusMd

                        // Background highlighting
                        color: {
                            if (delegateCard.isSelected) return Theme.alpha(Theme.accent, 0.18);
                            if (delegateCard.isHovered) return Theme.alpha(Theme.surface, 0.6);
                            return "transparent";
                        }

                        border.width: delegateCard.isSelected ? Tokens.borderWidthThin : 0
                        border.color: Theme.accent

                        Behavior on color {
                            ColorAnimation { duration: Tokens.durationFast }
                        }

                        Row {
                            anchors.fill: parent
                            anchors.leftMargin: Tokens.spaceMd
                            anchors.rightMargin: Tokens.spaceMd
                            spacing: Tokens.spaceMd

                            // Application Icon
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

                                // Fallback Icon Glyph when image fails or is missing
                                Text {
                                    anchors.centerIn: parent
                                    visible: appIcon.status !== Image.Ready
                                    text: "󰣇"
                                    font.family: Tokens.fontFamilyMono
                                    font.pixelSize: Tokens.fontXl
                                    color: delegateCard.isSelected ? Theme.accent : Theme.foreground
                                    renderType: Text.NativeRendering
                                }
                            }

                            // Application Name and Description
                            Column {
                                anchors.verticalCenter: parent.verticalCenter
                                width: parent.width - 100
                                spacing: 2

                                Text {
                                    width: parent.width
                                    text: delegateCard.modelData ? (delegateCard.modelData.name || "") : ""
                                    font.family: Tokens.fontFamilySans
                                    font.pixelSize: Tokens.fontBase
                                    font.weight: delegateCard.isSelected ? Tokens.weightBold : Tokens.weightMedium
                                    color: delegateCard.isSelected ? Theme.accent : Theme.foreground
                                    elide: Text.ElideRight
                                    renderType: Text.NativeRendering
                                }

                                Text {
                                    width: parent.width
                                    text: {
                                        if (!delegateCard.modelData) return "";
                                        return delegateCard.modelData.genericName || delegateCard.modelData.comment || delegateCard.modelData.id || "";
                                    }
                                    font.family: Tokens.fontFamilySans
                                    font.pixelSize: Tokens.fontXs
                                    color: Theme.mutedForeground
                                    elide: Text.ElideRight
                                    renderType: Text.NativeRendering
                                }
                            }

                            // Return Key Hint indicator
                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: "↵"
                                font.family: Tokens.fontFamilySans
                                font.pixelSize: Tokens.fontBase
                                color: Theme.accent
                                visible: delegateCard.isSelected
                                renderType: Text.NativeRendering
                            }
                        }

                        MouseArea {
                            id: itemMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor

                            onEntered: {
                                root.selectedIndex = delegateCard.index;
                            }

                            onClicked: {
                                root.launchApp(delegateCard.modelData);
                            }
                        }
                    }
                }

                // Empty Results State
                Column {
                    anchors.centerIn: parent
                    spacing: Tokens.spaceSm
                    visible: root.filteredApplications.length === 0

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "󰮗"
                        font.family: Tokens.fontFamilyMono
                        font.pixelSize: Tokens.fontTitle
                        color: Theme.mutedForeground
                        renderType: Text.NativeRendering
                    }

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: root.searchQuery.length > 0 ? "No applications found" : "No applications available"
                        font.family: Tokens.fontFamilySans
                        font.pixelSize: Tokens.fontSm
                        font.weight: Tokens.weightMedium
                        color: Theme.mutedForeground
                        renderType: Text.NativeRendering
                    }
                }
            }

            // -----------------------------------------------------------------
            // 3. KEYBOARD SHORTCUTS FOOTER
            // -----------------------------------------------------------------
            Item {
                id: footerArea
                width: parent.width
                height: 38

                // Divider line above footer
                Rectangle {
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.right: parent.right
                    height: Tokens.borderWidthThin
                    color: Theme.alpha(Theme.border, 0.4)
                }

                Row {
                    anchors.fill: parent
                    anchors.leftMargin: Tokens.spaceMd
                    anchors.rightMargin: Tokens.spaceMd
                    spacing: Tokens.spaceLg

                    Row {
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: Tokens.spaceXs

                        Text {
                            text: "↑↓"
                            font.family: Tokens.fontFamilyMono
                            font.pixelSize: Tokens.fontXs
                            color: Theme.accent
                        }
                        Text {
                            text: "Navigate"
                            font.family: Tokens.fontFamilySans
                            font.pixelSize: Tokens.fontXs
                            color: Theme.mutedForeground
                        }
                    }

                    Row {
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: Tokens.spaceXs

                        Text {
                            text: "↵"
                            font.family: Tokens.fontFamilyMono
                            font.pixelSize: Tokens.fontXs
                            color: Theme.accent
                        }
                        Text {
                            text: "Launch"
                            font.family: Tokens.fontFamilySans
                            font.pixelSize: Tokens.fontXs
                            color: Theme.mutedForeground
                        }
                    }

                    Row {
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: Tokens.spaceXs

                        Text {
                            text: "Esc"
                            font.family: Tokens.fontFamilyMono
                            font.pixelSize: Tokens.fontXs
                            color: Theme.accent
                        }
                        Text {
                            text: "Dismiss"
                            font.family: Tokens.fontFamilySans
                            font.pixelSize: Tokens.fontXs
                            color: Theme.mutedForeground
                        }
                    }
                }

                // Application count badge
                Text {
                    anchors.right: parent.right
                    anchors.rightMargin: Tokens.spaceMd
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.filteredApplications.length + " / " + root.allApplications.length
                    font.family: Tokens.fontFamilyMono
                    font.pixelSize: Tokens.fontXs
                    color: Theme.alpha(Theme.mutedForeground, 0.7)
                }
            }
        }
    }
}
