# crazydots — Configuration & Persistence

crazydots maintains persistent configuration in `~/.config/crazydots/config.json`. The configuration service (`Config.qml`) loads, validates, applies fallbacks, and safely persists intentional changes.

---

## 1. Configuration File Location
- File: `~/.config/crazydots/config.json`
- Fallback: Hardcoded defaults inside `Config.qml` ensure the shell starts reliably even if `config.json` is missing or corrupted.

---

## 2. Configuration Schema

```json
{
  "version": 1,
  "bar": {
    "position": "top",
    "height": 44,
    "floating": true,
    "margin": 8,
    "showWorkspaces": true,
    "showActiveTitle": true,
    "showTray": true,
    "showClock": true,
    "showBattery": true,
    "showAudio": true
  },
  "theme": {
    "name": "matugen",
    "mode": "dark",
    "accentColor": "#89b4fa",
    "blur": true,
    "opacity": 0.88
  },
  "wallpaper": {
    "current": "",
    "directory": "~/Pictures/Wallpapers",
    "mode": "fill"
  },
  "animations": {
    "enabled": true,
    "speed": 1.0,
    "expressiveBounce": true
  },
  "launcher": {
    "shortcut": "SUPER",
    "itemHeight": 56,
    "maxResults": 8
  },
  "dashboard": {
    "corner": "top-right",
    "width": 380,
    "height": 520
  },
  "terminal": {
    "command": "ghostty",
    "appId": "com.mitchellh.ghostty"
  }
}
```

---

## 3. Terminal & Hyprland Integration Settings

### 3.1 Terminal Configuration (`terminal`)
- `command`: Name of the binary or executable path to spawn when launching terminal actions (default: `"ghostty"`).
- `appId`: Desktop entry application ID used for desktop file execution and icon resolution (default: `"com.mitchellh.ghostty"`).

### 3.2 Hyprland Keybinding Snippets (Manual Integration)
crazydots preserves user autonomy and never modifies your active `~/.config/hypr/hyprland.lua` or `hyprland.conf`. To integrate crazydots with Hyprland hotkeys, add the following keybinding definitions to your Hyprland configuration:

```ini
# crazydots Desktop Shell Hotkeys
bind = $mainMod, SPACE, exec, quickshell ipc -p ~/crazydots/shell call crazydots toggleLauncher
bind = $mainMod, N, exec, quickshell ipc -p ~/crazydots/shell call crazydots togglePopover "quickToggles"
bind = $mainMod, B, exec, quickshell ipc -p ~/crazydots/shell call crazydots toggleDashboard
bind = $mainMod, T, exec, quickshell ipc -p ~/crazydots/shell call crazydots toggleThemeManager
bind = $mainMod, W, exec, quickshell ipc -p ~/crazydots/shell call crazydots toggleWallpaperManager
bind = $mainMod, RETURN, exec, quickshell ipc -p ~/crazydots/shell call crazydots launchTerminal

# Contextual Popover Direct Triggers
bind = $mainMod CTRL, N, exec, quickshell ipc -p ~/crazydots/shell call crazydots togglePopover "connectivity"
bind = $mainMod CTRL, V, exec, quickshell ipc -p ~/crazydots/shell call crazydots togglePopover "volume"
bind = $mainMod CTRL, B, exec, quickshell ipc -p ~/crazydots/shell call crazydots togglePopover "brightness"
```

---

## 4. Wallpaper Gestures
The bare desktop surface (`WallpaperSurface.qml`) listens for mouse double-clicks on the desktop background:
- **Left half double-click (`x < screen.width / 2`)**: Launches the Wallpaper Manager.
- **Right half double-click (`x >= screen.width / 2`)**: Launches the Theme Manager.
- Application windows resting above the background layer naturally receive their own clicks, preventing accidental triggers when windows are focused.

---

## 5. IPC Reference

| Method | Arguments | Returns | Description |
|---|---|---|---|
| `ping` | none | `"pong"` | Probes shell responsiveness |
| `toggleLauncher` | none | `boolean` | Toggles application launcher modal |
| `openLauncher` | none | `boolean` | Opens application launcher |
| `closeLauncher` | none | `boolean` | Closes application launcher |
| `isLauncherOpen` | none | `boolean` | Returns launcher visibility state |
| `toggleDashboard` | none | `boolean` | Toggles corner dashboard modal |
| `openDashboard` | none | `boolean` | Opens corner dashboard |
| `closeDashboard` | none | `boolean` | Closes corner dashboard |
| `isDashboardOpen` | none | `boolean` | Returns dashboard visibility state |
| `toggleThemeManager`| none | `boolean` | Toggles dedicated Theme Manager modal |
| `openThemeManager` | none | `boolean` | Opens dedicated Theme Manager |
| `closeThemeManager`| none | `boolean` | Closes dedicated Theme Manager |
| `isThemeManagerOpen`| none | `boolean` | Returns Theme Manager visibility state |
| `toggleWallpaperManager` | none | `boolean` | Toggles wallpaper manager drawer |
| `openWallpaperManager` | none | `boolean` | Opens wallpaper manager |
| `closeWallpaperManager`| none | `boolean` | Closes wallpaper manager |
| `isWallpaperManagerOpen`| none | `boolean` | Returns wallpaper manager visibility state |
| `togglePopover` | `name: string` | `boolean` | Toggles contextual popover (`"connectivity"`, `"volume"`, `"brightness"`, `"quickToggles"`) |
| `openPopover` | `name: string` | `boolean` | Opens specific popover |
| `closePopover` | none | `boolean` | Closes any open popover |
| `getActivePopover` | none | `string` | Returns name of currently open popover or `""` |
| `isNetworkAvailable`| none | `boolean` | Checks if `nmcli` backend is present |
| `getWifiEnabled` | none | `boolean` | Checks if Wi-Fi radio is enabled |
| `toggleWifi` | none | `boolean` | Toggles Wi-Fi radio on/off |
| `getConnectedSsid` | none | `string` | Returns active Wi-Fi SSID |
| `rescanWifi` | none | `boolean` | Triggers background Wi-Fi network rescan |
| `isBrightnessAvailable`| none | `boolean` | Checks if `brightnessctl` is supported |
| `getBrightness` | none | `number` | Returns current backlight percentage (0-100) |
| `setBrightness` | `pct: number` | `boolean` | Sets backlight percentage with clamp validation |
| `launchTerminal` | none | `boolean` | Launches Ghostty terminal emulator |
| `isHyprlandAvailable`| none | `boolean` | Returns Hyprland IPC connection state |

---

## 6. Validation and Safety Rules
1. **Never Crash on Bad Data**: If a string is provided where an integer is expected, `Config.qml` falls back to the default value.
2. **Debounced Disk Writes**: Runtime changes (e.g., sliding volume or adjusting opacity) are debounced so the file is not written on every animation frame.
3. **Atomic Replacement**: Configuration saving writes to a temporary file (`config.json.tmp`) before moving to `config.json`, preventing data corruption during unexpected shutdowns.
