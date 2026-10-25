import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Services.Pipewire
import Quickshell.Services.UPower
import Quickshell.Services.SystemTray
import "."
import "components"
import "panels"
import "panels/bar"

/**
 * TestBar.qml
 * Automated test harness for crazydots M4 Desktop Bar and sub-widgets.
 */
Item {
    id: testRoot
    width: 800
    height: 600

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

    // Mount Bar components for testing
    BarPill {
        id: testPill
        active: false
        Text {
            text: "Test"
        }
    }

    Workspaces {
        id: testWorkspaces
        screen: Quickshell.screens.length > 0 ? Quickshell.screens[0] : null
    }

    ActiveWindow {
        id: testActiveWindow
    }

    ClockWidget {
        id: testClock
    }

    AudioWidget {
        id: testAudio
    }

    BatteryWidget {
        id: testBattery
    }

    TrayWidget {
        id: testTray
    }

    // Full Bar instance
    Bar {
        id: testBar
        screen: Quickshell.screens.length > 0 ? Quickshell.screens[0] : null
    }

    Timer {
        id: testTimer
        interval: 600
        running: true
        repeat: false

        onTriggered: {
            console.log("=== CRAZYDOTS TEST SUITE: M4 DESKTOP BAR ===");

            // 1. BarPill Primitive Tests
            testRoot.assert(testPill.implicitHeight >= 28, "BarPill implicitHeight enforces minimum 28px");
            testRoot.assert(testPill.radius === Tokens.radiusSm, "BarPill radius matches Tokens.radiusSm");
            testRoot.assert(testPill.activeColor === Theme.accent, "BarPill activeColor binds to Theme.accent");
            testPill.active = true;
            testRoot.assert(testPill.active === true, "BarPill active property updates to true");
            testPill.active = false;

            // 2. Workspaces Widget Tests
            testRoot.assert(Array.isArray(testWorkspaces.visibleWorkspaces), "Workspaces returns an array of visible workspaces");
            let hasNegativeWs = false;
            for (let i = 0; i < testWorkspaces.visibleWorkspaces.length; i++) {
                if (testWorkspaces.visibleWorkspaces[i].id < 0) {
                    hasNegativeWs = true;
                    break;
                }
            }
            testRoot.assert(!hasNegativeWs, "Workspaces filters out negative ID special workspaces");

            // Verify ascending sorting
            let isSorted = true;
            for (let i = 1; i < testWorkspaces.visibleWorkspaces.length; i++) {
                if (testWorkspaces.visibleWorkspaces[i].id < testWorkspaces.visibleWorkspaces[i - 1].id) {
                    isSorted = false;
                    break;
                }
            }
            testRoot.assert(isSorted, "Workspaces are sorted in ascending numerical order");

            // 3. ActiveWindow Widget Tests
            testRoot.assert(typeof testActiveWindow.windowTitle === "string", "ActiveWindow exposes windowTitle string");
            testRoot.assert(testActiveWindow.maxTitleWidth === 380, "ActiveWindow default maxTitleWidth is 380px");
            testRoot.assert(testActiveWindow.implicitWidth <= testActiveWindow.maxTitleWidth, "ActiveWindow implicitWidth does not exceed maxTitleWidth");

            // 4. ClockWidget Tests
            testRoot.assert(testClock.timeString.length >= 4, "ClockWidget generates valid time string: " + testClock.timeString);
            testRoot.assert(testClock.dateString.length >= 4, "ClockWidget generates valid date string: " + testClock.dateString);
            testRoot.assert(testClock.timeString.indexOf(":") !== -1, "ClockWidget time string contains colon separator");

            // 5. AudioWidget Tests
            testRoot.assert(typeof testAudio.volume === "number", "AudioWidget volume is a number: " + testAudio.volume);
            testRoot.assert(typeof testAudio.isMuted === "boolean", "AudioWidget isMuted is a boolean");
            testRoot.assert(typeof testAudio.volumePercent === "number", "AudioWidget volumePercent is a number");
            testRoot.assert(testAudio.volumeIcon.length > 0, "AudioWidget provides non-empty volumeIcon glyph");

            // 6. BatteryWidget Tests
            testRoot.assert(typeof testBattery.isPresent === "boolean", "BatteryWidget exposes boolean isPresent");
            testRoot.assert(typeof testBattery.batteryPercent === "number", "BatteryWidget exposes number batteryPercent");
            testRoot.assert(testBattery.batteryIcon.length > 0, "BatteryWidget provides non-empty batteryIcon glyph");
            if (!testBattery.isPresent) {
                testRoot.assert(testBattery.implicitWidth === 0, "BatteryWidget collapses implicitWidth to 0 when not present");
            }

            // 7. TrayWidget Tests
            testRoot.assert(typeof testTray.itemCount === "number", "TrayWidget itemCount is a number: " + testTray.itemCount);
            testRoot.assert(testTray.visible === (testTray.itemCount > 0), "TrayWidget visibility synchronizes with itemCount");

            // 8. Bar PanelWindow Geometry & Anchoring Tests
            testRoot.assert(testBar.screen !== null, "Bar assigned to valid screen");
            testRoot.assert(testBar.anchors.top === (Config.barPosition === "top"), "Bar anchors.top matches Config.barPosition ('top')");
            testRoot.assert(testBar.anchors.left === true && testBar.anchors.right === true, "Bar anchors span left and right");

            const expectedHeight = Config.barHeight + (Config.barFloating ? Config.barMargin * 2 : 0);
            testRoot.assert(testBar.implicitHeight === expectedHeight, "Bar implicitHeight matches Config geometry (" + expectedHeight + "px)");
            testRoot.assert(testBar.WlrLayershell.exclusiveZone === expectedHeight, "Bar layer-shell exclusiveZone matches height (" + expectedHeight + "px)");
            testRoot.assert(testBar.WlrLayershell.layer === WlrLayer.Top, "Bar layer-shell is on WlrLayer.Top");

            // 9. Dynamic Config & Theme Responsiveness
            Config.setBarPosition("bottom");
            testRoot.assert(testBar.anchors.bottom === true, "Bar dynamically updates anchors.bottom when Config changes to 'bottom'");
            Config.setBarPosition("top");
            testRoot.assert(testBar.anchors.top === true, "Bar dynamically updates anchors.top when Config changes to 'top'");

            Theme.setTheme("nord");
            testRoot.assert(Theme.activeThemeName === "nord", "Bar theme switches to 'nord'");
            Theme.setTheme("crazydots-default");
            testRoot.assert(Theme.activeThemeName === "crazydots-default", "Bar theme restored to 'crazydots-default'");

            console.log("==========================================");
            console.log("TESTS PASSED:", testRoot.passedTests);
            console.log("TESTS FAILED:", testRoot.failedTests);
            console.log("==========================================");

            if (testRoot.failedTests === 0) {
                console.log("ALL M4 DESKTOP BAR TESTS PASSED SUCCESSFULLY.");
            } else {
                console.error("M4 DESKTOP BAR TESTS ENCOUNTERED FAILURES.");
            }

            Qt.quit();
        }
    }
}
