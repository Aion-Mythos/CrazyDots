# crazydots

> A modular, native Quickshell desktop shell for Hyprland on Arch Linux, written primarily in QML and JavaScript.

**crazydots** is a standalone, lightweight, fluid desktop environment interface for the Vexilion ecosystem. It replaces disconnected bars and launchers with a unified, cohesive desktop shell rendered by Quickshell.

---

## Features

- **Cohesive Desktop Bar**: Workspaces, active window title, system tray (StatusNotifierItem), clock, battery, and PipeWire audio volume.
- **Native Application Launcher**: Fast fuzzy search across XDG desktop entries (`DesktopEntries`) with keyboard navigation and smooth entrance transitions.
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
- **Qt**: Qt 6.12+ (`qt6-declarative`, `qt6-base`)
- **Terminal**: Ghostty
- **Dynamic Theming**: Matugen (optional, with native fallback)

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
├── docs/                      # Technical documentation
│   ├── ARCHITECTURE.md        # Crazydots internal architecture and pure QML stack
│   ├── COMPONENTS.md          # Component catalog and design system
│   ├── CONFIGURATION.md       # Configuration schema and defaults
│   ├── DEPENDENCIES.md        # Detailed dependency analysis and verification
│   ├── DEVELOPMENT.md         # Developer guide and coding conventions
│   ├── TESTING.md             # Testing and verification strategy
│   ├── TROUBLESHOOTING.md     # Diagnostic procedures and common fixes
│   └── SECURITY.md            # Security policy and sub-process execution
├── shell/                     # Quickshell QML shell source code (Milestones M1-M7)
├── themes/                    # Static color schemes and Matugen templates (Milestone M1)
├── wallpapers/                # Default wallpaper collection
└── config/                    # Hyprland and Ghostty integration snippets (Milestone M8)
```

---

## Running in Isolated Development Mode

crazydots is developed without interfering with your existing desktop configuration or currently running shell.

To test the shell in isolation:

```bash
quickshell -p ~/crazydots/shell
```

To run QML static analysis:

```bash
qmllint shell/**/*.qml
```

---

## License

crazydots is licensed under the **GNU General Public License v3.0 or later** ([GPL-3.0-or-later](LICENSE)).
