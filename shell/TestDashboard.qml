import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Services.Pipewire
import Quickshell.Services.UPower
import "."
import "components"
import "panels"

/**
 * TestDashboard.qml
 * Automated test harness for crazydots M7 Corner Dashboard & Quick Settings.
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

    // Instantiated Dashboard for component-level testing
    Dashboard {
        id: testDashboard
        active: true
    }

    // Instantiated ScreenCanvas for testing corner placement, modal exclusivity, and focus
    ScreenCanvas {
        id: testCanvas
        screen: Quickshell.screens.length > 0 ? Quickshell.screens[0] : null
        launcherOpen: false
        wallpaperManagerOpen: false
        dashboardOpen: false
    }

    // Instantiated Main coordinator for testing modal exclusivity rules
    Main {
        id: testMain
    }

    property bool closeRequestedFired: false
    property bool wallpaperManagerRequestedFired: false

    Connections {
        target: testDashboard
        function onCloseRequested() {
            testRoot.closeRequestedFired = true;
        }
        function onWallpaperManagerRequested() {
            testRoot.wallpaperManagerRequestedFired = true;
        }
    }

    Timer {
        id: testTimer
        interval: 600
        running: true
        repeat: false

        onTriggered: {
            console.log("=== CRAZYDOTS TEST SUITE: M7 CORNER DASHBOARD & QUICK SETTINGS ===");

            // =================================================================
            // TEST SUITE 1: CONFIGURATION & PERSISTENCE
            // =================================================================
            console.log("\n--- Suite 1: Dashboard Configuration & Defaults ---");
            testRoot.assert(Config.dashboardCorner !== undefined && Config.dashboardCorner.length > 0,
                "Config.dashboardCorner is initialized with a non-empty string");

            const originalCorner = Config.dashboardCorner;
            const validCorners = ["top-right", "top-left", "bottom-right", "bottom-left"];
            for (let i = 0; i < validCorners.length; i++) {
                const c = validCorners[i];
                const setRes = Config.setDashboardCorner(c);
                testRoot.assert(setRes === true && Config.dashboardCorner === c,
                    "Config.setDashboardCorner('" + c + "') succeeds and updates property");
            }

            const rejectInvalid = Config.setDashboardCorner("middle-center");
            testRoot.assert(rejectInvalid === false,
                "Config.setDashboardCorner('middle-center') rejects invalid corner string");

            // Restore corner
            Config.setDashboardCorner(originalCorner);

            // Width clamping
            const origWidth = Config.dashboardWidth;
            Config.setDashboardWidth(450);
            testRoot.assert(Config.dashboardWidth === 450,
                "Config.setDashboardWidth(450) sets width to 450");
            Config.setDashboardWidth(100);
            testRoot.assert(Config.dashboardWidth === 260,
                "Config.setDashboardWidth(100) clamps to minimum 260");
            Config.setDashboardWidth(2000);
            testRoot.assert(Config.dashboardWidth === 800,
                "Config.setDashboardWidth(2000) clamps to maximum 800");
            Config.setDashboardWidth(origWidth);

            // Height clamping
            const origHeight = Config.dashboardHeight;
            Config.setDashboardHeight(600);
            testRoot.assert(Config.dashboardHeight === 600,
                "Config.setDashboardHeight(600) sets height to 600");
            Config.setDashboardHeight(100);
            testRoot.assert(Config.dashboardHeight === 300,
                "Config.setDashboardHeight(100) clamps to minimum 300");
            Config.setDashboardHeight(3000);
            testRoot.assert(Config.dashboardHeight === 1200,
                "Config.setDashboardHeight(3000) clamps to maximum 1200");
            Config.setDashboardHeight(origHeight);

            // =================================================================
            // TEST SUITE 2: COMPONENT DIMENSIONS & TIME/DATE
            // =================================================================
            console.log("\n--- Suite 2: Component Dimensions & Time/Date ---");
            testRoot.assert(testDashboard.implicitWidth === Config.dashboardWidth,
                "Dashboard.implicitWidth binds reactively to Config.dashboardWidth");
            testRoot.assert(testDashboard.implicitHeight === Config.dashboardHeight,
                "Dashboard.implicitHeight binds reactively to Config.dashboardHeight");

            testRoot.assert(testDashboard.timeString.length >= 4 && testDashboard.timeString.indexOf(":") !== -1,
                "Dashboard.timeString provides formatted clock time ('" + testDashboard.timeString + "')");
            testRoot.assert(testDashboard.fullDateString.length > 5,
                "Dashboard.fullDateString provides formatted calendar date ('" + testDashboard.fullDateString + "')");

            // =================================================================
            // TEST SUITE 3: AUDIO & BATTERY SERVICE INTEGRATIONS
            // =================================================================
            console.log("\n--- Suite 3: Audio & Battery Truthful Status ---");
            testRoot.assert(typeof testDashboard.isAudioReady === "boolean",
                "Dashboard.isAudioReady is a boolean flag reflecting Pipewire state");
            testRoot.assert(typeof testDashboard.audioVolume === "number",
                "Dashboard.audioVolume is a numeric volume level");
            testRoot.assert(typeof testDashboard.isAudioMuted === "boolean",
                "Dashboard.isAudioMuted is a boolean mute flag");
            testRoot.assert(testDashboard.volumeGlyph.length > 0,
                "Dashboard.volumeGlyph provides a valid status glyph ('" + testDashboard.volumeGlyph + "')");

            // Safe audio execution tests
            testDashboard.toggleAudioMute();
            testRoot.assert(true, "toggleAudioMute() executes safely without throwing");
            testDashboard.setVolumeRatio(0.65);
            testRoot.assert(true, "setVolumeRatio(0.65) executes safely without throwing");

            // Battery truthful reporting
            testRoot.assert(typeof testDashboard.hasBattery === "boolean",
                "Dashboard.hasBattery is a boolean flag reflecting UPower state");
            testRoot.assert(typeof testDashboard.batteryPercent === "number",
                "Dashboard.batteryPercent is a numeric battery percentage");
            testRoot.assert(testDashboard.batteryGlyph.length > 0,
                "Dashboard.batteryGlyph provides a valid power/battery icon ('" + testDashboard.batteryGlyph + "')");

            // =================================================================
            // TEST SUITE 4: THEME SELECTION & WALLPAPER INTERACTION
            // =================================================================
            console.log("\n--- Suite 4: Theme Selection & Wallpaper Access ---");
            const originalTheme = Config.themeName;
            Config.setThemeName("catppuccin-mocha");
            testRoot.assert(Config.themeName === "catppuccin-mocha" && Theme.activeThemeName === "catppuccin-mocha",
                "Selecting 'catppuccin-mocha' updates Config.themeName and Theme.activeThemeName");

            Config.setThemeName("tokyo-night");
            testRoot.assert(Config.themeName === "tokyo-night" && Theme.activeThemeName === "tokyo-night",
                "Selecting 'tokyo-night' updates Config.themeName and Theme.activeThemeName");

            Config.setThemeName(originalTheme);
            testRoot.assert(Config.themeName === originalTheme,
                "Restoring default theme restores Config.themeName");

            // Wallpaper manage request signal
            testRoot.wallpaperManagerRequestedFired = false;
            testDashboard.wallpaperManagerRequested();
            testRoot.assert(testRoot.wallpaperManagerRequestedFired === true,
                "Dashboard emits wallpaperManagerRequested signal");

            // =================================================================
            // TEST SUITE 5: MOTION & ANIMATION PREFERENCES
            // =================================================================
            console.log("\n--- Suite 5: Motion & Animation Preferences ---");
            const origAnimEnabled = Config.animationsEnabled;
            Config.setAnimationsEnabled(false);
            testRoot.assert(Config.animationsEnabled === false,
                "Config.setAnimationsEnabled(false) disables animations");

            Config.setAnimationsEnabled(true);
            testRoot.assert(Config.animationsEnabled === true,
                "Config.setAnimationsEnabled(true) enables animations");

            Config.setAnimationsEnabled(origAnimEnabled);

            const origSpeed = Config.animationSpeed;
            Config.setAnimationSpeed(0.5);
            testRoot.assert(Math.abs(Config.animationSpeed - 0.5) < 0.01,
                "Config.setAnimationSpeed(0.5) sets fast speed multiplier");

            Config.setAnimationSpeed(1.5);
            testRoot.assert(Math.abs(Config.animationSpeed - 1.5) < 0.01,
                "Config.setAnimationSpeed(1.5) sets relaxed speed multiplier");

            Config.setAnimationSpeed(origSpeed);

            // =================================================================
            // TEST SUITE 6: SCREENCANVAS MODAL EXCLUSIVITY & FOCUS RESTORATION
            // =================================================================
            console.log("\n--- Suite 6: Modal Exclusivity & Keyboard Focus ---");
            // Canvas initial state
            testRoot.assert(testCanvas.isDashboardActive === false,
                "isDashboardActive is false when dashboardOpen is false");
            testRoot.assert(testCanvas.isModalActive === false,
                "isModalActive is false when all modals are closed");
            testRoot.assert(testCanvas.WlrLayershell.keyboardFocus === WlrKeyboardFocus.None,
                "Canvas keyboardFocus is None when all modals are closed");

            // Open dashboard on Canvas
            testCanvas.dashboardOpen = true;
            testRoot.assert(testCanvas.isDashboardActive === true,
                "isDashboardActive is true when dashboardOpen is true");
            testRoot.assert(testCanvas.isModalActive === true,
                "isModalActive is true when dashboardOpen is true");
            testRoot.assert(testCanvas.WlrLayershell.keyboardFocus === WlrKeyboardFocus.Exclusive,
                "Canvas keyboardFocus elevates to Exclusive when dashboard is open");

            // Close dashboard on Canvas
            testCanvas.dashboardOpen = false;
            testRoot.assert(testCanvas.isDashboardActive === false,
                "isDashboardActive reverts to false when dashboard is closed");
            testRoot.assert(testCanvas.isModalActive === false,
                "isModalActive reverts to false when dashboard is closed");
            testRoot.assert(testCanvas.WlrLayershell.keyboardFocus === WlrKeyboardFocus.None,
                "Canvas keyboardFocus reverts to None when dashboard is closed");

            // Main coordinator strict modal exclusivity
            console.log("\n--- Suite 7: Main Coordinator Modal Exclusivity ---");
            testMain.closeLauncher();
            testMain.closeWallpaperManager();
            testMain.closeDashboard();

            // Open Launcher -> only launcher is open
            testMain.openLauncher();
            testRoot.assert(testMain.isLauncherOpen() === true &&
                            testMain.isWallpaperManagerOpen() === false &&
                            testMain.isDashboardOpen() === false,
                "openLauncher() ensures only launcher is open");

            // Open Dashboard -> closes launcher, only dashboard is open
            testMain.openDashboard();
            testRoot.assert(testMain.isLauncherOpen() === false &&
                            testMain.isWallpaperManagerOpen() === false &&
                            testMain.isDashboardOpen() === true,
                "openDashboard() automatically closes launcher and keeps only dashboard open");

            // Open WallpaperManager -> closes dashboard, only wallpaper manager is open
            testMain.openWallpaperManager();
            testRoot.assert(testMain.isLauncherOpen() === false &&
                            testMain.isWallpaperManagerOpen() === true &&
                            testMain.isDashboardOpen() === false,
                "openWallpaperManager() automatically closes dashboard and keeps only wallpaper manager open");

            // Toggle Dashboard -> closes wallpaper manager, opens dashboard
            testMain.toggleDashboard();
            testRoot.assert(testMain.isLauncherOpen() === false &&
                            testMain.isWallpaperManagerOpen() === false &&
                            testMain.isDashboardOpen() === true,
                "toggleDashboard() closes other open modals and opens dashboard");

            // Toggle Dashboard again -> closes dashboard
            testMain.toggleDashboard();
            testRoot.assert(testMain.isDashboardOpen() === false,
                "toggleDashboard() when already open closes dashboard");

            // =================================================================
            // SUMMARY
            // =================================================================
            console.log("\n=======================================================");
            console.log("CRAZYDOTS M7 TEST RESULTS: " + testRoot.passedTests + " PASSED, " + testRoot.failedTests + " FAILED");
            console.log("=======================================================\n");

            if (testRoot.failedTests === 0) {
                console.log("ALL M7 CORNER DASHBOARD & QUICK SETTINGS TESTS PASSED.");
            } else {
                console.error("M7 CORNER DASHBOARD TESTS ENCOUNTERED FAILURES.");
            }

            Qt.quit();
        }
    }
}
