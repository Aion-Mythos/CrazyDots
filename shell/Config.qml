pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import "."

/**
 * Config.qml
 * Centralized configuration & persistence service for crazydots.
 *
 * Responsibilities:
 * - Manages persistent user preferences in ~/.config/crazydots/config.json.
 * - Provides sensible defaults and strict type validation for all settings.
 * - Gracefully handles missing files, malformed JSON, and unexpected types without crashing.
 * - Performs debounced, atomic disk writes to prevent file corruption and I/O spamming.
 * - Decouples persistent user preferences from dynamic wallpaper color palettes.
 *
 * All settings are exposed as granular, reactive QML properties to ensure optimal
 * property binding evaluation across UI components.
 */
QtObject {
    id: root

    // =========================================================================
    // CONFIGURATION FILE PATH & OPERATIONAL STATE
    // =========================================================================
    property string configPath: Quickshell.env("HOME") + "/.config/crazydots/config.json"
    property bool isLoaded: false
    property bool isSaving: false
    property bool hasSaveError: false
    property string lastSaveError: ""
    property var lastLoadedTime: null

    // Signals
    signal loaded(string path)
    signal saved(string path)
    signal saveFailed(string error)
    signal validationWarning(string field, string reason)
    signal configChanged()

    // =========================================================================
    // 1. DESKTOP BAR PREFERENCES
    // =========================================================================
    property string barPosition: "top"          // "top", "bottom", or "left"
    property int barHeight: 44                  // 24 to 120 pixels
    property bool barFloating: true             // Floating island bar vs docked edge
    property int barMargin: 8                   // 0 to 64 pixels edge margin
    property bool barShowWorkspaces: true       // Show Hyprland workspace indicator
    property bool barShowTitle: true            // Show active window title
    property bool barShowTray: true             // Show system tray (StatusNotifierItem)
    property bool barShowClock: true            // Show digital clock
    property bool barShowBattery: true          // Show battery percentage/status
    property bool barShowAudio: true            // Show volume control widget

    // =========================================================================
    // 2. THEME & VISUAL PREFERENCES
    // =========================================================================
    property string themeName: "crazydots-default" // Built-in name or "matugen" / "quantizer"
    property string themeMode: "dark"              // "dark" or "light"
    property real themeOpacity: 0.90               // 0.1 to 1.0 base panel opacity
    property bool themeBlur: true                  // Hyprland compositor blur enabled

    // =========================================================================
    // 3. WALLPAPER PREFERENCES
    // =========================================================================
    property string wallpaperCurrent: ""           // Path to active wallpaper image
    property string wallpaperMode: "fill"          // "fill", "fit", "center", "tile"
    property string wallpaperDirectory: Quickshell.env("HOME") + "/Pictures/Wallpapers" // Wallpaper folder

    // =========================================================================
    // 4. ANIMATION PREFERENCES
    // =========================================================================
    property bool animationsEnabled: true          // Reduced motion toggle
    property real animationSpeed: 1.0              // 0.1 to 3.0 scale multiplier

    // =========================================================================
    // 5. APPLICATION LAUNCHER PREFERENCES
    // =========================================================================
    property string launcherShortcut: "SUPER"      // Hotkey display hint
    property int launcherMaxResults: 8             // 1 to 30 items
    property int launcherItemHeight: 52            // 36 to 96 pixels

    // =========================================================================
    // 6. CORNER DASHBOARD PREFERENCES
    // =========================================================================
    property string dashboardCorner: "top-right"   // "top-right", "top-left", "bottom-right", "bottom-left"
    property int dashboardWidth: 380               // 260 to 800 pixels
    property int dashboardHeight: 520              // 300 to 1200 pixels

    // =========================================================================
    // 7. TERMINAL INTEGRATION (GHOSTTY)
    // =========================================================================
    property string terminalCommand: "ghostty"            // Executable command name or path
    property string terminalAppId: "com.mitchellh.ghostty" // Desktop entry ID for icon/metadata lookup

    // =========================================================================
    // ATOMIC FILE VIEW & DEBOUNCE TIMER
    // =========================================================================
    property FileView fileView: FileView {
        id: view
        path: root.configPath
        atomicWrites: true
        printErrors: false

        onSaved: {
            root.isSaving = false;
            root.hasSaveError = false;
            root.lastSaveError = "";
            root.saved(root.configPath);
        }

        onSaveFailed: error => {
            root.isSaving = false;
            root.hasSaveError = true;
            root.lastSaveError = "Atomic write failed: " + error;
            console.error("Config.qml: Failed to save configuration to", root.configPath, "error:", error);
            root.saveFailed(root.lastSaveError);
        }
    }

    property Timer debounceTimer: Timer {
        id: debounce
        interval: 350
        repeat: false
        onTriggered: {
            root.saveNow();
        }
    }

    // =========================================================================
    // SCHEMA DEFAULTS REFERENCE
    // =========================================================================
    readonly property var schemaDefaults: ({
        version: 1,
        bar: {
            position: "top",
            height: 44,
            floating: true,
            margin: 8,
            showWorkspaces: true,
            showTitle: true,
            showTray: true,
            showClock: true,
            showBattery: true,
            showAudio: true
        },
        theme: {
            name: "crazydots-default",
            mode: "dark",
            opacity: 0.90,
            blur: true
        },
        wallpaper: {
            current: "",
            mode: "fill",
            directory: Quickshell.env("HOME") + "/Pictures/Wallpapers"
        },
        animations: {
            enabled: true,
            speed: 1.0
        },
        launcher: {
            shortcut: "SUPER",
            maxResults: 8,
            itemHeight: 52
        },
        dashboard: {
            corner: "top-right",
            width: 380,
            height: 520
        },
        terminal: {
            command: "ghostty",
            appId: "com.mitchellh.ghostty"
        }
    })

    // =========================================================================
    // VALIDATION & SANITIZATION LOGIC
    // =========================================================================

    /**
     * validateAndSanitize(raw):
     * Takes an arbitrary parsed JSON object and returns a thoroughly validated
     * configuration object where all types and ranges are strictly enforced.
     */
    function validateAndSanitize(raw) {
        const d = root.schemaDefaults;
        const res = JSON.parse(JSON.stringify(d)); // Clone defaults

        if (!raw || typeof raw !== "object") {
            return res;
        }

        // --- Bar validation ---
        if (raw.bar && typeof raw.bar === "object") {
            if (raw.bar.position === "top" || raw.bar.position === "bottom" || raw.bar.position === "left") {
                res.bar.position = raw.bar.position;
            } else if (raw.bar.position !== undefined) {
                root.validationWarning("bar.position", "Invalid position, expected 'top', 'bottom', or 'left'");
            }

            if (typeof raw.bar.height === "number" && !isNaN(raw.bar.height)) {
                res.bar.height = Math.max(24, Math.min(120, Math.round(raw.bar.height)));
            }
            if (typeof raw.bar.floating === "boolean") res.bar.floating = raw.bar.floating;
            if (typeof raw.bar.margin === "number" && !isNaN(raw.bar.margin)) {
                res.bar.margin = Math.max(0, Math.min(64, Math.round(raw.bar.margin)));
            }
            if (typeof raw.bar.showWorkspaces === "boolean") res.bar.showWorkspaces = raw.bar.showWorkspaces;
            if (typeof raw.bar.showTitle === "boolean") res.bar.showTitle = raw.bar.showTitle;
            if (typeof raw.bar.showTray === "boolean") res.bar.showTray = raw.bar.showTray;
            if (typeof raw.bar.showClock === "boolean") res.bar.showClock = raw.bar.showClock;
            if (typeof raw.bar.showBattery === "boolean") res.bar.showBattery = raw.bar.showBattery;
            if (typeof raw.bar.showAudio === "boolean") res.bar.showAudio = raw.bar.showAudio;
        }

        // --- Theme validation ---
        if (raw.theme && typeof raw.theme === "object") {
            if (typeof raw.theme.name === "string" && raw.theme.name.trim().length > 0) {
                res.theme.name = raw.theme.name.trim();
            }
            if (raw.theme.mode === "dark" || raw.theme.mode === "light") {
                res.theme.mode = raw.theme.mode;
            }
            if (typeof raw.theme.opacity === "number" && !isNaN(raw.theme.opacity)) {
                res.theme.opacity = Math.max(0.1, Math.min(1.0, raw.theme.opacity));
            }
            if (typeof raw.theme.blur === "boolean") res.theme.blur = raw.theme.blur;
        }

        // --- Wallpaper validation ---
        if (raw.wallpaper && typeof raw.wallpaper === "object") {
            if (typeof raw.wallpaper.current === "string") {
                res.wallpaper.current = raw.wallpaper.current;
            }
            if (["fill", "fit", "center", "tile"].indexOf(raw.wallpaper.mode) !== -1) {
                res.wallpaper.mode = raw.wallpaper.mode;
            }
            if (typeof raw.wallpaper.directory === "string" && raw.wallpaper.directory.trim().length > 0) {
                res.wallpaper.directory = raw.wallpaper.directory.trim();
            }
        }

        // --- Animations validation ---
        if (raw.animations && typeof raw.animations === "object") {
            if (typeof raw.animations.enabled === "boolean") res.animations.enabled = raw.animations.enabled;
            if (typeof raw.animations.speed === "number" && !isNaN(raw.animations.speed)) {
                res.animations.speed = Math.max(0.1, Math.min(3.0, raw.animations.speed));
            }
        }

        // --- Launcher validation ---
        if (raw.launcher && typeof raw.launcher === "object") {
            if (typeof raw.launcher.shortcut === "string" && raw.launcher.shortcut.length > 0) {
                res.launcher.shortcut = raw.launcher.shortcut;
            }
            if (typeof raw.launcher.maxResults === "number" && !isNaN(raw.launcher.maxResults)) {
                res.launcher.maxResults = Math.max(1, Math.min(30, Math.round(raw.launcher.maxResults)));
            }
            if (typeof raw.launcher.itemHeight === "number" && !isNaN(raw.launcher.itemHeight)) {
                res.launcher.itemHeight = Math.max(36, Math.min(96, Math.round(raw.launcher.itemHeight)));
            }
        }

        // --- Dashboard validation ---
        if (raw.dashboard && typeof raw.dashboard === "object") {
            if (["top-right", "top-left", "bottom-right", "bottom-left"].indexOf(raw.dashboard.corner) !== -1) {
                res.dashboard.corner = raw.dashboard.corner;
            }
            if (typeof raw.dashboard.width === "number" && !isNaN(raw.dashboard.width)) {
                res.dashboard.width = Math.max(260, Math.min(800, Math.round(raw.dashboard.width)));
            }
            if (typeof raw.dashboard.height === "number" && !isNaN(raw.dashboard.height)) {
                res.dashboard.height = Math.max(300, Math.min(1200, Math.round(raw.dashboard.height)));
            }
        }

        // --- Terminal validation ---
        if (raw.terminal && typeof raw.terminal === "object") {
            if (typeof raw.terminal.command === "string" && raw.terminal.command.trim().length > 0) {
                const cleanCmd = raw.terminal.command.trim();
                if (/^[a-zA-Z0-9_\-\./]+$/.test(cleanCmd)) {
                    res.terminal.command = cleanCmd;
                } else {
                    root.validationWarning("terminal.command", "Invalid terminal binary name: " + cleanCmd);
                }
            }
            if (typeof raw.terminal.appId === "string" && raw.terminal.appId.trim().length > 0) {
                const cleanId = raw.terminal.appId.trim();
                if (/^[a-zA-Z0-9_\-\.]+$/.test(cleanId)) {
                    res.terminal.appId = cleanId;
                } else {
                    root.validationWarning("terminal.appId", "Invalid terminal application ID: " + cleanId);
                }
            }
        }

        return res;
    }

    /**
     * applyValidatedObject(clean):
     * Sets all individual reactive properties from a sanitized configuration object.
     */
    function applyValidatedObject(clean) {
        root.barPosition = clean.bar.position;
        root.barHeight = clean.bar.height;
        root.barFloating = clean.bar.floating;
        root.barMargin = clean.bar.margin;
        root.barShowWorkspaces = clean.bar.showWorkspaces;
        root.barShowTitle = clean.bar.showTitle;
        root.barShowTray = clean.bar.showTray;
        root.barShowClock = clean.bar.showClock;
        root.barShowBattery = clean.bar.showBattery;
        root.barShowAudio = clean.bar.showAudio;

        root.themeName = clean.theme.name;
        root.themeMode = clean.theme.mode;
        root.themeOpacity = clean.theme.opacity;
        root.themeBlur = clean.theme.blur;

        root.wallpaperCurrent = clean.wallpaper.current;
        root.wallpaperMode = clean.wallpaper.mode;
        root.wallpaperDirectory = clean.wallpaper.directory || (Quickshell.env("HOME") + "/Pictures/Wallpapers");

        root.animationsEnabled = clean.animations.enabled;
        root.animationSpeed = clean.animations.speed;

        root.launcherShortcut = clean.launcher.shortcut;
        root.launcherMaxResults = clean.launcher.maxResults;
        root.launcherItemHeight = clean.launcher.itemHeight;

        root.dashboardCorner = clean.dashboard.corner;
        root.dashboardWidth = clean.dashboard.width;
        root.dashboardHeight = clean.dashboard.height;

        if (clean.terminal) {
            root.terminalCommand = clean.terminal.command;
            root.terminalAppId = clean.terminal.appId;
        }

        // Sync theme with Theme singleton if valid
        Theme.setTheme(clean.theme.name);

        root.configChanged();
    }

    /**
     * toObject():
     * Serializes current reactive properties into the standard nested JSON format.
     */
    function toObject() {
        return {
            version: 1,
            bar: {
                position: root.barPosition,
                height: root.barHeight,
                floating: root.barFloating,
                margin: root.barMargin,
                showWorkspaces: root.barShowWorkspaces,
                showTitle: root.barShowTitle,
                showTray: root.barShowTray,
                showClock: root.barShowClock,
                showBattery: root.barShowBattery,
                showAudio: root.barShowAudio
            },
            theme: {
                name: root.themeName,
                mode: root.themeMode,
                opacity: root.themeOpacity,
                blur: root.themeBlur
            },
            wallpaper: {
                current: root.wallpaperCurrent,
                mode: root.wallpaperMode,
                directory: root.wallpaperDirectory
            },
            animations: {
                enabled: root.animationsEnabled,
                speed: root.animationSpeed
            },
            launcher: {
                shortcut: root.launcherShortcut,
                maxResults: root.launcherMaxResults,
                itemHeight: root.launcherItemHeight
            },
            dashboard: {
                corner: root.dashboardCorner,
                width: root.dashboardWidth,
                height: root.dashboardHeight
            },
            terminal: {
                command: root.terminalCommand,
                appId: root.terminalAppId
            }
        };
    }

    // =========================================================================
    // FILE I/O METHODS
    // =========================================================================

    /**
     * loadFromFile(optionalPath):
     * Loads, parses, validates, and applies configuration from disk.
     * Recovers safely from missing files and malformed JSON.
     */
    function loadFromFile(optionalPath: string): bool {
        const targetPath = (optionalPath && optionalPath.length > 0) ? optionalPath : root.configPath;
        root.fileView.path = targetPath;

        const text = root.fileView.text();

        // 1. Missing file: apply defaults without error
        if (!text || text.trim().length === 0) {
            root.applyValidatedObject(root.schemaDefaults);
            root.isLoaded = true;
            root.lastLoadedTime = new Date();
            root.loaded(targetPath);
            return true;
        }

        // 2. Parse JSON safely
        let raw;
        try {
            raw = JSON.parse(text);
        } catch (e) {
            console.warn("Config.qml: Malformed JSON in", targetPath, "- preserving current settings and falling back to defaults. Error:", e);
            root.validationWarning("json", "Malformed JSON: " + e);
            root.applyValidatedObject(root.schemaDefaults);
            root.isLoaded = true;
            return false;
        }

        // 3. Validate, clamp, and apply
        const clean = root.validateAndSanitize(raw);
        root.applyValidatedObject(clean);
        root.isLoaded = true;
        root.lastLoadedTime = new Date();
        root.loaded(targetPath);
        return true;
    }

    /**
     * saveNow():
     * Immediately serializes current state to formatted JSON and writes atomically to disk.
     */
    function saveNow(): bool {
        root.isSaving = true;
        root.hasSaveError = false;

        const obj = root.toObject();
        let jsonStr;
        try {
            jsonStr = JSON.stringify(obj, null, 2);
        } catch (e) {
            root.isSaving = false;
            root.hasSaveError = true;
            root.lastSaveError = "Serialization error: " + e;
            console.error("Config.qml: Failed to serialize config:", e);
            root.saveFailed(root.lastSaveError);
            return false;
        }

        root.fileView.setText(jsonStr);
        return true;
    }

    /**
     * saveDebounced(delayMs):
     * Restarts debounce timer to batch rapid changes before writing to disk.
     */
    function saveDebounced(delayMs: int) {
        root.debounceTimer.interval = (delayMs !== undefined && delayMs > 0) ? delayMs : 350;
        root.debounceTimer.restart();
    }

    /**
     * resetToDefaults():
     * Restores all properties to their default schema values and saves.
     */
    function resetToDefaults() {
        root.applyValidatedObject(root.schemaDefaults);
        root.saveDebounced(100);
    }

    // =========================================================================
    // MUTATION HELPERS (INTEGRATION WITH SHELL SETTINGS)
    // =========================================================================

    function setBarHeight(h: int): bool {
        const clamped = Math.max(24, Math.min(120, h));
        if (root.barHeight === clamped) return false;
        root.barHeight = clamped;
        root.saveDebounced(350);
        return true;
    }

    function setBarPosition(pos: string): bool {
        if (pos !== "top" && pos !== "bottom" && pos !== "left") return false;
        if (root.barPosition === pos) return false;
        root.barPosition = pos;
        root.saveDebounced(350);
        return true;
    }

    function setThemeName(name: string): bool {
        if (!name || name.trim().length === 0) return false;
        if (root.themeName === name) return false;
        root.themeName = name;
        Theme.setTheme(name);
        root.saveDebounced(350);
        return true;
    }

    function setAnimationsEnabled(enabled: bool) {
        if (root.animationsEnabled === enabled) return;
        root.animationsEnabled = enabled;
        root.saveDebounced(350);
    }

    function setAnimationSpeed(speed: real): bool {
        const clamped = Math.max(0.1, Math.min(3.0, speed));
        if (root.animationSpeed === clamped) return false;
        root.animationSpeed = clamped;
        root.saveDebounced(350);
        return true;
    }

    function setWallpaper(path: string, mode: string) {
        root.wallpaperCurrent = path;
        if (["fill", "fit", "center", "tile"].indexOf(mode) !== -1) {
            root.wallpaperMode = mode;
        }
        root.saveDebounced(350);
    }

    function setWallpaperDirectory(dir: string): bool {
        if (!dir || dir.trim().length === 0) return false;
        root.wallpaperDirectory = dir.trim();
        root.saveDebounced(350);
        return true;
    }

    function setDashboardCorner(corner: string): bool {
        if (["top-right", "top-left", "bottom-right", "bottom-left"].indexOf(corner) === -1) return false;
        if (root.dashboardCorner === corner) return true;
        root.dashboardCorner = corner;
        root.saveDebounced(350);
        return true;
    }

    function setDashboardWidth(w: int): bool {
        const clamped = Math.max(260, Math.min(800, w));
        if (root.dashboardWidth === clamped) return true;
        root.dashboardWidth = clamped;
        root.saveDebounced(350);
        return true;
    }

    function setDashboardHeight(h: int): bool {
        const clamped = Math.max(300, Math.min(1200, h));
        if (root.dashboardHeight === clamped) return true;
        root.dashboardHeight = clamped;
        root.saveDebounced(350);
        return true;
    }

    function setTerminalCommand(cmd: string): bool {
        if (!cmd || typeof cmd !== "string" || cmd.trim().length === 0) return false;
        const clean = cmd.trim();
        if (!/^[a-zA-Z0-9_\-\./]+$/.test(clean)) {
            console.warn("crazydots: Rejected invalid terminal command binary:", clean);
            return false;
        }
        if (root.terminalCommand === clean) return true;
        root.terminalCommand = clean;
        root.saveDebounced(350);
        return true;
    }

    function setTerminalAppId(id: string): bool {
        if (!id || typeof id !== "string" || id.trim().length === 0) return false;
        const clean = id.trim();
        if (!/^[a-zA-Z0-9_\-\.]+$/.test(clean)) {
            console.warn("crazydots: Rejected invalid terminal application ID:", clean);
            return false;
        }
        if (root.terminalAppId === clean) return true;
        root.terminalAppId = clean;
        root.saveDebounced(350);
        return true;
    }

    // =========================================================================
    // BOOTSTRAP LIFECYCLE
    // =========================================================================
    Component.onCompleted: {
        root.loadFromFile("");
    }
}
