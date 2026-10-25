import QtQuick
import Quickshell
import Quickshell.Io
import ".."

/**
 * ThemeEngine.qml
 * Headless subsystem coordinating dynamic themes, Matugen JSON palettes,
 * and native ColorQuantizer wallpaper extraction.
 *
 * Responsibilities:
 * - Watches external palette files (e.g. ~/.config/crazydots/palette.json)
 *   written by Matugen or external scripts, and pushes changes into Theme.
 * - Provides native in-shell color quantization via Quickshell's ColorQuantizer
 *   as a zero-dependency fallback when Matugen is unavailable.
 * - Detects presence of Matugen binary without executing arbitrary strings.
 * - Validates generated palette data and preserves last known-good theme on failures.
 * - Handles missing files and parse errors safely without crashing the shell.
 */
Item {
    id: root

    // =========================================================================
    // PUBLIC CONFIGURATION & STATE
    // =========================================================================
    property string palettePath: Quickshell.env("HOME") + "/.config/crazydots/palette.json"
    property bool autoWatch: true
    property string currentWallpaperPath: ""
    property bool isExtracting: false
    property bool hasMatugen: false
    property string lastKnownGoodPalette: ""

    // Signals
    signal paletteLoaded(string source)
    signal extractionCompleted(int colorCount)
    signal generationFailed(string reason)

    // =========================================================================
    // MATUGEN AVAILABILITY PROBE
    // =========================================================================
    Process {
        id: matugenProbe
        command: ["which", "matugen"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                const out = (text || "").trim();
                root.hasMatugen = out.length > 0 && out.indexOf("matugen") !== -1;
            }
        }
    }

    // =========================================================================
    // FILE WATCHER FOR EXTERNAL / MATUGEN PALETTES
    // =========================================================================
    FileView {
        id: paletteView
        path: root.autoWatch ? root.palettePath : ""
        atomicWrites: true
        printErrors: false

        onFileChanged: {
            root.reloadFromFile();
        }
    }

    // =========================================================================
    // NATIVE COLOR QUANTIZER (FALLBACK & IN-SHELL ENGINE)
    // =========================================================================
    ColorQuantizer {
        id: quantizer
        depth: 3 // 2^3 = 8 dominant colors

        onColorsChanged: {
            if (quantizer.colors.length > 0) {
                const success = Theme.applyFromQuantizer(quantizer.colors);
                root.isExtracting = false;
                if (success) {
                    root.lastKnownGoodPalette = "quantizer:" + quantizer.colors.join(",");
                    root.extractionCompleted(quantizer.colors.length);
                    root.paletteLoaded("quantizer");
                } else {
                    root.generationFailed("ColorQuantizer synthesis failed");
                }
            }
        }
    }

    // =========================================================================
    // PUBLIC CONTROL METHODS
    // =========================================================================

    /**
     * reloadFromFile(): Reads paletteView.text() and applies it to Theme.
     * Preserves last known good palette if file contains malformed data.
     */
    function reloadFromFile(): bool {
        const text = paletteView.text();
        if (!text || text.trim().length === 0) {
            return false;
        }

        // Validate JSON structure before loading
        try {
            JSON.parse(text);
        } catch (e) {
            console.warn("crazydots: Rejecting malformed palette JSON, preserving last known-good theme.");
            root.generationFailed("Malformed palette JSON");
            return false;
        }

        const success = Theme.loadPaletteJson(text);
        if (success) {
            root.lastKnownGoodPalette = text;
            root.paletteLoaded("file");
        } else {
            root.generationFailed("Failed to map palette tokens");
        }
        return success;
    }

    /**
     * extractFromWallpaper(path):
     * Runs Quickshell's native ColorQuantizer against an image file URL or path.
     * Fallback is active when Matugen is not installed.
     */
    function extractFromWallpaper(path: string): bool {
        if (!path || path.trim().length === 0) {
            root.generationFailed("Empty wallpaper path");
            return false;
        }

        root.isExtracting = true;
        root.currentWallpaperPath = path;

        // Ensure URL scheme is present
        const urlStr = path.startsWith("file://") ? path : ("file://" + path);
        quantizer.source = urlStr;
        return true;
    }

    /**
     * setBuiltinTheme(name):
     * Switches to one of the built-in static themes.
     */
    function setBuiltinTheme(name: string): bool {
        return Theme.setTheme(name);
    }

    Component.onCompleted: {
        // Attempt initial load from palette file; fall back to default theme if not present
        if (!reloadFromFile()) {
            Theme.setTheme("crazydots-default");
        }
    }
}
