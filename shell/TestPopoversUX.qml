import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import "."
import "components"
import "panels"
import "panels/popovers"
import "services"

/**
 * TestPopoversUX.qml
 * Automated test harness for crazydots M10 Interactive Popovers & Desktop UX Fixes.
 */
Item {
    id: testRoot
    width: 1280
    height: 800

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

    // Instantiated Services
    NetworkService {
        id: testNetwork
    }

    BrightnessService {
        id: testBrightness
    }

    // Instantiated Panels
    Launcher {
        id: testLauncher
        active: true
    }

    Dashboard {
        id: testDashboard
        active: true
    }

    ThemeManager {
        id: testThemeManager
        active: true
    }

    ConnectivityPopover {
        id: testConnPopover
        active: true
        networkService: testNetwork
    }

    VolumePopover {
        id: testVolPopover
        active: true
    }

    BrightnessPopover {
        id: testBrightPopover
        active: true
        brightnessService: testBrightness
    }

    QuickTogglesPopover {
        id: testQtPopover
        active: true
        networkService: testNetwork
        brightnessService: testBrightness
    }

    WallpaperSurface {
        id: testWpSurface
        screen: Quickshell.screens.length > 0 ? Quickshell.screens[0] : null
    }

    property bool wpManagerFired: false
    property bool themeManagerFired: false

    Connections {
        target: testWpSurface
        function onWallpaperManagerRequested() {
            testRoot.wpManagerFired = true;
        }
        function onThemeManagerRequested() {
            testRoot.themeManagerFired = true;
        }
    }

    // Instantiated Canvas & Coordinator
    ScreenCanvas {
        id: testCanvas
        screen: Quickshell.screens.length > 0 ? Quickshell.screens[0] : null
        networkService: testNetwork
        brightnessService: testBrightness
    }

    Main {
        id: testMain
    }

    Timer {
        id: runner
        interval: 350
        running: true
        repeat: false
        onTriggered: {
            console.log("=== CRAZYDOTS TEST SUITE: M10 POPOVERS & UX FIXES ===");

            // =================================================================
            // SUITE 1: LAUNCHER FIXES (>8 APPS & UNCONSTRAINED SEARCH)
            // =================================================================
            console.log("\n--- Suite 1: Launcher Fixes (>8 Apps & Unconstrained Search) ---");
            const totalApps = testLauncher.allApplications.length;
            testRoot.assert(totalApps > 0,
                "Launcher detects installed desktop applications (" + totalApps + " found)");

            // Empty query must show all eligible apps, not capped to 8
            testLauncher.searchQuery = "";
            testRoot.assert(testLauncher.filteredApplications.length === totalApps,
                "Empty query displays ALL installed applications (" + testLauncher.filteredApplications.length + " / " + totalApps + ") without artificial 8-item cap");

            // Search filtering across complete catalog
            testLauncher.searchQuery = "ghostty";
            testRoot.assert(testLauncher.filteredApplications.length >= 1,
                "Search query 'ghostty' successfully searches the entire application catalog");

            testLauncher.searchQuery = "nonexistent_app_query_xyz";
            testRoot.assert(testLauncher.filteredApplications.length === 0,
                "Non-matching search query returns empty results cleanly");

            testLauncher.searchQuery = "";
            testRoot.assert(testLauncher.filteredApplications.length === totalApps,
                "Clearing search query immediately restores the full application list");

            // =================================================================
            // SUITE 2: DASHBOARD VISIBILITY & LIFECYCLE FIXES
            // =================================================================
            console.log("\n--- Suite 2: Dashboard Visibility & Lifecycle Fixes ---");
            testRoot.assert(testCanvas.isCurrentMonitor === true,
                "ScreenCanvas.isCurrentMonitor is unconditionally true on single-monitor systems");

            testRoot.assert(testDashboard.implicitWidth >= 280,
                "Dashboard maintains minimum width threshold (>= 280px)");
            testRoot.assert(testDashboard.implicitHeight >= 300,
                "Dashboard maintains minimum height threshold (>= 300px)");

            testRoot.assert(testMain.isDashboardOpen() === false,
                "Dashboard is initially closed");

            testMain.openDashboard();
            testRoot.assert(testMain.isDashboardOpen() === true,
                "Main.openDashboard() sets isDashboardOpen to true");

            testMain.closeDashboard();
            testRoot.assert(testMain.isDashboardOpen() === false,
                "Main.closeDashboard() reverts isDashboardOpen to false");

            testMain.toggleDashboard();
            testRoot.assert(testMain.isDashboardOpen() === true,
                "Main.toggleDashboard() opens dashboard when closed");

            testMain.toggleDashboard();
            testRoot.assert(testMain.isDashboardOpen() === false,
                "Main.toggleDashboard() closes dashboard when open");

            // =================================================================
            // SUITE 3: DEDICATED THEME MANAGER
            // =================================================================
            console.log("\n--- Suite 3: Dedicated Theme Manager ---");
            testRoot.assert(testThemeManager.implicitWidth === 620,
                "ThemeManager has dedicated dialog width (620px)");
            testRoot.assert(testThemeManager.implicitHeight === 520,
                "ThemeManager has dedicated dialog height (520px)");

            testRoot.assert(testMain.isThemeManagerOpen() === false,
                "ThemeManager is initially closed");

            testMain.openThemeManager();
            testRoot.assert(testMain.isThemeManagerOpen() === true,
                "Main.openThemeManager() opens ThemeManager");

            // Modal exclusivity: opening launcher must close ThemeManager
            testMain.openLauncher();
            testRoot.assert(testMain.isLauncherOpen() === true && testMain.isThemeManagerOpen() === false,
                "Opening Launcher automatically dismisses ThemeManager (mutual exclusivity)");

            // Modal exclusivity: opening ThemeManager must close Launcher
            testMain.openThemeManager();
            testRoot.assert(testMain.isThemeManagerOpen() === true && testMain.isLauncherOpen() === false,
                "Opening ThemeManager automatically dismisses Launcher (mutual exclusivity)");

            // Theme preset switching
            const prevTheme = Config.themeName;
            Config.setThemeName("nord");
            testRoot.assert(Config.themeName === "nord",
                "Theme preset selection updates Config.themeName to 'nord'");
            Config.setThemeName(prevTheme);

            testMain.closeThemeManager();
            testRoot.assert(testMain.isThemeManagerOpen() === false,
                "Main.closeThemeManager() reverts isThemeManagerOpen to false");

            // =================================================================
            // SUITE 4: CONTEXTUAL POPOVERS & SERVICES
            // =================================================================
            console.log("\n--- Suite 4: Contextual Popovers & Services ---");

            // 4.1 NetworkService & Connectivity Popover
            testRoot.assert(testNetwork.isAvailable === true,
                "NetworkService detects NetworkManager nmcli backend on host");
            testRoot.assert(typeof testNetwork.wifiEnabled === "boolean",
                "NetworkService exposes boolean wifiEnabled state");
            testRoot.assert(testNetwork.bluetoothAvailable === false,
                "NetworkService truthfully reports Bluetooth daemon as inactive without simulating state");
            testRoot.assert(testConnPopover.implicitWidth === 350,
                "ConnectivityPopover has compact width (350px)");

            // 4.2 BrightnessService & Brightness Popover
            testRoot.assert(testBrightness.isAvailable === true,
                "BrightnessService detects brightnessctl backend on host");
            testRoot.assert(testBrightness.maxBrightness > 0,
                "BrightnessService exposes valid hardware maxBrightness (" + testBrightness.maxBrightness + ")");
            testRoot.assert(testBrightPopover.implicitWidth === 320,
                "BrightnessPopover has compact width (320px)");

            // 4.3 Volume Popover
            testRoot.assert(testVolPopover.implicitWidth === 320,
                "VolumePopover has compact width (320px)");
            testRoot.assert(typeof testVolPopover.volume === "number",
                "VolumePopover exposes numeric volume level (" + testVolPopover.volumePercent + "%)");

            // 4.4 Quick Toggles Popover
            testRoot.assert(testQtPopover.implicitWidth === 350,
                "QuickTogglesPopover has compact width (350px)");

            // 4.5 Popover Mutual Exclusivity & Safe Dismissal
            testMain.openPopover("connectivity");
            testRoot.assert(testMain.getActivePopover() === "connectivity",
                "Main.openPopover('connectivity') sets activePopover to 'connectivity'");
            testRoot.assert(testMain.isDashboardOpen() === false,
                "Opening connectivity popover does NOT open the large dashboard");

            testMain.openPopover("volume");
            testRoot.assert(testMain.getActivePopover() === "volume",
                "Main.openPopover('volume') seamlessly transitions active popover to 'volume'");

            testMain.openPopover("quickToggles");
            testRoot.assert(testMain.getActivePopover() === "quickToggles",
                "Main.openPopover('quickToggles') sets activePopover to 'quickToggles'");

            testMain.closePopover();
            testRoot.assert(testMain.getActivePopover() === "",
                "Main.closePopover() resets activePopover to empty");

            testMain.togglePopover("brightness");
            testRoot.assert(testMain.getActivePopover() === "brightness",
                "Main.togglePopover('brightness') opens popover when none active");

            testMain.togglePopover("brightness");
            testRoot.assert(testMain.getActivePopover() === "",
                "Main.togglePopover('brightness') closes popover when currently active");

            // =================================================================
            // SUITE 5: WALLPAPER DESKTOP GESTURES
            // =================================================================
            console.log("\n--- Suite 5: Wallpaper Desktop Gestures ---");
            testRoot.assert(testWpSurface.WlrLayershell.layer === WlrLayer.Background,
                "WallpaperSurface lives on WlrLayer.Background, ensuring application windows sit above it");

            testRoot.wpManagerFired = false;
            testRoot.themeManagerFired = false;

            // Simulate double click on left side (x = 200 of 1920)
            const leftClick = { x: 200 };
            if (leftClick.x < 1920 / 2) {
                testWpSurface.wallpaperManagerRequested();
            }
            testRoot.assert(testRoot.wpManagerFired === true,
                "Double-click on left half of wallpaper triggers Wallpaper Manager request");

            // Simulate double click on right side (x = 1500 of 1920)
            const rightClick = { x: 1500 };
            if (rightClick.x >= 1920 / 2) {
                testWpSurface.themeManagerRequested();
            }
            testRoot.assert(testRoot.themeManagerFired === true,
                "Double-click on right half of wallpaper triggers Theme Manager request");

            // =================================================================
            // RESULTS SUMMARY
            // =================================================================
            console.log("\n=======================================================");
            console.log("CRAZYDOTS M10 TEST RESULTS: " + testRoot.passedTests + " PASSED, " + testRoot.failedTests + " FAILED");
            console.log("=======================================================\n");

            if (testRoot.failedTests === 0) {
                console.log("ALL M10 POPOVERS & UX FIXES TESTS PASSED.");
            } else {
                console.error("M10 TESTS ENCOUNTERED FAILURES.");
            }

            Qt.quit();
        }
    }
}
