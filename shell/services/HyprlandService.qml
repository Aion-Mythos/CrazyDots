import QtQuick
import Quickshell
import Quickshell.Hyprland

/**
 * HyprlandService.qml
 * Central integration service for compositor state and dispatchers.
 *
 * Responsibilities:
 * - Direct reactive binding to Quickshell.Hyprland singleton.
 * - Exposes sanitized snapshot objects for active workspace, available workspaces,
 *   active window title, and monitor metadata without duplicate competing state.
 * - Handles workspace activation and dispatching with strict argument validation.
 * - Graceful degradation when compositor is disconnected or unavailable.
 */
Item {
    id: root

    readonly property bool isAvailable: {
        return (Hyprland.eventSocketPath !== undefined && Hyprland.eventSocketPath.length > 0) ||
               (Hyprland.monitors && Hyprland.monitors.values && Hyprland.monitors.values.length > 0);
    }

    readonly property var focusedMonitor: Hyprland.focusedMonitor
    readonly property var focusedWorkspace: Hyprland.focusedWorkspace
    readonly property var activeToplevel: Hyprland.activeToplevel

    readonly property int activeWorkspaceId: focusedWorkspace ? focusedWorkspace.id : 1
    readonly property string activeWorkspaceName: focusedWorkspace ? (focusedWorkspace.name || String(focusedWorkspace.id)) : "1"
    readonly property string activeWindowTitle: (activeToplevel && activeToplevel.title) ? activeToplevel.title : ""
    readonly property string activeWindowAddress: (activeToplevel && activeToplevel.address) ? activeToplevel.address : ""

    function getActiveWorkspace() {
        const ws = root.focusedWorkspace;
        if (!ws) {
            return {
                id: 1,
                name: "1",
                active: true,
                focused: true,
                urgent: false
            };
        }
        return {
            id: ws.id,
            name: ws.name || String(ws.id),
            active: ws.active,
            focused: ws.focused,
            urgent: ws.urgent
        };
    }

    function getWorkspaces() {
        const list = [];
        const raw = Hyprland.workspaces ? Hyprland.workspaces.values : [];
        if (!raw || raw.length === 0) return list;

        for (let i = 0; i < raw.length; i++) {
            const ws = raw[i];
            if (ws && ws.id > 0) {
                list.push({
                    id: ws.id,
                    name: ws.name || String(ws.id),
                    active: ws.active,
                    focused: ws.focused,
                    urgent: ws.urgent,
                    monitorId: ws.monitor ? ws.monitor.id : -1
                });
            }
        }
        list.sort((a, b) => a.id - b.id);
        return list;
    }

    function getActiveWindow() {
        const win = root.activeToplevel;
        if (!win) {
            return {
                title: "",
                address: "",
                activated: false,
                urgent: false,
                workspaceId: -1,
                monitorId: -1
            };
        }
        return {
            title: win.title || "",
            address: win.address || "",
            activated: win.activated,
            urgent: win.urgent,
            workspaceId: win.workspace ? win.workspace.id : -1,
            monitorId: win.monitor ? win.monitor.id : -1
        };
    }

    function focusWorkspace(id: int): bool {
        if (typeof id !== "number" || isNaN(id) || id <= 0) {
            console.warn("crazydots: Rejected invalid workspace ID:", id);
            return false;
        }

        const raw = Hyprland.workspaces ? Hyprland.workspaces.values : [];
        for (let i = 0; i < raw.length; i++) {
            if (raw[i].id === id) {
                if (typeof raw[i].activate === "function") {
                    raw[i].activate();
                    return true;
                }
                break;
            }
        }

        try {
            Hyprland.dispatch("workspace " + id);
        } catch (e) {
            console.warn("crazydots: Hyprland.dispatch fallback error:", e);
        }
        return true;
    }

    function dispatch(request: string): bool {
        if (!request || typeof request !== "string") return false;
        const clean = request.trim();
        if (clean.length === 0) return false;

        // Disallow dangerous multi-line or command-chaining injections
        if (clean.indexOf("\n") !== -1 || clean.indexOf(";") !== -1 || clean.indexOf("&") !== -1) {
            console.warn("crazydots: Rejected unsafe Hyprland dispatch request:", clean);
            return false;
        }

        Hyprland.dispatch(clean);
        return true;
    }

    function refresh() {
        if (typeof Hyprland.refreshWorkspaces === "function") Hyprland.refreshWorkspaces();
        if (typeof Hyprland.refreshMonitors === "function") Hyprland.refreshMonitors();
        if (typeof Hyprland.refreshToplevels === "function") Hyprland.refreshToplevels();
    }

    Component.onCompleted: {
        root.refresh();
    }
}
