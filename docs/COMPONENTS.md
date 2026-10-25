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
- **`ButtonBase.qml`**: Accessible interactive clickable surface with hover, active, and pressed visual states, cursor management, and click handlers.

### 2.2 Panels (`shell/panels/`)
- **`Bar.qml`**: Desktop taskbar and edge bezel dock. Supports horizontal top/bottom bar and vertical left dock (`Config.barPosition === "left"`). Integrates Iris branding launcher trigger, vertical workspaces, active window title, and compact bottom hotspots (Connectivity, Volume, Battery, Quick Toggles, Dashboard).
- **`Launcher.qml`**: Floating application launcher (540×480) positioned in the lower-middle display area, implementing an inverted layout matching `launcher_primary_reference.png`. Features an unconstrained full desktop-entry catalog at top, smooth scrolling and selection, bottom search capsule (`Type ">" for commands`), Iris logo badge, and working command execution mode (`> <cmd>`).
- **`WallpaperSurface.qml`**: Background layer-shell window rendering wallpaper images with fill modes (fill, fit, center, tile), crossfades, theme background fallback, and desktop double-click gestures (left = Wallpaper Manager, right = Theme Manager).
- **`WallpaperManager.qml`**: Visual wallpaper selector modal with asynchronous directory scanning, thumbnail grid, search filter, and dynamic color synthesis.
- **`ThemeManager.qml`**: Dedicated appearance and theme management modal dialog (620×520) featuring active color palette swatches, 8 curated theme presets, live selection indicators, and dynamic wallpaper palette generation.
- **`Dashboard.qml`**: Tabbed floating control center (740×520) matching `dashboard_reference.png`. Features 4 tabs (Dashboard, Media, Performance, Weather), truthful live uptime from `/proc/uptime`, interactive month calendar, hardware telemetry gauges (CPU %, RAM %, Battery %), live MPRIS playback controls, and quick action shortcuts.
- **`popovers/`**: Compact contextual drawer popovers anchored adjacent to bar controls (with adaptive left-bezel or horizontal-bar positioning):
  - **`ConnectivityPopover.qml`**: Compact network popover displaying active Wi-Fi connection, signal quality, scrollable available networks list, rescan trigger, radio toggle, and truthful Bluetooth daemon state.
  - **`VolumePopover.qml`**: PipeWire audio popover featuring master output volume slider, mute toggle, microphone input level indicator, and mic mute toggle.
  - **`BrightnessPopover.qml`**: Hardware display backlight popover featuring real-time slider, percentage indicator, device name, and unavailable hardware detection.
  - **`QuickTogglesPopover.qml`**: Compact unified control capsule featuring 2×2 quick toggle pills (Wi-Fi, Bluetooth, Audio Mute, Animations), mini-sliders for volume and brightness, and direct triggers for Theme and Wallpaper managers.

### 2.3 Iris Brand Assets (`assets/iris_logo/`)
- **`iris.svg`**: Full-color Iris logo mark preserved bit-for-bit from source assets.
- **`iris-mono.svg`**: Monochrome / currentColor variant for dark-surface badges.
- **`iris-small.svg`**: Optimized compact mark for bar triggers and search capsule badges.

### 2.4 Services (`shell/services/`)
- **`ThemeEngine.qml`**: Headless coordinator managing dynamic themes, Matugen JSON palettes, and native ColorQuantizer wallpaper extraction.
- **`HyprlandService.qml`**: Central compositor service exposing sanitized workspace, toplevel window, monitor states, and safe dispatchers.
- **`TerminalService.qml`**: Terminal launch integration for Ghostty and preferred terminal emulators with DesktopEntry and Process fallbacks.
- **`NetworkService.qml`**: Asynchronous NetworkManager wrapper using `nmcli` to inspect radio state, connected SSID, signal strength, and available networks without ever storing or logging passwords; truthfully queries Bluetooth daemon status via `systemctl`.
- **`BrightnessService.qml`**: Hardware backlight controller using `brightnessctl` to inspect and clamp brightness percentages across system display devices without requiring elevated permissions.


