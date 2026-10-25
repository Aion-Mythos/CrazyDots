import QtQuick
import Quickshell
import Quickshell.Hyprland
import "."
import "services"

/**
 * TestHyprlandGhostty.qml
 * Automated test harness for crazydots M8 Hyprland & Ghostty Integration.
 */
Item {
    id: testRoot
    width: 1024
    height: 768

    property int passedTests: 0
    property int failedTests: 0

    function assert(condition, message) {
        if (condition) {
            console.log("PASS:", message);
            passedTests++;
        } else {
            console.error("FAIL:", message);
            failedTests++;
        }
    }

    // Instantiated HyprlandService
    HyprlandService {
        id: testHyprland
    }

    // Instantiated TerminalService
    TerminalService {
        id: testTerminal
    }

    // Instantiated Main shell coordinator
    Main {
        id: testMain
    }

    property bool terminalLaunchedFired: false
    property bool terminalLaunchFailedFired: false
    property string lastLaunchedCmd: ""

    Connections {
        target: testTerminal
        function onTerminalLaunched(cmd) {
            testRoot.terminalLaunchedFired = true;
            testRoot.lastLaunchedCmd = cmd;
        }
        function onTerminalLaunchFailed(reason) {
            testRoot.terminalLaunchFailedFired = true;
        }
    }

    Timer {
        id: testTimer
        interval: 600
        running: true
        repeat: false

        onTriggered: {
            console.log("=== CRAZYDOTS TEST SUITE: M8 HYPRLAND & GHOSTTY INTEGRATION ===");

            // =================================================================
            // TEST SUITE 1: HYPRLAND SERVICE AVAILABILITY & STATE
            // =================================================================
            console.log("\n--- Suite 1: Hyprland Service Availability & State ---");
            testRoot.assert(typeof testHyprland.isAvailable === "boolean",
                "HyprlandService.isAvailable exposes boolean availability flag (" + testHyprland.isAvailable + ")");

            const activeWs = testHyprland.getActiveWorkspace();
            testRoot.assert(activeWs !== null && typeof activeWs === "object",
                "getActiveWorkspace() returns a valid workspace snapshot object");
            testRoot.assert(typeof activeWs.id === "number" && activeWs.id >= 1,
                "Active workspace ID is a valid positive integer (" + activeWs.id + ")");
            testRoot.assert(typeof activeWs.name === "string" && activeWs.name.length > 0,
                "Active workspace name is non-empty ('" + activeWs.name + "')");
            testRoot.assert(typeof activeWs.focused === "boolean",
                "Active workspace focused property is boolean");

            const wsList = testHyprland.getWorkspaces();
            testRoot.assert(Array.isArray(wsList),
                "getWorkspaces() returns an array of workspace items");
            let hasSpecial = false;
            for (let i = 0; i < wsList.length; i++) {
                if (wsList[i].id < 0) {
                    hasSpecial = true;
                    break;
                }
            }
            testRoot.assert(!hasSpecial,
                "getWorkspaces() filters out negative ID special workspaces");

            // Verify ascending sorting
            let sorted = true;
            for (let j = 1; j < wsList.length; j++) {
                if (wsList[j].id < wsList[j - 1].id) {
                    sorted = false;
                    break;
                }
            }
            testRoot.assert(sorted,
                "getWorkspaces() returns workspaces sorted numerically in ascending order");

            const activeWin = testHyprland.getActiveWindow();
            testRoot.assert(activeWin !== null && typeof activeWin === "object",
                "getActiveWindow() returns an active window snapshot object");
            testRoot.assert(typeof activeWin.title === "string",
                "Active window exposes title string ('" + activeWin.title + "')");
            testRoot.assert(typeof activeWin.address === "string",
                "Active window exposes address string ('" + activeWin.address + "')");

            // =================================================================
            // TEST SUITE 2: HYPRLAND DISPATCH & WORKSPACE ACTIVATION SAFETY
            // =================================================================
            console.log("\n--- Suite 2: Hyprland Dispatch & Workspace Safety ---");
            const focusValid = testHyprland.focusWorkspace(1);
            testRoot.assert(focusValid === true,
                "focusWorkspace(1) accepts valid positive workspace ID");

            const rejectNegative = testHyprland.focusWorkspace(-5);
            testRoot.assert(rejectNegative === false,
                "focusWorkspace(-5) rejects negative workspace ID");

            const rejectZero = testHyprland.focusWorkspace(0);
            testRoot.assert(rejectZero === false,
                "focusWorkspace(0) rejects zero workspace ID");

            const rejectNaN = testHyprland.focusWorkspace(NaN);
            testRoot.assert(rejectNaN === false,
                "focusWorkspace(NaN) rejects non-numeric input");

            // Dispatch safety tests
            const dispatchValid = testHyprland.dispatch(Hyprland.usingLua ? "hl.dsp.no_op()" : "workspace 1");
            testRoot.assert(dispatchValid === true,
                "dispatch() accepts clean dispatcher string");

            const rejectEmpty = testHyprland.dispatch("");
            testRoot.assert(rejectEmpty === false,
                "dispatch('') rejects empty request");

            const rejectNewline = testHyprland.dispatch("workspace 1\nexec evil");
            testRoot.assert(rejectNewline === false,
                "dispatch() rejects multi-line injection string");

            const rejectSemicolon = testHyprland.dispatch("workspace 1; exec evil");
            testRoot.assert(rejectSemicolon === false,
                "dispatch() rejects semicolon command-chaining injection");

            const rejectAmpersand = testHyprland.dispatch("workspace 1 && exec evil");
            testRoot.assert(rejectAmpersand === false,
                "dispatch() rejects ampersand command-chaining injection");

            const rejectUnapproved = testHyprland.dispatch("exec evil_payload");
            testRoot.assert(rejectUnapproved === false,
                "dispatch() rejects unapproved 'exec' dispatcher command via allowlist");

            const rejectPipe = testHyprland.dispatch("workspace 1 | evil");
            testRoot.assert(rejectPipe === false,
                "dispatch() rejects pipe character injection");

            const rejectInvalidWs = testHyprland.dispatch("workspace -9");
            testRoot.assert(rejectInvalidWs === false,
                "dispatch() rejects malformed workspace arguments");

            // =================================================================
            // TEST SUITE 3: GHOSTTY & TERMINAL CONFIGURATION PERSISTENCE
            // =================================================================
            console.log("\n--- Suite 3: Terminal Configuration & Persistence ---");
            testRoot.assert(Config.terminalCommand === "ghostty",
                "Config.terminalCommand defaults to 'ghostty'");
            testRoot.assert(Config.terminalAppId === "com.mitchellh.ghostty",
                "Config.terminalAppId defaults to 'com.mitchellh.ghostty'");

            const setCmdRes = Config.setTerminalCommand("alacritty");
            testRoot.assert(setCmdRes === true && Config.terminalCommand === "alacritty",
                "Config.setTerminalCommand('alacritty') updates terminalCommand property");

            const rejectEmptyCmd = Config.setTerminalCommand("");
            testRoot.assert(rejectEmptyCmd === false,
                "Config.setTerminalCommand('') rejects empty command string");

            const rejectInjectedCmd = Config.setTerminalCommand("ghostty; evil");
            testRoot.assert(rejectInjectedCmd === false,
                "Config.setTerminalCommand() rejects injection metacharacters");

            const rejectSpacesCmd = Config.setTerminalCommand("sh -c evil");
            testRoot.assert(rejectSpacesCmd === false,
                "Config.setTerminalCommand() rejects multi-token command strings");

            const setAppIdRes = Config.setTerminalAppId("org.alacritty");
            testRoot.assert(setAppIdRes === true && Config.terminalAppId === "org.alacritty",
                "Config.setTerminalAppId('org.alacritty') updates terminalAppId property");

            const rejectEmptyAppId = Config.setTerminalAppId("");
            testRoot.assert(rejectEmptyAppId === false,
                "Config.setTerminalAppId('') rejects empty appId string");

            const rejectInjectedAppId = Config.setTerminalAppId("org.app; evil");
            testRoot.assert(rejectInjectedAppId === false,
                "Config.setTerminalAppId() rejects invalid appId characters");

            // Restore defaults
            Config.setTerminalCommand("ghostty");
            Config.setTerminalAppId("com.mitchellh.ghostty");
            testRoot.assert(Config.terminalCommand === "ghostty" && Config.terminalAppId === "com.mitchellh.ghostty",
                "Restoring defaults resets terminal configuration cleanly");

            // Serialization check in toObject()
            const cfgObj = Config.toObject();
            testRoot.assert(cfgObj.terminal !== undefined &&
                            cfgObj.terminal.command === "ghostty" &&
                            cfgObj.terminal.appId === "com.mitchellh.ghostty",
                "Config.toObject() serializes terminal.command and terminal.appId");

            // =================================================================
            // TEST SUITE 4: TERMINAL SERVICE AVAILABILITY & SAFE LAUNCH
            // =================================================================
            console.log("\n--- Suite 4: Terminal Service & Safe Launch ---");
            testRoot.assert(typeof testTerminal.isTerminalAvailable === "boolean",
                "TerminalService.isTerminalAvailable exposes boolean flag (" + testTerminal.isTerminalAvailable + ")");
            testRoot.assert(testTerminal.terminalDisplayName === "Ghostty",
                "TerminalService.terminalDisplayName defaults to 'Ghostty'");
            testRoot.assert(testTerminal.terminalIcon === "com.mitchellh.ghostty",
                "TerminalService.terminalIcon defaults to 'com.mitchellh.ghostty'");

            // Test launch initiation (in test mock, DesktopEntry or Process is invoked)
            testRoot.terminalLaunchedFired = false;
            const launchOk = testTerminal.launchTerminal();
            testRoot.assert(launchOk === true,
                "launchTerminal() returns true on launch initiation");
            testRoot.assert(testRoot.terminalLaunchedFired === true,
                "launchTerminal() emits terminalLaunched signal");

            // =================================================================
            // TEST SUITE 5: IPC INTEGRATION & COMPATIBILITY
            // =================================================================
            console.log("\n--- Suite 5: Main IPC Integration ---");
            testRoot.assert(typeof testMain.isLauncherOpen === "function",
                "Main preserves isLauncherOpen IPC method");
            testRoot.assert(typeof testMain.isWallpaperManagerOpen === "function",
                "Main preserves isWallpaperManagerOpen IPC method");
            testRoot.assert(typeof testMain.isDashboardOpen === "function",
                "Main preserves isDashboardOpen IPC method");

            // =================================================================
            // SUMMARY
            // =================================================================
            console.log("\n=======================================================");
            console.log("CRAZYDOTS M8 TEST RESULTS: " + testRoot.passedTests + " PASSED, " + testRoot.failedTests + " FAILED");
            console.log("=======================================================\n");

            if (testRoot.failedTests === 0) {
                console.log("ALL M8 HYPRLAND & GHOSTTY INTEGRATION TESTS PASSED.");
            } else {
                console.error("M8 HYPRLAND & GHOSTTY INTEGRATION TESTS ENCOUNTERED FAILURES.");
            }

            Qt.quit();
        }
    }
}
