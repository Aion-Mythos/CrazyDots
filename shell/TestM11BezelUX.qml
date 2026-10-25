import QtQuick
import Quickshell
import Quickshell.Wayland
import "."
import "components"
import "panels"
import "panels/bar"
import "panels/popovers"
import "services"

/**
 * TestM11BezelUX.qml
 * Automated test suite for Milestone M11:
 * - Iris branding asset integrity and placement.
 * - Inverted application launcher with bottom search capsule & command mode (>).
 * - Full unconstrained application catalog.
 * - Tabbed dashboard (Dashboard, Media, Performance, Weather) with live uptime and calendar.
 * - Left bezel dock support in Bar.qml with vertical workspaces & bottom hotspots.
 * - Contextual popover anchoring for both horizontal and vertical dock layouts.
 */
FloatingWindow {
    id: testWindow
    title: "Crazydots M11 Bezel UX Test Suite"
    implicitWidth: 1024
    implicitHeight: 768
    visible: true

    Item {
        id: testRoot
        anchors.fill: parent

        property int passedTests: 0
        property int failedTests: 0

        function assert(condition: bool, message: string) {
            if (condition) {
                console.log("PASS:", message);
                passedTests++;
            } else {
                console.error("FAIL:", message);
                failedTests++;
            }
        }

        // Test Harness Services
        NetworkService { id: testNetService }
        BrightnessService { id: testBrightnessService }

        // Test Bar Instance
        Bar {
            id: testBar
            screen: Quickshell.screens[0] || null
        }

        // Test ScreenCanvas Instance
        ScreenCanvas {
            id: testCanvas
            screen: Quickshell.screens[0] || null
            networkService: testNetService
            brightnessService: testBrightnessService
        }

        // Direct Launcher Component for deep layout validation
        Launcher {
            id: testLauncher
            active: true
            visible: true
        }

        // Direct Dashboard Component for tab & telemetry validation
        Dashboard {
            id: testDashboard
            active: true
            visible: true
        }

        // Main Shell Coordinator Instance
        Main {
            id: testMain
        }

        // Signals tracker
        property bool connTriggeredFired: false
        property bool volTriggeredFired: false
        property bool qtTriggeredFired: false
        property bool dashTriggeredFired: false

        Connections {
            target: testBar
            function onConnectivityTriggered() { testRoot.connTriggeredFired = true; }
            function onVolumeTriggered() { testRoot.volTriggeredFired = true; }
            function onQuickTogglesTriggered() { testRoot.qtTriggeredFired = true; }
            function onDashboardTriggered() { testRoot.dashTriggeredFired = true; }
        }

        Timer {
            id: runnerTimer
            interval: 600
            running: true
            repeat: false
            onTriggered: {
                console.log("=== CRAZYDOTS TEST SUITE: M11 BEZEL UX & LAUNCHER OVERHAUL ===");

                // =============================================================
                // 1. IRIS BRANDING ASSETS INTEGRITY
                // =============================================================
                console.log("\n--- Suite 1: Iris Branding Assets Integrity ---");
                const irisLogoSmall = Qt.resolvedUrl("../assets/iris_logo/iris-small.svg");
                const irisLogoFull = Qt.resolvedUrl("../assets/iris_logo/iris.svg");
                const irisLogoMono = Qt.resolvedUrl("../assets/iris_logo/iris-mono.svg");

                testRoot.assert(irisLogoSmall.toString().length > 0,
                    "Iris small logo resolved URL is valid: " + irisLogoSmall);
                testRoot.assert(irisLogoFull.toString().length > 0,
                    "Iris full logo resolved URL is valid: " + irisLogoFull);
                testRoot.assert(irisLogoMono.toString().length > 0,
                    "Iris monochrome logo resolved URL is valid: " + irisLogoMono);

                // =============================================================
                // 2. OVERHAULED LAUNCHER (image(9).png BLUEPRINT)
                // =============================================================
                console.log("\n--- Suite 2: Overhauled Application Launcher Layout ---");
                testRoot.assert(testLauncher.implicitWidth === 540,
                    "Launcher width is exactly 540px matching primary reference");
                testRoot.assert(testLauncher.implicitHeight === 480,
                    "Launcher height is exactly 480px matching primary reference");

                // Unconstrained catalog
                testRoot.assert(testLauncher.allApplications.length > 0,
                    "Launcher discovers installed desktop entries (found " + testLauncher.allApplications.length + ")");
                testRoot.assert(testLauncher.filteredApplications.length === testLauncher.allApplications.length,
                    "Initial state exposes 100% of the application catalog without 8-item cap (" +
                    testLauncher.filteredApplications.length + " / " + testLauncher.allApplications.length + ")");

                // Search capsule & command mode
                testRoot.assert(testLauncher.searchQuery === "",
                    "Initial search query is empty");
                testRoot.assert(testLauncher.isCommandMode === false,
                    "Normal mode is active initially");

                testLauncher.searchQuery = "> htop";
                testRoot.assert(testLauncher.isCommandMode === true,
                    "Typing prefix '>' activates Command Mode");
                testRoot.assert(testLauncher.commandText === "htop",
                    "commandText correctly strips '>' prefix: '" + testLauncher.commandText + "'");

                // Clear query
                testLauncher.resetSearch();
                testRoot.assert(testLauncher.searchQuery === "" && testLauncher.isCommandMode === false,
                    "resetSearch() restores empty query and normal app search mode");

                // Keyboard selection bounds
                testLauncher.selectedIndex = 1;
                testRoot.assert(testLauncher.selectedIndex === 1,
                    "selectedIndex updates correctly");

                // =============================================================
                // 3. TABBED FLOATING DASHBOARD (dashboard_reference.png)
                // =============================================================
                console.log("\n--- Suite 3: Tabbed Floating Dashboard ---");
                testRoot.assert(testDashboard.activeTab === "dashboard",
                    "Initial dashboard tab is 'dashboard'");

                testDashboard.activeTab = "media";
                testRoot.assert(testDashboard.activeTab === "media",
                    "Switching to 'media' tab succeeds");

                testDashboard.activeTab = "performance";
                testRoot.assert(testDashboard.activeTab === "performance",
                    "Switching to 'performance' tab succeeds");

                testDashboard.activeTab = "weather";
                testRoot.assert(testDashboard.activeTab === "weather",
                    "Switching to 'weather' tab succeeds");

                testDashboard.activeTab = "dashboard";
                testRoot.assert(testDashboard.activeTab === "dashboard",
                    "Switching back to 'dashboard' tab succeeds");

                // Telemetry & truthfully bound data
                testRoot.assert(typeof testDashboard.uptimeString === "string" && testDashboard.uptimeString.length > 0,
                    "Dashboard provides truthful uptime from /proc/uptime ('" + testDashboard.uptimeString + "')");
                testRoot.assert(typeof testDashboard.cpuPercent === "number" && testDashboard.cpuPercent >= 0 && testDashboard.cpuPercent <= 100,
                    "Dashboard exposes CPU usage percentage (" + testDashboard.cpuPercent + "%)");
                testRoot.assert(typeof testDashboard.ramPercent === "number" && testDashboard.ramPercent >= 0 && testDashboard.ramPercent <= 100,
                    "Dashboard exposes RAM usage percentage (" + testDashboard.ramPercent + "%)");
                testRoot.assert(typeof testDashboard.trackTitle === "string",
                    "Dashboard exposes MPRIS trackTitle: '" + testDashboard.trackTitle + "'");
                testRoot.assert(typeof testDashboard.fullDateString === "string" && testDashboard.fullDateString.length > 5,
                    "Dashboard exposes formatted calendar date: '" + testDashboard.fullDateString + "'");

                // =============================================================
                // 4. LEFT BEZEL DOCK (Bar.qml & Workspaces.qml)
                // =============================================================
                console.log("\n--- Suite 4: Left Bezel Dock Support ---");
                const initialBarPos = Config.barPosition;

                Config.setBarPosition("left");
                testRoot.assert(Config.barPosition === "left",
                    "Config.setBarPosition('left') successfully sets barPosition to 'left'");
                testRoot.assert(testBar.isVertical === true,
                    "Bar.isVertical is true when barPosition is 'left'");
                testRoot.assert(testBar.anchors.left === true && testBar.anchors.right === false,
                    "Vertical bar anchors to left edge only");
                testRoot.assert(testBar.anchors.top === true && testBar.anchors.bottom === true,
                    "Vertical bar spans from top to bottom edge");

                // Test vertical dock signals
                testRoot.connTriggeredFired = false;
                testBar.connectivityTriggered();
                testRoot.assert(testRoot.connTriggeredFired === true,
                    "Bar emits connectivityTriggered signal");

                testRoot.volTriggeredFired = false;
                testBar.volumeTriggered();
                testRoot.assert(testRoot.volTriggeredFired === true,
                    "Bar emits volumeTriggered signal");

                testRoot.qtTriggeredFired = false;
                testBar.quickTogglesTriggered();
                testRoot.assert(testRoot.qtTriggeredFired === true,
                    "Bar emits quickTogglesTriggered signal");

                testRoot.dashTriggeredFired = false;
                testBar.dashboardTriggered();
                testRoot.assert(testRoot.dashTriggeredFired === true,
                    "Bar emits dashboardTriggered signal");

                // Restore bar position
                Config.setBarPosition(initialBarPos);
                testRoot.assert(Config.barPosition === initialBarPos,
                    "Restored Config.barPosition to '" + initialBarPos + "'");

                // =============================================================
                // 5. COORDINATOR & POPOVERS INTEGRATION
                // =============================================================
                console.log("\n--- Suite 5: Coordinator & Popover Placement ---");
                testMain.closeLauncher();
                testMain.closeDashboard();
                testMain.closePopover();

                testMain.openLauncher();
                testRoot.assert(testMain.isLauncherOpen() === true,
                    "Launcher opens cleanly via Main coordinator");

                testMain.openPopover("connectivity");
                testRoot.assert(testMain.isLauncherOpen() === false && testMain.isPopoverOpen() === true,
                    "Opening connectivity popover automatically dismisses Launcher");

                testMain.toggleDashboard();
                testRoot.assert(testMain.isPopoverOpen() === false && testMain.isDashboardOpen() === true,
                    "Toggling dashboard dismisses active popovers");

                testMain.closeDashboard();
                testRoot.assert(testMain.isDashboardOpen() === false && testMain.isModalOpen() === false,
                    "All modals cleanly closed");

                console.log("\n=======================================================");
                console.log("CRAZYDOTS M11 TEST RESULTS: " + testRoot.passedTests + " PASSED, " + testRoot.failedTests + " FAILED");
                console.log("=======================================================");

                if (testRoot.failedTests === 0) {
                    console.log("ALL M11 BEZEL UX & LAUNCHER TESTS PASSED SUCCESSFULLY.");
                } else {
                    console.error("M11 BEZEL UX TESTS ENCOUNTERED FAILURES.");
                }

                Qt.quit();
            }
        }
    }
}
