# Changelog

All notable changes to the **crazydots** desktop shell project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

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
