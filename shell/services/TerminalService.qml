import QtQuick
import Quickshell
import Quickshell.Io
import ".."

/**
 * TerminalService.qml
 * Safe launch and metadata service for Ghostty and preferred terminal emulators.
 *
 * Responsibilities:
 * - Detects presence of preferred terminal (Ghostty) via DesktopEntries and Process probe.
 * - Launches terminal safely using DesktopEntry.execute() or Process without arbitrary shell execution.
 * - Handles missing binaries and execution failures gracefully.
 * - Exposes truthful availability status to dashboard and IPC callers.
 */
Item {
    id: root

    property bool isTerminalAvailable: false
    property string terminalDisplayName: "Ghostty"
    property string terminalIcon: "com.mitchellh.ghostty"

    signal terminalLaunched(string command)
    signal terminalLaunchFailed(string reason)

    // Probe terminal executable availability safely via Process
    Process {
        id: probeProc
        command: ["which", Config.terminalCommand]
        running: true

        stdout: StdioCollector {
            onStreamFinished: {
                const out = (text || "").trim();
                root.isTerminalAvailable = out.length > 0 && out.indexOf(Config.terminalCommand) !== -1;
            }
        }
    }

    // Process launcher instance for safe invocation with argument array
    Process {
        id: launchProc
        running: false

        onExited: (code) => {
            if (code !== 0) {
                root.terminalLaunchFailed("Terminal process exited with code " + code);
            }
        }
    }

    function refreshProbe() {
        probeProc.command = ["which", Config.terminalCommand];
        probeProc.running = true;
    }

    function launchTerminal(args): bool {
        const cmd = Config.terminalCommand;
        if (!cmd || cmd.trim().length === 0) {
            root.terminalLaunchFailed("Empty terminal command configured");
            return false;
        }

        // 1. First preference: Launch via Quickshell DesktopEntries if no custom args
        if (!args || args.length === 0) {
            const apps = (typeof DesktopEntries !== "undefined" && DesktopEntries.applications)
                ? DesktopEntries.applications.values
                : [];
            const targetId = Config.terminalAppId;
            for (let i = 0; i < apps.length; i++) {
                const app = apps[i];
                if (app && (app.id === targetId || app.id === targetId + ".desktop" || app.name.toLowerCase() === cmd.toLowerCase())) {
                    try {
                        app.execute();
                        root.terminalLaunched(app.name);
                        return true;
                    } catch (e) {
                        console.warn("crazydots: DesktopEntry.execute() failed, falling back to Process:", e);
                    }
                }
            }
        }

        // 2. Safe fallback: Spawn binary directly with argv array (zero shell interpretation)
        const cmdList = [cmd];
        if (Array.isArray(args)) {
            for (let j = 0; j < args.length; j++) {
                cmdList.push(String(args[j]));
            }
        }

        try {
            launchProc.command = cmdList;
            launchProc.running = true;
            root.terminalLaunched(cmd);
            return true;
        } catch (err) {
            root.terminalLaunchFailed(String(err));
            return false;
        }
    }

    Component.onCompleted: {
        root.refreshProbe();
    }
}
