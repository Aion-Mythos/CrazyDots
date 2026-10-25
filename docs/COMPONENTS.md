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
- **`Launcher.qml`**: Modal application launcher with live search input, keyboard navigation, and application delegates.
- **`Dashboard.qml`**: Corner slide-in control center containing quick toggles, audio sink selectors, and MPRIS media player.
- **`WallpaperManager.qml`**: Visual wallpaper selector with thumbnail grid and dynamic theme trigger.
