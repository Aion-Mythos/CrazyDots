# crazydots — Troubleshooting & Diagnostics

This document outlines diagnostic steps and solutions for common issues when running or developing crazydots.

---

## 1. Diagnostics Workflow

### 1.1 Checking Quickshell Logs
Run Quickshell in verbose mode to capture Qt Quick scene graph and QML runtime output:
```bash
quickshell -v -p ~/crazydots/shell
```
Or for debug-level logs:
```bash
quickshell -vv -p ~/crazydots/shell
```

### 1.2 Inspecting Active Quickshell Instances
To check running Quickshell instances:
```bash
quickshell list --all
```

---

## 2. Common Issues & Solutions

### 2.1 Clicks Not Reaching Desktop Windows
- **Cause**: The fullscreen layer-shell `mask: Region` is either missing or incorrectly configured.
- **Fix**: Verify that the root region of the `PanelWindow` uses `intersection: Intersection.Xor` and covers the full screen bounds, while sliding panels use `Intersection.Subtract`.

### 2.2 Shell Fails to Start with Module Import Errors
- **Cause**: Outdated Quickshell version or missing Qt6 declarative libraries.
- **Fix**: Verify that `quickshell` is at least version `0.3.2` (`quickshell --version`) and that `qt6-declarative` is installed.

### 2.3 Matugen Colors Not Updating
- **Cause**: `matugen` is not installed or the generated JSON palette path is incorrect.
- **Fix**: Run `which matugen` to verify installation. If uninstalled, install via `pacman -S matugen` or configure `Theme.qml` to use a built-in static theme.

### 2.4 Hyprland Global Shortcuts Not Firing
- **Cause**: Keybind not bound to the `global` dispatcher in Hyprland configuration.
- **Fix**: In your Hyprland configuration, verify the binding syntax:
  ```
  bind = SUPER, Space, global, crazydots:launcher
  ```

### 2.5 Hyprland Lua Configuration Dispatching
- **Cause**: Hyprland 0.56.2 with Lua configuration interprets raw socket strings as Lua expressions (`return hl.dispatch(...)`).
- **Fix**: crazydots uses native `HyprlandWorkspace.activate()` for workspace switching, bypassing string evaluation entirely. For arbitrary dispatcher commands via IPC, verify that the string matches the syntax expected by your Hyprland configuration (e.g. `hl.dsp.no_op()`).

### 2.6 Terminal Emulator Launch Configuration
- **Cause**: Preferred terminal (Ghostty) binary not found on `$PATH` or custom terminal desired.
- **Fix**: Configure `terminal.command` and `terminal.appId` in `~/.config/crazydots/config.json`, or dynamically update via IPC:
  ```bash
  quickshell ipc -p ~/crazydots/shell call crazydots setTerminalCommand alacritty
  quickshell ipc -p ~/crazydots/shell call crazydots setTerminalAppId org.alacritty
  ```
