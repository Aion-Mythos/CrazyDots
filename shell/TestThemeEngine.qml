import QtQuick
import Quickshell
import "."
import "services"

/**
 * TestThemeEngine.qml
 * Automated test harness for Milestone M1 (Design Tokens & Theme Engine).
 *
 * Verifies:
 * 1. Tokens.qml properties (spacing, radii, typography, durations, Bezier curves).
 * 2. Theme.qml semantic color tokens initialization with crazydots-default palette.
 * 3. Color manipulation functions: alpha(), lighten(), darken(), mix().
 * 4. Switching across built-in static themes.
 * 5. Parsing of Matugen JSON schema.
 * 6. ColorQuantizer dynamic fallback palette calculation.
 *
 * Exits with status 0 on success, or logs failures.
 */
ShellRoot {
    id: root

    property int testsPassed: 0
    property int testsFailed: 0

    function assert(condition: bool, description: string) {
        if (condition) {
            console.log("PASS:", description);
            testsPassed++;
        } else {
            console.error("FAIL:", description);
            testsFailed++;
        }
    }

    ThemeEngine {
        id: engine
        autoWatch: false // Disable file watch in test environment
    }

    Timer {
        id: testRunner
        interval: 50
        running: true
        repeat: false
        onTriggered: {
            console.log("=== CRAZYDOTS TEST SUITE: M1 THEME ENGINE ===");

            // -------------------------------------------------------------
            // Test 1: Tokens.qml verification
            // -------------------------------------------------------------
            root.assert(Tokens.spaceMd === 12, "Tokens.spaceMd is 12px");
            root.assert(Tokens.radiusMd === 12, "Tokens.radiusMd is 12px");
            root.assert(Tokens.fontBase === 14, "Tokens.fontBase is 14px");
            root.assert(Tokens.durationNormal === 280, "Tokens.durationNormal is 280ms");
            root.assert(Tokens.springCurve.length === 6, "Tokens.springCurve has 6 control points");
            root.assert(Tokens.exitCurve.length === 6, "Tokens.exitCurve has 6 control points");

            // -------------------------------------------------------------
            // Test 2: Default Theme initialization (crazydots-default)
            // -------------------------------------------------------------
            root.assert(Theme.activeThemeName === "crazydots-default", "Default theme is crazydots-default");
            root.assert(Theme.background.toString() === "#0d0e15", "Default background is #0d0e15");
            root.assert(Theme.accent.toString() === "#2ee6ca", "Default accent is #2ee6ca");
            root.assert(Theme.foreground.toString() === "#e6eaf8", "Default foreground is #e6eaf8");

            // -------------------------------------------------------------
            // Test 3: Color manipulation helpers
            // -------------------------------------------------------------
            const translucent = Theme.alpha(Theme.accent, 0.5);
            root.assert(Math.abs(translucent.a - 0.5) < 0.05, "Theme.alpha() calculates alpha 0.5");

            const darkened = Theme.darken(Theme.accent, 0.5);
            root.assert(darkened.r <= Theme.accent.r, "Theme.darken() reduces RGB values");

            const lightened = Theme.lighten(Theme.background, 0.5);
            root.assert(lightened.r >= Theme.background.r, "Theme.lighten() increases RGB values");

            const mixed = Theme.mix(Theme.background, Theme.foreground, 0.5);
            root.assert(mixed !== Theme.background && mixed !== Theme.foreground, "Theme.mix() blends two colors");

            // -------------------------------------------------------------
            // Test 4: Switching to built-in themes
            // -------------------------------------------------------------
            const switchedMocha = Theme.setTheme("catppuccin-mocha");
            root.assert(switchedMocha === true, "Theme.setTheme('catppuccin-mocha') returns true");
            root.assert(Theme.activeThemeName === "catppuccin-mocha", "Active theme is catppuccin-mocha");
            root.assert(Theme.background.toString() === "#1e1e2e", "Catppuccin background is #1e1e2e");
            root.assert(Theme.accent.toString() === "#89b4fa", "Catppuccin accent is #89b4fa");

            const switchedNord = Theme.setTheme("nord");
            root.assert(switchedNord === true, "Theme.setTheme('nord') returns true");
            root.assert(Theme.background.toString() === "#2e3440", "Nord background is #2e3440");
            root.assert(Theme.accent.toString() === "#88c0d0", "Nord accent is #88c0d0");

            // -------------------------------------------------------------
            // Test 5: Matugen JSON parser
            // -------------------------------------------------------------
            const matugenSample = JSON.stringify({
                colors: {
                    dark: {
                        background: "#101016",
                        surface: "#181822",
                        primary: "#a0e060",
                        secondary: "#60d0b0",
                        on_surface: "#f0f0f8",
                        outline: "#505060"
                    }
                }
            });
            const matugenLoaded = Theme.loadPaletteJson(matugenSample);
            root.assert(matugenLoaded === true, "Theme.loadPaletteJson() succeeds on Matugen JSON");
            root.assert(Theme.activeThemeName === "matugen", "Active theme is now matugen");
            root.assert(Theme.accent.toString() === "#a0e060", "Matugen primary mapped to accent (#a0e060)");
            root.assert(Theme.background.toString() === "#101016", "Matugen background mapped correctly");

            // -------------------------------------------------------------
            // Test 6: ColorQuantizer fallback algorithm
            // -------------------------------------------------------------
            const mockQuantizedColors = [
                Qt.rgba(0.2, 0.4, 0.8, 1.0), // vibrant blue
                Qt.rgba(0.8, 0.3, 0.2, 1.0), // reddish secondary
                Qt.rgba(0.1, 0.1, 0.2, 1.0)  // dark shade
            ];
            const quantizerLoaded = Theme.applyFromQuantizer(mockQuantizedColors);
            root.assert(quantizerLoaded === true, "Theme.applyFromQuantizer() succeeds with color list");
            root.assert(Theme.activeThemeName === "quantizer", "Active theme is now quantizer");
            root.assert(Theme.isDynamic === true, "Theme is marked as dynamic");

            // Return to default
            Theme.setTheme("crazydots-default");
            root.assert(Theme.activeThemeName === "crazydots-default", "Restored crazydots-default");

            // -------------------------------------------------------------
            // Summary and Exit
            // -------------------------------------------------------------
            console.log("==========================================");
            console.log("TESTS PASSED:", root.testsPassed);
            console.log("TESTS FAILED:", root.testsFailed);
            console.log("==========================================");

            if (root.testsFailed === 0) {
                console.log("ALL M1 THEME ENGINE TESTS PASSED SUCCESSFULLY.");
            } else {
                console.error("FAILURES DETECTED IN M1 THEME ENGINE.");
            }

            Qt.quit();
        }
    }
}
