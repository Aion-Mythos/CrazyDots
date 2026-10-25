# crazydots — Dependencies & System Requirements

This document tracks all external dependencies, verification status, and fallback mechanisms for crazydots on Arch Linux.

---

## 1. Dependency Analysis Table

| Package | Status on Host | Purpose | Fallback if Missing |
| :--- | :--- | :--- | :--- |
| `quickshell-git` | Installed (`0.3.2`) | Shell host engine, Wayland layer surfaces, service bindings | None (Core Requirement) |
| `hyprland` | Installed (`0.56.2`) | Wayland compositor, window management, global shortcuts | None (Core Requirement) |
| `qt6-declarative` | Installed (`6.12.0`) | Qt Quick and QML engine | None (Core Requirement) |
| `qt6-base` | Installed (`6.12.0`) | Qt 6 core libraries | None (Core Requirement) |
| `qt6-svg` | Installed (`6.12.0`) | Vector graphics and SVG wallpaper rendering | Vector wallpapers fall back to Theme.background |
| `pipewire` | Installed | Audio server and stream routing | None (Audio widgets hide or display disconnected) |
| `wireplumber` | Installed | PipeWire session manager | Volume controls unavailable |
| `ghostty` | Installed (`1.3.1`) | Default terminal emulator | Shell launches `$TERMINAL` or `xterm` |
| `matugen` | In official repos (`extra`) | Dynamic Material You palette generator | Falls back to built-in static themes or `ColorQuantizer` |
| `qmllint` | Installed (`6.12.0`) | Static analysis for QML source files | Development only |
| `ttf-jetbrains-mono-nerd` | Installed | Typography and glyphs | System monospace font fallback |
| `brightnessctl` | Optional | Screen backlight hardware control | Brightness slider hidden |
| `grim` / `slurp` | Optional | Screenshot and region selection | Screenshot utility triggers warning |
| `wl-clipboard` | Optional | Wayland clipboard history and copying | Clipboard functions disabled |

---

## 2. API Verification Against Installed Quickshell 0.3.2

Verified through `/usr/lib/qt6/qml/Quickshell/**/*.qmltypes`:
- **`Quickshell.Hyprland`**: `Hyprland` singleton provides `workspaces`, `monitors`, `toplevels`, `activeToplevel`, `focusedWorkspace`, `focusedMonitor`, and `dispatch()`.
- **`Quickshell.Hyprland.GlobalShortcut`**: Protocol for registering direct compositor keybindings without spawning sub-processes.
- **`Quickshell.Io.Process`**: Asynchronous process execution accepting string arrays (`command: ["cmd", "arg"]`), preventing shell injection vulnerabilities.
- **`Quickshell.Io.IpcHandler`**: Native IPC mechanism allowing CLI commands to trigger shell functions (`qs ipc -p ... call <target> <method>`).
- **`Quickshell.DesktopEntries`**: Standard XDG `.desktop` file parser and application list singleton (`DesktopEntries.applications`).
- **`Quickshell.Services.Pipewire`**: Built-in `Pipewire` audio sink and volume bindings.
- **`Quickshell.Services.Mpris`**: MPRIS media player tracking (`Mpris.players`).
- **`Quickshell.Services.SystemTray`**: StatusNotifierItem tray icons and context menus.
- **`Quickshell.Services.UPower`**: Battery monitoring singleton (`UPower.displayDevice`).
