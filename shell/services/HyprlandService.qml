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
            return true;
        } catch (e) {
            console.warn("crazydots: Hyprland.dispatch fallback error:", e);
            return false;
        }
    }

    /**
     * dispatch(request: string): bool
     * Strictly allowlisted and argument-validated Hyprland dispatcher proxy.
     * Prevents arbitrary command execution, shell metacharacter injection,
     * and invalid argument types.
     */
    function dispatch(request: string): bool {
        if (!request || typeof request !== "string") return false;
        const clean = request.trim();
        if (clean.length === 0) return false;

        // 1. Structural check: Reject command chaining, shell metacharacters, or control codes
        if (/[\n\r;&|`$><]/.test(clean)) {
            console.warn("crazydots: Rejected unsafe characters in Hyprland dispatch request:", clean);
            return false;
        }

        // Special test dispatcher support:
        if (clean === "hl.dsp.no_op()" || clean === "no_op") {
            try {
                Hyprland.dispatch(clean);
                return true;
            } catch (e) {
                console.warn("crazydots: Hyprland dispatch error:", e);
                return false;
            }
        }

        // 2. Tokenize into operation and argument
        const spaceIdx = clean.search(/\s/);
        const op = (spaceIdx === -1 ? clean : clean.slice(0, spaceIdx)).toLowerCase();
        const arg = spaceIdx === -1 ? "" : clean.slice(spaceIdx).trim();

        // 3. Strict allowlist validation
        switch (op) {
            case "workspace":
                // Numeric ID (e.g. "1", "12")
                if (/^[1-9][0-9]*$/.test(arg)) {
                    const wsId = parseInt(arg, 10);
                    return root.focusWorkspace(wsId);
                }
                // Relative workspace navigation: e+1, e-1, m+1, m-1, r+1, r-1, empty, previous
                if (/^(e|m|r)[+-]([1-9][0-9]*)?$/.test(arg) || arg === "empty" || arg === "previous") {
                    try {
                        Hyprland.dispatch("workspace " + arg);
                        return true;
                    } catch (e) {
                        console.warn("crazydots: Hyprland dispatch error:", e);
                        return false;
                    }
                }
                // Named workspace (e.g. "name:code")
                if (/^name:[a-zA-Z0-9_\-\.]+$/.test(arg)) {
                    try {
                        Hyprland.dispatch("workspace " + arg);
                        return true;
                    } catch (e) {
                        console.warn("crazydots: Hyprland dispatch error:", e);
                        return false;
                    }
                }
                console.warn("crazydots: Rejected invalid argument for 'workspace' dispatcher:", arg);
                return false;

            case "movetoworkspace":
            case "movetoworkspacesilent":
                if (/^[1-9][0-9]*$/.test(arg) || /^(e|m|r)[+-]([1-9][0-9]*)?$/.test(arg) || arg === "empty" || /^name:[a-zA-Z0-9_\-\.]+$/.test(arg)) {
                    try {
                        Hyprland.dispatch(op + " " + arg);
                        return true;
                    } catch (e) {
                        console.warn("crazydots: Hyprland dispatch error:", e);
                        return false;
                    }
                }
                console.warn("crazydots: Rejected invalid argument for '" + op + "' dispatcher:", arg);
                return false;

            case "focuswindow":
                if (/^(address:)?0x[0-9a-fA-F]+$/.test(arg) || /^(class|title):[a-zA-Z0-9_\-\. ]+$/.test(arg)) {
                    try {
                        Hyprland.dispatch("focuswindow " + arg);
                        return true;
                    } catch (e) {
                        console.warn("crazydots: Hyprland dispatch error:", e);
                        return false;
                    }
                }
                console.warn("crazydots: Rejected invalid argument for 'focuswindow' dispatcher:", arg);
                return false;

            case "closewindow":
                if (/^(address:)?0x[0-9a-fA-F]+$/.test(arg)) {
                    try {
                        Hyprland.dispatch("closewindow " + arg);
                        return true;
                    } catch (e) {
                        console.warn("crazydots: Hyprland dispatch error:", e);
                        return false;
                    }
                }
                console.warn("crazydots: Rejected invalid argument for 'closewindow' dispatcher:", arg);
                return false;

            case "killactive":
                if (arg.length > 0) {
                    console.warn("crazydots: 'killactive' dispatcher takes no arguments, received:", arg);
                    return false;
                }
                try {
                    Hyprland.dispatch("killactive");
                    return true;
                } catch (e) {
                    console.warn("crazydots: Hyprland dispatch error:", e);
                    return false;
                }

            case "fullscreen":
                if (arg === "" || /^(0|1|2|monocle)$/.test(arg)) {
                    try {
                        Hyprland.dispatch(arg ? ("fullscreen " + arg) : "fullscreen");
                        return true;
                    } catch (e) {
                        console.warn("crazydots: Hyprland dispatch error:", e);
                        return false;
                    }
                }
                console.warn("crazydots: Rejected invalid argument for 'fullscreen' dispatcher:", arg);
                return false;

            case "togglefloating":
                if (arg === "" || /^(address:)?0x[0-9a-fA-F]+$/.test(arg)) {
                    try {
                        Hyprland.dispatch(arg ? ("togglefloating " + arg) : "togglefloating");
                        return true;
                    } catch (e) {
                        console.warn("crazydots: Hyprland dispatch error:", e);
                        return false;
                    }
                }
                console.warn("crazydots: Rejected invalid argument for 'togglefloating' dispatcher:", arg);
                return false;

            default:
                console.warn("crazydots: Rejected unapproved or unknown Hyprland dispatcher operation:", op);
                return false;
        }
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
