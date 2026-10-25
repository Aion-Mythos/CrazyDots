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
  }
}
```

---

## 3. Validation and Safety Rules
1. **Never Crash on Bad Data**: If a string is provided where an integer is expected, `Config.qml` falls back to the default value.
2. **Debounced Disk Writes**: Runtime changes (e.g., sliding volume or adjusting opacity) are debounced so the file is not written on every animation frame.
3. **Atomic Replacement**: Configuration saving writes to a temporary file (`config.json.tmp`) before moving to `config.json`, preventing data corruption during unexpected shutdowns.
