import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import "."
import "components"
import "panels"
import "services"

/**
 * TestWallpaper.qml
 * Automated test harness for crazydots M6 Wallpaper Manager & Dynamic Color Engine.
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

    // Instantiated WallpaperSurface for testing
    WallpaperSurface {
        id: testSurface
        screen: Quickshell.screens.length > 0 ? Quickshell.screens[0] : null
    }

    // Instantiated WallpaperManager for testing
    WallpaperManager {
        id: testManager
        active: true
    }

    // Instantiated ScreenCanvas for testing modal and focus states
    ScreenCanvas {
        id: testCanvas
        screen: Quickshell.screens.length > 0 ? Quickshell.screens[0] : null
        wallpaperManagerOpen: false
    }

    // Instantiated ThemeEngine for testing dynamic color extraction
    ThemeEngine {
        id: testEngine
    }

    property bool wallpaperAppliedFired: false
    property bool dynamicColorsFired: false
    property bool generationFailedFired: false
    property string lastAppliedPath: ""
    property string lastAppliedMode: ""

    Connections {
        target: testManager
        function onWallpaperApplied(path, mode) {
            testRoot.wallpaperAppliedFired = true;
            testRoot.lastAppliedPath = path;
            testRoot.lastAppliedMode = mode;
        }
        function onDynamicColorsExtracted(path) {
            testRoot.dynamicColorsFired = true;
        }
    }

    Connections {
        target: testEngine
        function onGenerationFailed(reason) {
            testRoot.generationFailedFired = true;
        }
    }

    Timer {
        id: testTimer
        interval: 600
        running: true
        repeat: false

        onTriggered: {
            console.log("=== CRAZYDOTS TEST SUITE: M6 WALLPAPER MANAGER & DYNAMIC COLOR ENGINE ===");

            // =================================================================
            // TEST SUITE 1: CONFIGURATION & PERSISTENCE DEFAULTS
            // =================================================================
            console.log("\n--- Suite 1: Wallpaper Configuration & Defaults ---");
            testRoot.assert(Config.wallpaperDirectory !== undefined && Config.wallpaperDirectory.length > 0,
                "Config.wallpaperDirectory is initialized to a valid directory path");

            const originalDir = Config.wallpaperDirectory;
            const assetsDir = Quickshell.env("HOME") + "/crazydots/assets/wallpapers";
            const dirUpdated = Config.setWallpaperDirectory(assetsDir);
            testRoot.assert(dirUpdated === true && Config.wallpaperDirectory === assetsDir,
                "Config.setWallpaperDirectory() successfully updates wallpaper directory path");

            const rejectEmptyDir = Config.setWallpaperDirectory("");
            testRoot.assert(rejectEmptyDir === false,
                "Config.setWallpaperDirectory() rejects empty directory path");

            // Restore directory
            Config.setWallpaperDirectory(originalDir);

            // Test setWallpaper and fill mode validation
            const testPath = assetsDir + "/crazydots-dark-mesh.svg";
            Config.setWallpaper(testPath, "fill");
            testRoot.assert(Config.wallpaperCurrent === testPath,
                "Config.setWallpaper() updates wallpaperCurrent path");
            testRoot.assert(Config.wallpaperMode === "fill",
                "Config.setWallpaper() sets fill mode to 'fill'");

            Config.setWallpaper(testPath, "fit");
            testRoot.assert(Config.wallpaperMode === "fit",
                "Config.setWallpaper() sets fill mode to 'fit'");

            Config.setWallpaper(testPath, "center");
            testRoot.assert(Config.wallpaperMode === "center",
                "Config.setWallpaper() sets fill mode to 'center'");

            Config.setWallpaper(testPath, "tile");
            testRoot.assert(Config.wallpaperMode === "tile",
                "Config.setWallpaper() sets fill mode to 'tile'");

            Config.setWallpaper(testPath, "invalid_mode");
            testRoot.assert(Config.wallpaperMode === "tile",
                "Config.setWallpaper() rejects invalid wallpaper mode and preserves previous mode");

            // =================================================================
            // TEST SUITE 2: WALLPAPER SURFACE LAYER & GEOMETRY
            // =================================================================
            console.log("\n--- Suite 2: WallpaperSurface Wayland Configuration ---");
            testRoot.assert(testSurface.WlrLayershell.layer === WlrLayer.Background,
                "WallpaperSurface is mounted on WlrLayer.Background");
            testRoot.assert(testSurface.WlrLayershell.exclusionMode === ExclusionMode.Ignore,
                "WallpaperSurface exclusionMode is ExclusionMode.Ignore");
            testRoot.assert(testSurface.WlrLayershell.keyboardFocus === WlrKeyboardFocus.None,
                "WallpaperSurface keyboardFocus is WlrKeyboardFocus.None");
            testRoot.assert(testSurface.anchors.top === true && testSurface.anchors.bottom === true &&
                            testSurface.anchors.left === true && testSurface.anchors.right === true,
                "WallpaperSurface anchors fill the designated screen geometry");

            testRoot.assert(testSurface.wallpaperSource.startsWith("file://"),
                "WallpaperSurface formats local file path with 'file://' URI scheme");

            // Test fillMode mapping
            Config.setWallpaper(testPath, "fit");
            testRoot.assert(testSurface.activeFillMode === Image.PreserveAspectFit,
                "activeFillMode maps 'fit' to Image.PreserveAspectFit");

            Config.setWallpaper(testPath, "center");
            testRoot.assert(testSurface.activeFillMode === Image.Pad,
                "activeFillMode maps 'center' to Image.Pad");

            Config.setWallpaper(testPath, "tile");
            testRoot.assert(testSurface.activeFillMode === Image.Tile,
                "activeFillMode maps 'tile' to Image.Tile");

            Config.setWallpaper(testPath, "fill");
            testRoot.assert(testSurface.activeFillMode === Image.PreserveAspectCrop,
                "activeFillMode maps 'fill' to Image.PreserveAspectCrop");

            testRoot.assert(testSurface.color === Theme.background,
                "WallpaperSurface fallback background color matches Theme.background");

            // =================================================================
            // TEST SUITE 3: WALLPAPER MANAGER DISCOVERY & FILTERING
            // =================================================================
            console.log("\n--- Suite 3: WallpaperManager Discovery & Filter ---");
            testRoot.assert(testManager.implicitWidth === 800 && testManager.implicitHeight === 580,
                "WallpaperManager has appropriate dialog dimensions (800x580)");

            testRoot.assert(testManager.discoveredWallpapers.length >= 3,
                "WallpaperManager discovered at least 3 bundled wallpapers in assets/wallpapers");

            // Test filename search filtering
            testManager.searchQuery = "glacier";
            testRoot.assert(testManager.filteredWallpapers.length === 1,
                "searchQuery 'glacier' filters to exactly 1 matching wallpaper");
            testRoot.assert(testManager.filteredWallpapers[0].name.indexOf("nord-glacier") !== -1,
                "Filtered result correctly matches 'crazydots-nord-glacier.svg'");

            testManager.searchQuery = "nonexistent_pattern_xyz";
            testRoot.assert(testManager.filteredWallpapers.length === 0,
                "searchQuery with non-matching pattern returns empty filtered list");

            testManager.searchQuery = "";
            testRoot.assert(testManager.filteredWallpapers.length === testManager.discoveredWallpapers.length,
                "Empty searchQuery returns all discovered wallpapers");

            // Test selection and apply
            testManager.selectedPath = testPath;
            testManager.selectedMode = "fit";
            testManager.applyCurrentSelection();
            testRoot.assert(testRoot.wallpaperAppliedFired === true,
                "applyCurrentSelection() emits wallpaperApplied signal");
            testRoot.assert(testRoot.lastAppliedPath === testPath && testRoot.lastAppliedMode === "fit",
                "wallpaperApplied signal carries correct path and mode payload");
            testRoot.assert(Config.wallpaperCurrent === testPath && Config.wallpaperMode === "fit",
                "applyCurrentSelection() updates Config.wallpaperCurrent and Config.wallpaperMode");

            // =================================================================
            // TEST SUITE 4: SCREENCANVAS MODAL INTEGRATION & INPUT MASK
            // =================================================================
            console.log("\n--- Suite 4: ScreenCanvas Modal & Focus Coordination ---");
            testRoot.assert(testCanvas.isWallpaperManagerActive === false,
                "isWallpaperManagerActive is false when wallpaperManagerOpen is false");
            testRoot.assert(testCanvas.WlrLayershell.keyboardFocus === WlrKeyboardFocus.None,
                "ScreenCanvas keyboardFocus is None when all modals are closed");

            testCanvas.wallpaperManagerOpen = true;
            testRoot.assert(testCanvas.isWallpaperManagerActive === true,
                "isWallpaperManagerActive is true when wallpaperManagerOpen is true");
            testRoot.assert(testCanvas.WlrLayershell.keyboardFocus === WlrKeyboardFocus.Exclusive,
                "ScreenCanvas keyboardFocus elevates to Exclusive when wallpaper manager opens");

            testCanvas.wallpaperManagerOpen = false;
            testRoot.assert(testCanvas.isWallpaperManagerActive === false,
                "isWallpaperManagerActive reverts to false when wallpaperManagerOpen is false");
            testRoot.assert(testCanvas.WlrLayershell.keyboardFocus === WlrKeyboardFocus.None,
                "ScreenCanvas keyboardFocus reverts to None when modal is closed");

            // =================================================================
            // TEST SUITE 5: THEME ENGINE DYNAMIC EXTRACTION & RESILIENCE
            // =================================================================
            console.log("\n--- Suite 5: ThemeEngine Dynamic Extraction & Resilience ---");
            testRoot.assert(typeof testEngine.hasMatugen === "boolean",
                "ThemeEngine.hasMatugen is probed as a boolean flag");

            testRoot.generationFailedFired = false;
            const emptyResult = testEngine.extractFromWallpaper("");
            testRoot.assert(emptyResult === false && testRoot.generationFailedFired === true,
                "ThemeEngine.extractFromWallpaper('') safely rejects empty path and fires generationFailed");

            const validExtract = testEngine.extractFromWallpaper(testPath);
            testRoot.assert(validExtract === true && testEngine.isExtracting === true,
                "ThemeEngine.extractFromWallpaper() initiates quantization on valid wallpaper");

            // Test malformed palette JSON rejection
            testEngine.lastKnownGoodPalette = "test-theme";
            const badJsonResult = testEngine.reloadFromFile(); // empty/missing file
            testRoot.assert(badJsonResult === false,
                "reloadFromFile() rejects empty/missing file without crashing shell");
            testRoot.assert(testEngine.lastKnownGoodPalette === "test-theme",
                "ThemeEngine preserves lastKnownGoodPalette when file is invalid");

            // =================================================================
            // SUMMARY
            // =================================================================
            console.log("\n=======================================================");
            console.log("CRAZYDOTS M6 TEST RESULTS: " + testRoot.passedTests + " PASSED, " + testRoot.failedTests + " FAILED");
            console.log("=======================================================\n");

            if (testRoot.failedTests === 0) {
                console.log("ALL M6 WALLPAPER MANAGER & DYNAMIC COLOR ENGINE TESTS PASSED.");
            } else {
                console.error("M6 WALLPAPER MANAGER TESTS ENCOUNTERED FAILURES.");
            }

            Qt.quit();
        }
    }
}
