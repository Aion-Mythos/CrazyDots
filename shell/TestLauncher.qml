import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import "."
import "components"
import "panels"

/**
 * TestLauncher.qml
 * Automated test harness for crazydots M5 Application Launcher.
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

    // Instantiated Launcher for testing
    Launcher {
        id: testLauncher
        active: true
    }

    // Instantiated ScreenCanvas for testing focus and mask transitions
    ScreenCanvas {
        id: testCanvas
        screen: Quickshell.screens.length > 0 ? Quickshell.screens[0] : null
        launcherOpen: false
    }

    // Mock application object for launch testing
    QtObject {
        id: mockApp
        property string id: "org.crazydots.testapp"
        property string name: "Crazydots Test App"
        property string genericName: "Test Utility"
        property string comment: "Automated test application"
        property string icon: "utilities-terminal"
        property bool noDisplay: false
        property bool wasExecuted: false

        function execute() {
            mockApp.wasExecuted = true;
        }
    }

    property bool appLaunchedFired: false
    property bool closeRequestedFired: false

    Connections {
        target: testLauncher
        function onAppLaunched(app) {
            testRoot.appLaunchedFired = true;
        }
        function onCloseRequested() {
            testRoot.closeRequestedFired = true;
        }
    }

    Timer {
        id: testTimer
        interval: 500
        running: true
        repeat: false

        onTriggered: {
            console.log("=== CRAZYDOTS TEST SUITE: M5 APPLICATION LAUNCHER ===");

            // 1. Desktop Application Discovery Tests
            testRoot.assert(Array.isArray(testLauncher.allApplications), "Launcher retrieves allApplications as an array");
            testRoot.assert(testLauncher.allApplications.length > 0, "Launcher discovered installed applications (count: " + testLauncher.allApplications.length + ")");

            let hasHidden = false;
            for (let i = 0; i < testLauncher.allApplications.length; i++) {
                if (testLauncher.allApplications[i].noDisplay === true) {
                    hasHidden = true;
                    break;
                }
            }
            testRoot.assert(!hasHidden, "Launcher filters out noDisplay applications");

            // 2. Default & Query Search Filtering Tests
            testRoot.assert(Array.isArray(testLauncher.filteredApplications), "Launcher provides filteredApplications array");
            testRoot.assert(testLauncher.filteredApplications.length <= Config.launcherMaxResults,
                            "Filtered applications count (" + testLauncher.filteredApplications.length + ") does not exceed Config.launcherMaxResults (" + Config.launcherMaxResults + ")");

            // Search by name
            testLauncher.searchQuery = "ghostty";
            let foundGhostty = false;
            for (let i = 0; i < testLauncher.filteredApplications.length; i++) {
                if ((testLauncher.filteredApplications[i].name || "").toLowerCase().indexOf("ghostty") !== -1) {
                    foundGhostty = true;
                    break;
                }
            }
            testRoot.assert(foundGhostty, "Search for 'ghostty' successfully finds Ghostty application");

            // Search by keyword / generic name
            testLauncher.searchQuery = "terminal";
            testRoot.assert(testLauncher.filteredApplications.length > 0, "Search for 'terminal' returns results based on categories/keywords");

            // Non-existent search query
            testLauncher.searchQuery = "xyznonexistentapp999999";
            testRoot.assert(testLauncher.filteredApplications.length === 0, "Non-existent search query returns 0 results");
            testRoot.assert(testLauncher.selectedIndex === 0, "Selected index remains safe (0) on empty results");

            // Reset search
            testLauncher.resetSearch();
            testRoot.assert(testLauncher.searchQuery === "", "resetSearch() clears query string");
            testRoot.assert(testLauncher.selectedIndex === 0, "resetSearch() resets selectedIndex to 0");

            // 3. Selection & Keyboard Navigation Tests
            testRoot.assert(testLauncher.selectedIndex === 0, "Initial selectedIndex is 0");
            testLauncher.selectedIndex = 2;
            testRoot.assert(testLauncher.selectedIndex === 2, "selectedIndex updates when changed");

            // 4. Safe Launch & Signal Emission Tests
            testRoot.appLaunchedFired = false;
            testRoot.closeRequestedFired = false;
            mockApp.wasExecuted = false;

            testLauncher.launchApp(mockApp);
            testRoot.assert(mockApp.wasExecuted, "launchApp() executes application delegate safely");
            testRoot.assert(testRoot.appLaunchedFired, "launchApp() emits appLaunched signal");
            testRoot.assert(testRoot.closeRequestedFired, "launchApp() emits closeRequested signal to dismiss modal");
            testRoot.assert(testLauncher.isLaunching === true, "launchApp() sets isLaunching flag during cooldown");

            // Duplicate launch prevention
            mockApp.wasExecuted = false;
            testLauncher.launchApp(mockApp);
            testRoot.assert(!mockApp.wasExecuted, "Duplicate launch blocked while isLaunching cooldown is active");

            // 5. Layer-Shell Canvas Coordination & Focus Tests
            testRoot.assert(testCanvas.isLauncherActive === false, "Canvas launcher is initially inactive");
            testRoot.assert(testCanvas.WlrLayershell.keyboardFocus === WlrKeyboardFocus.None,
                            "Idle canvas has WlrKeyboardFocus.None (zero keyboard interception)");

            // Activate launcher on canvas
            testCanvas.launcherOpen = true;
            testRoot.assert(testCanvas.isLauncherActive === true, "Canvas activates when launcherOpen is true");
            testRoot.assert(testCanvas.WlrLayershell.keyboardFocus === WlrKeyboardFocus.Exclusive,
                            "Active canvas claims WlrKeyboardFocus.Exclusive (routes keystrokes to search input)");

            // Deactivate launcher on canvas
            testCanvas.launcherOpen = false;
            testRoot.assert(testCanvas.isLauncherActive === false, "Canvas deactivates when launcherOpen is false");
            testRoot.assert(testCanvas.WlrLayershell.keyboardFocus === WlrKeyboardFocus.None,
                            "Canvas restores WlrKeyboardFocus.None upon closing");

            // 6. Icon Resolution Helper Tests
            testRoot.assert(testLauncher.resolveIconSource("") === "", "resolveIconSource('') returns empty string");
            testRoot.assert(testLauncher.resolveIconSource("/usr/share/pixmaps/app.png") === "/usr/share/pixmaps/app.png",
                            "resolveIconSource preserves absolute paths");
            testRoot.assert(testLauncher.resolveIconSource("kwrite") === "image://icon/kwrite",
                            "resolveIconSource wraps system icon names with image://icon/");

            // 7. Theme Responsiveness
            Theme.setTheme("tokyo-night");
            testRoot.assert(Theme.activeThemeName === "tokyo-night", "Theme switches to 'tokyo-night'");
            Theme.setTheme("crazydots-default");
            testRoot.assert(Theme.activeThemeName === "crazydots-default", "Theme restored to 'crazydots-default'");

            console.log("==========================================");
            console.log("TESTS PASSED:", testRoot.passedTests);
            console.log("TESTS FAILED:", testRoot.failedTests);
            console.log("==========================================");

            if (testRoot.failedTests === 0) {
                console.log("ALL M5 APPLICATION LAUNCHER TESTS PASSED SUCCESSFULLY.");
            } else {
                console.error("M5 APPLICATION LAUNCHER TESTS ENCOUNTERED FAILURES.");
            }

            Qt.quit();
        }
    }
}
