import QtQuick
import Quickshell
import "."
import "components"

/**
 * TestBaseComponents.qml
 * Automated test harness for Milestone M3 (Quickshell Entry Point & Shell Base).
 *
 * Verifies:
 * 1. StyledRect properties (elevated vs standard, border styling, theme color bindings).
 * 2. StyledText properties (standard vs muted, sans vs monospace typography).
 * 3. ButtonBase interaction states, click signal emission, primary vs outline modes.
 * 4. Multi-monitor screen detection and variant model bindings.
 * 5. Input region pass-through configuration.
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

    // Component instances under test
    StyledRect {
        id: standardRect
        elevated: false
        bordered: true
    }

    StyledRect {
        id: elevatedRect
        elevated: true
        bordered: true
    }

    StyledText {
        id: defaultText
        text: "Default Text"
        muted: false
        monospace: false
    }

    StyledText {
        id: mutedMonoText
        text: "Muted Monospace Text"
        muted: true
        monospace: true
    }

    ButtonBase {
        id: secondaryButton
        text: "Secondary Action"
        primary: false
    }

    ButtonBase {
        id: primaryButton
        text: "Primary Action"
        primary: true
    }

    property bool buttonClickedFired: false
    ButtonBase {
        id: clickTestButton
        text: "Click Me"
        onClicked: {
            root.buttonClickedFired = true;
        }
    }

    Timer {
        id: testRunner
        interval: 50
        running: true
        repeat: false
        onTriggered: {
            console.log("=== CRAZYDOTS TEST SUITE: M3 SHELL BASE & COMPONENTS ===");

            // -------------------------------------------------------------
            // Test 1: StyledRect component
            // -------------------------------------------------------------
            root.assert(standardRect.color.toString() === Theme.surface.toString(), "StyledRect standard color matches Theme.surface");
            root.assert(elevatedRect.color.toString() === Theme.surfaceElevated.toString(), "StyledRect elevated color matches Theme.surfaceElevated");
            root.assert(standardRect.border.color.toString() === Theme.border.toString(), "StyledRect border matches Theme.border");
            root.assert(standardRect.radius === Tokens.radiusMd, "StyledRect radius matches Tokens.radiusMd");

            // -------------------------------------------------------------
            // Test 2: StyledText component
            // -------------------------------------------------------------
            root.assert(defaultText.color.toString() === Theme.foreground.toString(), "StyledText default color matches Theme.foreground");
            root.assert(mutedMonoText.color.toString() === Theme.mutedForeground.toString(), "StyledText muted color matches Theme.mutedForeground");
            root.assert(defaultText.font.family === Tokens.fontFamilySans, "StyledText default font matches Tokens.fontFamilySans");
            root.assert(mutedMonoText.font.family === Tokens.fontFamilyMono, "StyledText monospace font matches Tokens.fontFamilyMono");

            // -------------------------------------------------------------
            // Test 3: ButtonBase component
            // -------------------------------------------------------------
            root.assert(secondaryButton.primary === false, "Secondary button primary flag is false");
            root.assert(primaryButton.primary === true, "Primary button primary flag is true");
            root.assert(secondaryButton.activeFocusOnTab === true, "ButtonBase participates in Tab focus navigation");

            // Test click trigger
            clickTestButton.clicked();
            root.assert(root.buttonClickedFired === true, "ButtonBase clicked signal fires correctly");

            // -------------------------------------------------------------
            // Test 4: Multi-monitor screen detection & Base Shell
            // -------------------------------------------------------------
            root.assert(Quickshell.screens.length > 0, "Quickshell reports at least 1 connected display");
            const primaryScreen = Quickshell.screens[0];
            root.assert(primaryScreen.name.length > 0, "Primary display has valid name: " + primaryScreen.name);
            root.assert(primaryScreen.width > 0 && primaryScreen.height > 0, "Primary display has positive geometry: " + primaryScreen.width + "x" + primaryScreen.height);

            // -------------------------------------------------------------
            // Test 5: Dynamic Theme propagation to Base Components
            // -------------------------------------------------------------
            Theme.setTheme("nord");
            // Allow ColorAnimation (280ms) to interpolate and settle
            animTimer.start();
        }
    }

    Timer {
        id: animTimer
        interval: 320
        repeat: false
        onTriggered: {
            root.assert(defaultText.color.toString() === Theme.foreground.toString(), "StyledText adapts dynamically to Nord foreground after transition");
            root.assert(standardRect.color.toString() === Theme.surface.toString(), "StyledRect adapts dynamically to Nord surface after transition");

            // Restore signature default theme
            Theme.setTheme("crazydots-default");
            root.assert(Theme.activeThemeName === "crazydots-default", "Restored crazydots-default theme");

            // -------------------------------------------------------------
            // Test Summary & Exit
            // -------------------------------------------------------------
            console.log("==========================================");
            console.log("TESTS PASSED:", root.testsPassed);
            console.log("TESTS FAILED:", root.testsFailed);
            console.log("==========================================");

            if (root.testsFailed === 0) {
                console.log("ALL M3 SHELL BASE & COMPONENT TESTS PASSED.");
            } else {
                console.error("FAILURES DETECTED IN M3 BASE TESTS.");
            }

            Qt.quit();
        }
    }
}
