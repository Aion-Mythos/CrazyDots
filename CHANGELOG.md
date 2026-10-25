# Changelog

All notable changes to the **crazydots** desktop shell project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### [0.6.0] - 2026-10-25 - Milestone M5: Application Launcher

#### Added
- Native modular Application Launcher modal in `shell/panels/Launcher.qml`:
  - Discovers installed desktop applications directly via `Quickshell.DesktopEntries`.
  - Scored search engine matching application names, generic descriptions, comments, IDs, and keywords.
  - Case-insensitive filtering and alphabetical sorting honoring `Config.launcherMaxResults`.
  - Immediate keyboard focus on opening with arrow key navigation (`Up`/`Down`), launch activation (`Enter`/`Return`), and dismissal (`Escape`).
  - Safe desktop entry execution via `DesktopEntry.execute()` with duplicate launch prevention cooldown timer.
  - Application icon rendering with `Quickshell.Widgets.IconImage` and fallback Nerd Font application glyphs.
  - Interactive item delegates with hover, focus, and selection states.
- Modal layer-shell input architecture in `shell/ScreenCanvas.qml`:
  - Centered modal launcher dialog with smooth spring scale and opacity animations.
  - Fullscreen dismissible backdrop scrim (`color: Theme.alpha("#000000", 0.45)`) that closes the launcher on outside clicks.
  - Dynamic `WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive` when active, transitioning to `WlrKeyboardFocus.None` when idle.
  - Dynamic input masking switching between `launcherMask` when active and `emptyMask` when idle, guaranteeing 100% click-through to apps when closed.
  - Multi-monitor targeting matching `Hyprland.focusedMonitor`.
- Extended IPC interface in `shell/Main.qml`:
  - `openLauncher()`, `closeLauncher()`, `toggleLauncher()`, and `isLauncherOpen()`.
  - Integrated launcher button on desktop bar (`Bar.qml: onLauncherTriggered`).
- Automated test suite `shell/TestLauncher.qml` (29 passing assertions) covering application discovery, filtering, selection, signal emissions, focus transitions, and icon resolution.
- Updated `tests/run_tests.sh` to execute M1 through M5 suites, achieving 140 passing assertions with 0 errors.

### [0.5.0] - 2026-10-25 - Milestone M4: Desktop Bar

#### Added
- Dedicated layer-shell Desktop Bar window in `shell/panels/Bar.qml`:
  - Operates as a per-monitor `PanelWindow` on `WlrLayer.Top` anchored to screen edge (`top` or `bottom`).
  - Claims precise layer-shell exclusive zone (`WlrLayershell.exclusiveZone`) for Hyprland window tiling reservation.
  - Dynamic input masking (`mask: Region { item: barCard }`) guaranteeing that pointer clicks in floating margins pass through to underlying windows.
  - Supports configurable heights, docked edge or floating island modes, and dynamic theme opacity.
- Modular bar sub-widgets in `shell/panels/bar/`:
  - `BarPill.qml`: Reusable capsule container with hover, press, click, and mouse wheel handling.
  - `Workspaces.qml`: Hyprland workspace indicator with elastic spring pill animations, special workspace filtering, ascending ID ordering, click activation, and mouse wheel cycling.
  - `ActiveWindow.qml`: Active window title widget with smooth elision, status dot, and graceful empty-state handling.
  - `ClockWidget.qml`: Digital clock and calendar date widget with jitter-free monospace formatting.
  - `AudioWidget.qml`: Pipewire audio meter with dynamic volume glyphs, mute toggling on click, and 5% scroll step adjustments.
  - `BatteryWidget.qml`: UPower battery indicator with charging/discharging states, capacity thresholds, low-battery warning, and automatic collapse on desktop systems.
  - `TrayWidget.qml`: StatusNotifierItem (SNI) system tray with icon rendering via `Quickshell.Widgets.IconImage` and left/right click actions.
- Multi-monitor bar instantiation coordinated in `shell/Main.qml` via `Variants`.
- Extended IPC handler with `getBarPosition()`, `setBarPosition()`, `isBarFloating()`, and `setBarFloating()`.
- Automated test suite `shell/TestBar.qml` (32 passing assertions) covering geometry, anchoring, widgets, and dynamic responsiveness.
- Updated `tests/run_tests.sh` with M4 verification, bringing total test suite assertions to 111 passing tests with 0 errors.

### [0.4.0] - 2026-10-25 - Milestone M3: Quickshell Entry Point & Shell Base

#### Added
- Primary Quickshell entry point in `shell/shell.qml` (`ShellRoot`) with threaded scene graph rendering pragmas.
- Central shell coordinator in `shell/Main.qml`:
  - Multi-monitor variant instantiation via `Quickshell.screens` and `Variants`.
  - Secure `Quickshell.Io.IpcHandler` exposing `ping`, `getTheme`, `setTheme`, `reloadConfig`, `getScreens`, and `getScreenCount`.
  - Global service mounting for `ThemeEngine` and singletons.
- Screen canvas in `shell/ScreenCanvas.qml`:
  - Permanent fullscreen `PanelWindow` spanning each connected monitor with `ExclusionMode.Ignore`.
  - Dynamic boolean input region masking (`mask: Region`) ensuring 100% pass-through to desktop applications when idle.
  - Idle keyboard focus set to `WlrKeyboardFocus.None` to prevent stealing focus from active windows.
  - Designated anchor slots prepared for Bar (M4), Launcher (M5), and Dashboard (M7).
- Reusable base components in `shell/components/`:
  - `StyledRect.qml`: Themed container with elevated modes, borders, and smooth `ColorAnimation`.
  - `StyledText.qml`: Themed text with monospace/sans switching and high-contrast semantic bindings.
  - `ButtonBase.qml`: Accessible button with hover, pressed, and Tab focus keyboard states.
- Automated test suite `shell/TestBaseComponents.qml` and live IPC verification in `tests/run_tests.sh` (79 total passing assertions).
- Cryptographic commit signing configured via user GPG key (`3BB1686D906FB796`).

### [0.3.0] - 2026-10-25 - Milestone M2: Configuration & Persistence Service

#### Added
- Centralized configuration singleton in `shell/Config.qml`:
  - Granular, reactive properties for bar, theme, wallpaper, animations, launcher, and dashboard preferences.
  - Strict input validation and boundary clamping for all user configuration fields.
  - Safe recovery for missing configuration files and malformed JSON syntax with diagnostic warnings.
  - Debounced (`saveDebounced`), atomic disk writes (`atomicWrites: true`) via `Quickshell.Io.FileView` preventing I/O spamming and data corruption.
  - Decoupled persistent user settings from dynamic wallpaper color palettes, synchronizing with `Theme` without circular dependencies.
- Registered `Config` singleton in `shell/qmldir`.
- Added automated test harness `shell/TestConfig.qml` with 32 passing assertions covering defaults, validation, runtime updates, round-trip persistence, and reset handling.
- Updated `tests/run_tests.sh` to execute both M1 and M2 test suites under `qmllint` and Quickshell.

### [0.2.0] - 2026-10-25 - Milestone M1: Design Tokens & Theme Engine

#### Added
- Centralized design tokens in `shell/Tokens.qml`:
  - Standard spacing hierarchy (`spaceXxs` through `spaceXxl`).
  - Corner radii (`radiusXs` through `radiusFull`).
  - Typography scale with monospace (`JetBrainsMono Nerd Font`) and sans-serif font families.
  - Deterministic animation durations and expressive cubic Bezier curves (`springCurve`, `exitCurve`, `standardCurve`).
- Central semantic theme singleton in `shell/Theme.qml`:
  - Reactive semantic color properties (`background`, `surface`, `surfaceElevated`, `foreground`, `mutedForeground`, `accent`, `accentSecondary`, `border`, `selection`, `success`, `warning`, `error`, `shadow`).
  - Color math helpers: `alpha()`, `lighten()`, `darken()`, and `mix()`.
  - Built-in theme dictionary with instant in-memory switching.
  - Matugen JSON palette adapter mapping Material 3 scheme keys to crazydots tokens.
  - Native `ColorQuantizer` fallback algorithm synthesizing dark, high-contrast palettes from wallpaper colors without external tools.
- Curated 8 static theme files under `themes/`:
  - `themes/crazydots-default.json`: Signature obsidian and electric cyan palette.
  - `themes/catppuccin-mocha.json`
  - `themes/tokyo-night.json`
  - `themes/nord.json`
  - `themes/gruvbox-dark.json`
  - `themes/dracula.json`
  - `themes/rose-pine.json`
  - `themes/everforest.json`
- Built headless service `shell/services/ThemeEngine.qml` watching `palette.json` and managing wallpaper extraction.
- Created test harness `shell/TestThemeEngine.qml` and test runner `tests/run_tests.sh` with 29 passing automated assertions.
- Unified canonical milestone numbering (M0–M9) across `SPEC.md`, `README.md`, `AGENTS.md`, `CHANGELOG.md`, and `docs/ARCHITECTURE.md`.

### [0.1.0] - 2026-10-25 - Milestone M0: Repository Foundation & Specification

#### Added
- Initialized local Git repository on `main` branch.
- Created root governance and specification files:
  - `AGENTS.md`: Operating principles, API verification rules, and git commit guidelines for development agents.
  - `SPEC.md`: Complete engineering specification covering architecture, dependencies, boundaries, and panel state lifecycles.
  - `LICENSE`: Full GNU General Public License v3.0 text (GPL-3.0-or-later).
  - `packages.txt`: Tiered package dependency manifest across Required, Recommended, Optional, and Dev categories.
  - `.gitignore`: Ignore rules for Qt Quick caches, QML compiler outputs, editor files, and temporary test artifacts.
  - `install.sh`: Safe installation script with `--dry-run`, directory creation, and non-destructive symlink management.
  - `uninstall.sh`: Clean removal script targeting crazydots configurations without affecting other desktop files.
- Added comprehensive documentation suite under `docs/`:
  - `docs/ARCHITECTURE.md`: Crazydots internal architecture, pure QML/JS stack, state management, and layer-shell integration.
  - `docs/COMPONENTS.md`: Catalog of core components, properties, signals, and styling principles.
  - `docs/CONFIGURATION.md`: Centralized configuration schema (`config.json`), validation rules, and persistence API.
  - `docs/DEPENDENCIES.md`: Dependency tier analysis, system requirements, verification procedures, and fallback modes.
  - `docs/DEVELOPMENT.md`: Developer setup, isolated testing with `quickshell -p ~/crazydots/shell`, and linting rules.
  - `docs/TESTING.md`: Verification plan including static checks (`qmllint`), component testbeds, and safety boundaries.
  - `docs/TROUBLESHOOTING.md`: Common diagnostic scenarios, Wayland socket checks, and layer-shell grab handling.
  - `docs/SECURITY.md`: Process execution security, argument escaping, and D-Bus boundaries.
- Preserved existing `ARCHITECTURE.md` as reference analysis of Caelestia.
