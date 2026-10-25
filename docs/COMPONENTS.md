# crazydots — Components Catalog

This document details the reusable component hierarchy and design conventions for crazydots.

---

## 1. Design System Foundations

All components consume values from `Tokens.qml` and `Theme.qml`. Hardcoded pixel values and color literals (`#ffffff`) are prohibited in UI components.

### 1.1 Spacing Tokens
- `Tokens.spacing.xs`: 4px
- `Tokens.spacing.sm`: 8px
- `Tokens.spacing.md`: 12px
- `Tokens.spacing.lg`: 16px
- `Tokens.spacing.xl`: 24px
- `Tokens.spacing.xxl`: 32px

### 1.2 Corner Radii Tokens
- `Tokens.radius.sm`: 6px
- `Tokens.radius.md`: 12px
- `Tokens.radius.lg`: 18px
- `Tokens.radius.full`: 9999px (circular / pills)

### 1.3 Semantic Theme Tokens
- `Theme.background`: Primary background.
- `Theme.surface`: Card backgrounds, elevated widgets.
- `Theme.surfaceElevated`: Menus, floating popups.
- `Theme.foreground`: Primary high-contrast text.
- `Theme.mutedForeground`: Secondary subtle text and descriptions.
- `Theme.accent`: Primary accent / highlight.
- `Theme.accentSecondary`: Subtle secondary accent.
- `Theme.border`: Card and divider borders.
- `Theme.selection`: List and menu active selection highlights.
- `Theme.success`, `Theme.warning`, `Theme.error`: Status indicators.

---

## 2. Component Hierarchy

### 2.1 Base Primitives (`shell/components/`)
- **`StyledRect.qml`**: Background rectangle with default theme colors, border radii, and smooth `ColorAnimation` on theme shifts.
- **`StyledText.qml`**: Typography element with default fonts (JetBrainsMono Nerd Font / Adwaita Sans) and semantic color bindings.
- **`StyledButton.qml`**: Interactive button with hover, pressed, and focused visual feedback states.
- **`FilledSlider.qml`**: Smooth custom slider for volume, brightness, or settings sliders.
- **`Icon.qml`**: Standardized glyph rendering supporting both Nerd Font symbols and system icons via `Quickshell.Widgets.IconImage`.

### 2.2 Panels (`shell/panels/`)
- **`Bar.qml`**: Desktop taskbar containing workspaces, clock, tray, battery, and audio controls.
- **`Launcher.qml`**: Modal application launcher with live desktop-entry search input, keyboard navigation, and application delegates.
- **`WallpaperSurface.qml`**: Background layer-shell window rendering wallpaper images with fill modes (fill, fit, center, tile), crossfades, and theme background fallback.
- **`WallpaperManager.qml`**: Visual wallpaper selector modal with asynchronous directory scanning, thumbnail grid, search filter, and dynamic color synthesis.
- **`Dashboard.qml`**: Corner slide-in control center containing quick settings, audio volume track, battery status, theme selector, wallpaper info, and motion preferences.

#### 2.2.1 Bar Sub-Widgets (`shell/panels/bar/`)
- **`BarPill.qml`**: Interactive capsule container handling hover, press, click, and mouse wheel actions with smooth color transitions.
- **`Workspaces.qml`**: Hyprland workspace indicator with elastic spring-expanding active pills, special workspace filtering, ascending ID ordering, click activation, and mouse wheel cycling.
- **`ActiveWindow.qml`**: Focused window title display with status dot, elision bounds, and graceful empty-state desktop handling.
- **`ClockWidget.qml`**: Digital clock and calendar date display with jitter-free monospace typography.
- **`AudioWidget.qml`**: Pipewire volume meter with dynamic volume glyphs, mute toggling on click, and 5% scroll step adjustments.
- **`BatteryWidget.qml`**: UPower battery indicator with charging/discharging states, capacity thresholds, low-battery warning, and automatic collapse on desktop systems.
- **`TrayWidget.qml`**: StatusNotifierItem (SNI) system tray with icon rendering via `Quickshell.Widgets.IconImage` and left/right click actions.

### 2.3 Services (`shell/services/`)
- **`ThemeEngine.qml`**: Headless coordinator managing dynamic themes, Matugen JSON palettes, and native ColorQuantizer wallpaper extraction.
- **`HyprlandService.qml`**: Central compositor service exposing sanitized workspace, toplevel window, monitor states, and safe dispatchers.
- **`TerminalService.qml`**: Terminal launch integration for Ghostty and preferred terminal emulators with DesktopEntry and Process fallbacks.


