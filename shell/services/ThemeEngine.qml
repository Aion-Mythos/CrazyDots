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

    // Signals
    signal paletteLoaded(string source)
    signal extractionCompleted(int colorCount)

    // =========================================================================
    // FILE WATCHER FOR EXTERNAL / MATUGEN PALETTES
    // =========================================================================
    FileView {
        id: paletteView
        path: root.autoWatch ? root.palettePath : ""
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
                    root.extractionCompleted(quantizer.colors.length);
                    root.paletteLoaded("quantizer");
                }
            }
        }
    }

    // =========================================================================
    // PUBLIC CONTROL METHODS
    // =========================================================================

    /**
     * reloadFromFile(): Reads paletteView.text() and applies it to Theme.
     */
    function reloadFromFile(): bool {
        const text = paletteView.text();
        if (!text || text.trim().length === 0) {
            return false;
        }

        const success = Theme.loadPaletteJson(text);
        if (success) {
            root.paletteLoaded("file");
        }
        return success;
    }

    /**
     * extractFromWallpaper(path):
     * Runs Quickshell's native ColorQuantizer against an image file URL or path.
     */
    function extractFromWallpaper(path: string) {
        if (!path || path.length === 0) return;

        root.isExtracting = true;
        root.currentWallpaperPath = path;

        // Ensure URL scheme is present
        const urlStr = path.startsWith("file://") ? path : ("file://" + path);
        quantizer.source = urlStr;
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
