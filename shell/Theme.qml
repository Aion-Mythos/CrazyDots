pragma Singleton
import QtQuick

/**
 * Theme.qml
 * Central semantic theme engine for crazydots.
 *
 * Responsibilities:
 * - Exposes semantic color tokens (background, surface, foreground, accent, etc.) to all components.
 * - Manages active theme selection and reactive updates across the entire shell.
 * - Stores built-in themes (crazydots-default, Catppuccin, Tokyo Night, Nord, Gruvbox, etc.) in memory.
 * - Integrates dynamic Matugen palettes generated from wallpapers.
 * - Provides an intelligent fallback algorithm that synthesizes a cohesive dark palette
 *   directly from Quickshell's ColorQuantizer if Matugen is not installed.
 * - Exposes mathematical color helpers: alpha(), lighten(), darken(), mix().
 *
 * All visual UI elements in crazydots bind strictly to Theme.* semantic properties.
 */
QtObject {
    id: root

    // =========================================================================
    // ACTIVE THEME METADATA
    // =========================================================================
    property string activeThemeName: "crazydots-default"
    property string activeThemeDisplayName: "crazydots Signature"
    property bool isDynamic: false

    // Signal emitted whenever semantic colors change
    signal themeChanged(string name)

    // =========================================================================
    // SEMANTIC COLOR TOKENS
    // Default values match the crazydots signature palette.
    // =========================================================================
    property color background: "#0d0e15"
    property color surface: "#141724"
    property color surfaceElevated: "#1c2033"

    property color foreground: "#e6eaf8"
    property color mutedForeground: "#8b94b2"

    property color accent: "#2ee6ca"
    property color accentSecondary: "#ff6b8b"

    property color border: "#282e47"
    property color borderFocus: "#2ee6ca"

    property color selection: "#273152"
    property color selectionForeground: "#ffffff"

    property color success: "#34d399"
    property color warning: "#fbbf24"
    property color error: "#f87171"
    property color shadow: "#000000"

    // =========================================================================
    // COLOR MANIPULATION UTILITIES
    // =========================================================================

    /**
     * alpha(c, a): Returns color `c` with transparency factor `a` (0.0 to 1.0).
     */
    function alpha(c: color, a: real): color {
        return Qt.rgba(c.r, c.g, c.b, Math.max(0.0, Math.min(1.0, a)));
    }

    /**
     * lighten(c, factor): Lightens color `c` by factor (0.0 to 1.0).
     */
    function lighten(c: color, factor: real): color {
        const f = Math.max(0.0, Math.min(1.0, factor));
        return Qt.rgba(
            Math.min(1.0, c.r + (1.0 - c.r) * f),
            Math.min(1.0, c.g + (1.0 - c.g) * f),
            Math.min(1.0, c.b + (1.0 - c.b) * f),
            c.a
        );
    }

    /**
     * darken(c, factor): Darkens color `c` by factor (0.0 to 1.0).
     */
    function darken(c: color, factor: real): color {
        const f = Math.max(0.0, Math.min(1.0, factor));
        return Qt.rgba(
            Math.max(0.0, c.r * (1.0 - f)),
            Math.max(0.0, c.g * (1.0 - f)),
            Math.max(0.0, c.b * (1.0 - f)),
            c.a
        );
    }

    /**
     * mix(c1, c2, weight): Linearly interpolates between two colors.
     * weight: 0.0 returns c1, 1.0 returns c2.
     */
    function mix(c1: color, c2: color, weight: real): color {
        const w = Math.max(0.0, Math.min(1.0, weight));
        const inv = 1.0 - w;
        return Qt.rgba(
            c1.r * inv + c2.r * w,
            c1.g * inv + c2.g * w,
            c1.b * inv + c2.b * w,
            c1.a * inv + c2.a * w
        );
    }

    // =========================================================================
    // BUILT-IN THEMES REGISTRY
    // =========================================================================
    readonly property var builtinThemes: ({
        "crazydots-default": {
            displayName: "crazydots Signature (Obsidian & Electric Cyan)",
            background: "#0d0e15",
            surface: "#141724",
            surfaceElevated: "#1c2033",
            foreground: "#e6eaf8",
            mutedForeground: "#8b94b2",
            accent: "#2ee6ca",
            accentSecondary: "#ff6b8b",
            border: "#282e47",
            borderFocus: "#2ee6ca",
            selection: "#273152",
            selectionForeground: "#ffffff",
            success: "#34d399",
            warning: "#fbbf24",
            error: "#f87171",
            shadow: "#000000"
        },
        "catppuccin-mocha": {
            displayName: "Catppuccin Mocha",
            background: "#1e1e2e",
            surface: "#181825",
            surfaceElevated: "#313244",
            foreground: "#cdd6f4",
            mutedForeground: "#a6adc8",
            accent: "#89b4fa",
            accentSecondary: "#f5c2e7",
            border: "#45475a",
            borderFocus: "#89b4fa",
            selection: "#585b70",
            selectionForeground: "#ffffff",
            success: "#a6e3a1",
            warning: "#f9e2af",
            error: "#f38ba8",
            shadow: "#11111b"
        },
        "tokyo-night": {
            displayName: "Tokyo Night",
            background: "#1a1b26",
            surface: "#16161e",
            surfaceElevated: "#24283b",
            foreground: "#c0caf5",
            mutedForeground: "#7aa2f7",
            accent: "#7aa2f7",
            accentSecondary: "#bb9af7",
            border: "#292e42",
            borderFocus: "#7dcfff",
            selection: "#33467c",
            selectionForeground: "#ffffff",
            success: "#9ece6a",
            warning: "#e0af68",
            error: "#f7768e",
            shadow: "#101014"
        },
        "nord": {
            displayName: "Nord Frost",
            background: "#2e3440",
            surface: "#3b4252",
            surfaceElevated: "#434c5e",
            foreground: "#eceff4",
            mutedForeground: "#d8dee9",
            accent: "#88c0d0",
            accentSecondary: "#81a1c1",
            border: "#4c566a",
            borderFocus: "#8fbcbb",
            selection: "#4c566a",
            selectionForeground: "#eceff4",
            success: "#a3be8c",
            warning: "#ebcb8b",
            error: "#bf616a",
            shadow: "#1e222a"
        },
        "gruvbox-dark": {
            displayName: "Gruvbox Dark",
            background: "#282828",
            surface: "#1d2021",
            surfaceElevated: "#3c3836",
            foreground: "#ebdbb2",
            mutedForeground: "#a89984",
            accent: "#fe8019",
            accentSecondary: "#fabd2f",
            border: "#504945",
            borderFocus: "#fe8019",
            selection: "#665c54",
            selectionForeground: "#fbf1c7",
            success: "#b8bb26",
            warning: "#fabd2f",
            error: "#fb4934",
            shadow: "#141617"
        },
        "dracula": {
            displayName: "Dracula",
            background: "#282a36",
            surface: "#21222c",
            surfaceElevated: "#44475a",
            foreground: "#f8f8f2",
            mutedForeground: "#6272a4",
            accent: "#bd93f9",
            accentSecondary: "#ff79c6",
            border: "#44475a",
            borderFocus: "#bd93f9",
            selection: "#44475a",
            selectionForeground: "#ffffff",
            success: "#50fa7b",
            warning: "#f1fa8c",
            error: "#ff5555",
            shadow: "#191a21"
        },
        "rose-pine": {
            displayName: "Rosé Pine",
            background: "#191724",
            surface: "#1f1d2e",
            surfaceElevated: "#26233a",
            foreground: "#e0def4",
            mutedForeground: "#908caa",
            accent: "#ebbcba",
            accentSecondary: "#31748f",
            border: "#524f67",
            borderFocus: "#ebbcba",
            selection: "#403d52",
            selectionForeground: "#e0def4",
            success: "#9ccfd8",
            warning: "#f6c177",
            error: "#eb6f92",
            shadow: "#12101b"
        },
        "everforest": {
            displayName: "Everforest Dark",
            background: "#2b3339",
            surface: "#232a2e",
            surfaceElevated: "#323c41",
            foreground: "#d3c6aa",
            mutedForeground: "#9da9a0",
            accent: "#a7c080",
            accentSecondary: "#7fbbb3",
            border: "#475258",
            borderFocus: "#a7c080",
            selection: "#3a454a",
            selectionForeground: "#d3c6aa",
            success: "#a7c080",
            warning: "#dbbc7f",
            error: "#e67e80",
            shadow: "#1a1e21"
        }
    })

    // =========================================================================
    // THEME APPLICATION METHODS
    // =========================================================================

    /**
     * applyPalette(palette): Applies an arbitrary palette dictionary to semantic tokens.
     * Safely checks properties before assignment.
     */
    function applyPalette(palette): bool {
        if (!palette) return false;

        if (palette.background) root.background = palette.background;
        if (palette.surface) root.surface = palette.surface;
        if (palette.surfaceElevated) root.surfaceElevated = palette.surfaceElevated;
        if (palette.foreground) root.foreground = palette.foreground;
        if (palette.mutedForeground) root.mutedForeground = palette.mutedForeground;
        if (palette.accent) root.accent = palette.accent;
        if (palette.accentSecondary) root.accentSecondary = palette.accentSecondary;
        if (palette.border) root.border = palette.border;
        if (palette.borderFocus) root.borderFocus = palette.borderFocus;
        if (palette.selection) root.selection = palette.selection;
        if (palette.selectionForeground) root.selectionForeground = palette.selectionForeground;
        if (palette.success) root.success = palette.success;
        if (palette.warning) root.warning = palette.warning;
        if (palette.error) root.error = palette.error;
        if (palette.shadow) root.shadow = palette.shadow;

        root.themeChanged(root.activeThemeName);
        return true;
    }

    /**
     * setTheme(name): Switches to a named built-in theme.
     */
    function setTheme(name: string): bool {
        if (root.builtinThemes[name]) {
            root.activeThemeName = name;
            root.activeThemeDisplayName = root.builtinThemes[name].displayName ?? name;
            root.isDynamic = false;
            return applyPalette(root.builtinThemes[name]);
        }
        console.warn("Theme.setTheme: Theme not found:", name);
        return false;
    }

    /**
     * loadPaletteJson(jsonString): Parses a JSON palette (e.g. from Matugen or custom file).
     * Handles both flat crazydots schema and nested Material 3/Matugen schema.
     */
    function loadPaletteJson(jsonString: string): bool {
        try {
            const data = JSON.parse(jsonString);
            if (!data) return false;

            // Handle standard crazydots flat schema
            if (data.background && data.accent) {
                root.activeThemeName = data.name ?? "custom";
                root.activeThemeDisplayName = data.displayName ?? "Custom Theme";
                root.isDynamic = true;
                return applyPalette(data);
            }

            // Handle Matugen JSON schema (nested colors.dark / colors.light)
            if (data.colors && (data.colors.dark || data.colors.light)) {
                const c = data.colors.dark ?? data.colors.light;
                const mapped = {
                    background: c.background ?? "#0d0e15",
                    surface: c.surface ?? "#141724",
                    surfaceElevated: c.surface_container_high ?? c.surface_variant ?? "#1c2033",
                    foreground: c.on_surface ?? c.on_background ?? "#e6eaf8",
                    mutedForeground: c.outline ?? "#8b94b2",
                    accent: c.primary ?? "#2ee6ca",
                    accentSecondary: c.secondary ?? "#ff6b8b",
                    border: c.outline_variant ?? c.outline ?? "#282e47",
                    borderFocus: c.primary ?? "#2ee6ca",
                    selection: c.secondary_container ?? "#273152",
                    selectionForeground: c.on_secondary_container ?? "#ffffff",
                    success: "#34d399",
                    warning: "#fbbf24",
                    error: c.error ?? "#f87171",
                    shadow: c.shadow ?? "#000000"
                };
                root.activeThemeName = "matugen";
                root.activeThemeDisplayName = "Matugen Dynamic";
                root.isDynamic = true;
                return applyPalette(mapped);
            }
        } catch (e) {
            console.warn("Theme.loadPaletteJson: Failed to parse palette JSON:", e);
        }
        return false;
    }

    /**
     * applyFromQuantizer(colors):
     * Intelligent fallback color generator using Quickshell's native ColorQuantizer.
     * Takes an array of QColor items extracted from a wallpaper and generates
     * a cohesive, high-contrast dark theme.
     */
    function applyFromQuantizer(colors): bool {
        if (!colors || colors.length === 0) {
            console.warn("Theme.applyFromQuantizer: Empty color list, keeping current theme");
            return false;
        }

        // 1. Identify dominant color and vibrant accent
        let dominant = colors[0];
        let bestAccent = dominant;
        let maxSaturation = -1;

        // Find the color with the highest saturation for the vibrant accent
        for (let i = 0; i < colors.length; i++) {
            const c = colors[i];
            const maxVal = Math.max(c.r, c.g, c.b);
            const minVal = Math.min(c.r, c.g, c.b);
            const sat = maxVal > 0 ? (maxVal - minVal) / maxVal : 0;
            if (sat > maxSaturation && maxVal > 0.3) {
                maxSaturation = sat;
                bestAccent = c;
            }
        }

        // 2. Synthesize dark obsidian background tinted slightly with dominant color
        const darkBase = Qt.rgba(0.05, 0.05, 0.07, 1.0);
        const bg = root.mix(darkBase, dominant, 0.08);

        // 3. Synthesize elevated surface and container
        const surf = root.lighten(bg, 0.05);
        const surfElevated = root.lighten(bg, 0.10);

        // 4. Synthesize border
        const brd = root.lighten(bg, 0.16);

        // 5. Secondary accent (lightened or hue-shifted)
        const secondary = colors.length > 1 ? colors[1] : root.lighten(bestAccent, 0.2);

        const synthetic = {
            name: "quantizer",
            displayName: "Wallpaper Dynamic (Quantized)",
            background: bg,
            surface: surf,
            surfaceElevated: surfElevated,
            foreground: "#e6eaf8",
            mutedForeground: "#8b94b2",
            accent: bestAccent,
            accentSecondary: secondary,
            border: brd,
            borderFocus: bestAccent,
            selection: root.alpha(bestAccent, 0.25),
            selectionForeground: "#ffffff",
            success: "#34d399",
            warning: "#fbbf24",
            error: "#f87171",
            shadow: "#000000"
        };

        root.activeThemeName = "quantizer";
        root.activeThemeDisplayName = "Wallpaper Dynamic (Quantizer)";
        root.isDynamic = true;
        return applyPalette(synthetic);
    }
}
