# crazydots

> A modular, native Quickshell desktop shell for Hyprland on Arch Linux, written primarily in QML and JavaScript.

**crazydots** is a standalone, lightweight, fluid desktop environment interface for the Vexilion ecosystem. It replaces disconnected bars and launchers with a unified, cohesive desktop shell rendered by Quickshell.

---

## Features

- **Cohesive Desktop Bar**: Workspaces, active window title, system tray (StatusNotifierItem), clock, battery, network status, quick toggles, and PipeWire audio volume.
- **Native Application Launcher**: Fast fuzzy search across XDG desktop entries (`DesktopEntries`) with keyboard navigation, full unconstrained scrolling, and smooth entrance transitions.
- **Dedicated Theme Manager**: Modal manager dialog (620×520) with active palette swatches, 8 curated theme presets, and dynamic wallpaper palette generation.
- **Contextual Popovers**: Compact drawers anchored next to bar controls:
  - **Connectivity**: NetworkManager Wi-Fi status, scan list, radio toggle, and truthful Bluetooth daemon state.
  - **Volume**: PipeWire master output slider, mute toggle, microphone level, and mic mute toggle.
  - **Brightness**: Hardware backlight slider (`brightnessctl`) with percentage, device name, and unavailable state handling.
  - **Quick Toggles**: Unified capsule with 2×2 quick toggles, mini-sliders, and direct appearance shortcuts.
- **Wallpaper Gestures**: Double-click bare wallpaper on left half for Wallpaper Manager, right half for Theme Manager.
- **Dynamic Color Engine**: Matugen integration for wallpaper-derived Material You palettes, with built-in fallbacks (Catppuccin, Tokyo Night, Nord, Gruvbox) and Quickshell's native `ColorQuantizer`.
- **Wallpaper Manager**: In-shell wallpaper browser, previewer, and instant theme application.
- **Corner Dashboard & Quick Settings**: Fast-access controls for audio outputs, media playback (MPRIS), and system status.
- **Pure QML & JS Architecture**: Zero custom C++ plugins or binary dependencies required.
- **Zero-Resize Layer Surfaces**: Uses fullscreen static layer-shell surfaces with dynamic boolean input masking (`Intersection.Xor` and `Intersection.Subtract`), eliminating Wayland buffer reconfiguration stutter.

---

## System Requirements

- **OS**: Arch Linux (or compatible Linux distribution)
- **Compositor**: Hyprland (>= 0.56.0)
- **Host**: Quickshell (>= 0.3.2)
- **Qt**: Qt 6.12+ (`qt6-declarative`, `qt6-base`, `qt6-svg`)
- **Audio Server**: PipeWire & WirePlumber
- **Network**: NetworkManager (`nmcli`)
- **Backlight**: `brightnessctl` (optional, for display brightness)
- **Terminal**: Ghostty (configurable to any terminal emulator)
- **Dynamic Theming**: Matugen (optional, with native `ColorQuantizer` fallback)

---

## Project Structure

```
crazydots/
├── AGENTS.md                  # Development guidelines and agent operating instructions
├── README.md                  # Project overview and quickstart
├── SPEC.md                    # Engineering specification
├── CHANGELOG.md               # Version history and milestone log
├── LICENSE                    # GNU General Public License v3.0 (GPL-3.0-or-later)
├── install.sh                 # Safe installer script with dry-run support
├── uninstall.sh               # Safe removal script
├── packages.txt               # Tiered dependency manifest
├── assets/                    # Assets and default vector wallpapers
│   └── wallpapers/            # Bundled SVG wallpapers
├── docs/                      # Technical documentation
│   ├── ARCHITECTURE.md        # Crazydots internal architecture and pure QML stack
│   ├── COMPONENTS.md          # Component catalog and design system
│   ├── CONFIGURATION.md       # Configuration schema and defaults
│   ├── DEPENDENCIES.md        # Detailed dependency analysis and verification
│   ├── DEVELOPMENT.md         # Developer guide and coding conventions
│   ├── TESTING.md             # Testing and verification strategy
│   ├── TROUBLESHOOTING.md     # Diagnostic procedures and common fixes
│   └── SECURITY.md            # Security policy and process execution
├── shell/                     # Quickshell QML shell source code
│   ├── components/            # Reusable primitives (StyledRect, StyledText, ButtonBase)
│   ├── panels/                # Desktop bar, launcher, dashboard, wallpaper, theme panels
│   │   ├── bar/               # Bar pills, clock, workspaces, audio, battery, tray
│   │   └── popovers/          # Contextual popovers (Connectivity, Volume, Brightness, QuickToggles)
│   ├── services/              # ThemeEngine, HyprlandService, TerminalService, NetworkService, BrightnessService
│   ├── Config.qml             # Centralized configuration & persistence singleton
│   ├── Theme.qml              # Centralized theme engine singleton
│   ├── Tokens.qml             # Centralized design tokens singleton
│   ├── ScreenCanvas.qml       # Per-monitor static layer-shell window & modal coordinator
│   └── Main.qml               # Shell coordinator & IPC handler
├── tests/                     # Automated test suites
│   └── run_tests.sh           # End-to-end test runner (309 assertions across 12 suites)
└── themes/                    # Built-in static JSON themes (8 presets)
```

---

## Canonical Milestone Roadmap

The crazydots engineering lifecycle executes in sequential milestones:
- **M0**: Repository Foundation & Specification
- **M1**: Design Tokens & Theme Engine
- **M2**: Configuration & Persistence Service
- **M3**: Quickshell Entry Point & Shell Base
- **M4**: Desktop Bar
- **M5**: Application Launcher
- **M6**: Wallpaper Manager & Dynamic Color Engine
- **M7**: Corner Dashboard & Quick Settings
- **M8**: Hyprland & Ghostty Integration
- **M9**: Verification, Documentation & Polish
- **M10**: Interactive Popovers & Desktop UX Fixes

---

## Running in Isolated Development Mode

crazydots is developed without interfering with your existing desktop configuration or currently running shell.

To run the shell in isolation:

```bash
quickshell -p ~/crazydots/shell
```

To run the complete automated test suite (309 assertions + static analysis):

```bash
./tests/run_tests.sh
```

To run QML static analysis alone:

```bash
qmllint shell/**/*.qml
```

### IPC Controls

When crazydots is running, you can inspect and control the shell via Quickshell IPC:

```bash
# Toggle modals
quickshell ipc -p ~/crazydots/shell call crazydots toggleLauncher
quickshell ipc -p ~/crazydots/shell call crazydots toggleDashboard
quickshell ipc -p ~/crazydots/shell call crazydots toggleThemeManager
quickshell ipc -p ~/crazydots/shell call crazydots toggleWallpaperManager

# Contextual popovers
quickshell ipc -p ~/crazydots/shell call crazydots togglePopover "quickToggles"
quickshell ipc -p ~/crazydots/shell call crazydots togglePopover "connectivity"
quickshell ipc -p ~/crazydots/shell call crazydots togglePopover "volume"
quickshell ipc -p ~/crazydots/shell call crazydots togglePopover "brightness"

# Network & Hardware Brightness
quickshell ipc -p ~/crazydots/shell call crazydots toggleWifi
quickshell ipc -p ~/crazydots/shell call crazydots setBrightness 80

# Terminal actions
quickshell ipc -p ~/crazydots/shell call crazydots launchTerminal

# Theming & Wallpaper
quickshell ipc -p ~/crazydots/shell call crazydots setTheme nord
quickshell ipc -p ~/crazydots/shell call crazydots setWallpaper ~/Pictures/wall.png fit

# Hyprland Compositor Actions
quickshell ipc -p ~/crazydots/shell call crazydots focusWorkspace 2
```

---

## License

crazydots is licensed under the **GNU General Public License v3.0 or later** ([GPL-3.0-or-later](LICENSE)).
