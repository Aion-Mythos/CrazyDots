# crazydots — Troubleshooting & Diagnostics

This document outlines diagnostic steps and solutions for common issues when running or developing crazydots.

---

## 1. Diagnostics Workflow

### 1.1 Checking Quickshell Logs
Run Quickshell in verbose mode to capture Qt Quick scene graph and QML runtime output:
```bash
quickshell -v -p /home/aion/crazydots/shell
```
Or for debug-level logs:
```bash
quickshell -vv -p /home/aion/crazydots/shell
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
