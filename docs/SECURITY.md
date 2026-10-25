# crazydots — Security Policy & Guidelines

This document details security boundaries, command execution policies, input masking, and external process safety in crazydots.

---

## 1. Subprocess Execution Guidelines

### 1.1 Array-Based Arguments
Never concatenate un-sanitized user input into a raw shell string (e.g., `sh -c "command " + userInput`).
Always use `Quickshell.Io.Process` with structured array-based arguments:
```qml
Process {
    command: ["ghostty", "-e", "btop"]
}
```
This guarantees that arguments are passed directly through `execvp()` without shell word-splitting or command injection vulnerabilities.

### 1.2 Terminal Emulator Invocation
- **Primary Route**: crazydots prioritizes `DesktopEntry.execute()` via `DesktopEntries.applications` matching the configured `terminalAppId` (`com.mitchellh.ghostty`).
- **Secondary Route**: Direct binary execution via `Process { command: [Config.terminalCommand].concat(args) }`.
- **Validation**: `Config.terminalCommand` is strictly validated against `/^[a-zA-Z0-9_\-\./]+$/`, rejecting whitespace, newlines, semicolons, pipes, and shell metacharacters. Multi-token or arbitrary shell strings cannot be injected via terminal settings.

---

## 2. Hyprland Dispatcher Hardening

### 2.1 Native Quickshell API Priority
Where Quickshell provides native models or methods, crazydots uses them instead of raw dispatcher strings. Workspace activation always uses `HyprlandWorkspace.activate()`, which directly triggers compositor workspace focus without socket string parsing or Lua syntax mismatch errors.

### 2.2 Strict Dispatcher Allowlist
The `HyprlandService.dispatch()` proxy enforces an explicit allowlist of known-safe operations:
- **`workspace`**: Validated for positive integer IDs (`/^[1-9][0-9]*$/`), relative shifts (`/^(e|m|r)[+-]([1-9][0-9]*)?$/`), named workspaces (`/^name:[a-zA-Z0-9_\-\.]+$/`), or keywords (`empty`, `previous`).
- **`movetoworkspace`** & **`movetoworkspacesilent`**: Validated against workspace ID, relative shift, or name patterns.
- **`focuswindow`**: Validated for window addresses (`/^(address:)?0x[0-9a-fA-F]+$/`) or class/title selectors.
- **`closewindow`**: Validated for window addresses (`/^(address:)?0x[0-9a-fA-F]+$/`).
- **`killactive`**: Zero arguments permitted.
- **`fullscreen`**: Zero arguments or explicit mode numbers (`0`, `1`, `2`, `monocle`).
- **`togglefloating`**: Zero arguments or explicit window address.
- **`no_op`** / **`hl.dsp.no_op()`**: Connectivity verification testing.

### 2.3 Injection Prevention & Truthful Errors
- Any dispatcher request containing control characters or shell metacharacters (`\n`, `\r`, `;`, `&`, `|`, `` ` ``, `$`, `>`, `<`) is immediately rejected.
- Dangerous operations (including `exec`, `spawn`, `exit`, `kill`, `pass`, `submap`) are rejected and logged.
- All dispatcher invocations are wrapped in `try ... catch` blocks and return truthful boolean results (`true` on success, `false` on rejection or compositor error).

---

## 3. Filesystem & Configuration Persistence

### 3.1 Atomic Disk Persistence
Configuration persistence via `Config.qml` uses `Quickshell.Io.FileView` configured with `atomicWrites: true`. File modifications are staged to a temporary file before atomic renaming, preventing file truncation or corruption if the system loses power or terminates unexpectedly.

### 3.2 Non-Destructive Error Recovery
If `~/.config/crazydots/config.json` is missing or contains malformed JSON:
- In-memory properties are safely populated from default schema values.
- The corrupt or unreadable file on disk is **never overwritten** or deleted automatically during load.
- A `validationWarning` signal is emitted for inspection and logging.

### 3.3 Setting Isolation
Updating one configuration domain (e.g. switching themes or selecting a wallpaper) serializes the full schema and preserves all unrelated preferences (bar position, margins, animations, terminal preferences).

### 3.4 Safe Asset Handling
- Wallpaper discovery utilizes `find` with structured argument arrays across allowlisted directories.
- Paths containing spaces and special characters are handled cleanly via `Qt.resolvedUrl()`.
- Assets paths are resolved dynamically without hardcoded usernames or machine-specific locations.

---

## 4. Input Privacy & Focus Isolation

### 4.1 Pass-Through Input Masking
- When idle (no modals active), `ScreenCanvas.qml` assigns `mask: Region {}` (empty mask) and `WlrLayershell.keyboardFocus: WlrKeyboardFocus.None`. Pointer events and keystrokes pass straight through to desktop windows without shell interception.
- Desktop bar margins around floating islands are excluded via `Bar.qml` `mask: Region { item: barCard }`, allowing click-through to underlying application windows in margin areas.

### 4.2 Modal Focus Scoping
- Keyboard focus is elevated to `WlrKeyboardFocus.Exclusive` **only** when an interactive modal (Launcher, Wallpaper Manager, or Dashboard) is explicitly open.
- Dismissing the modal immediately restores `keyboardFocus: None` and collapses the input region mask.

### 4.3 Credentials & Secrets
- crazydots never requests, stores, or logs passwords, private keys, or credentials.
- Privilege elevation (if required by external tools) is delegated entirely to system polkit agents.

---

## 5. Network & Hardware Control Subprocess Safety

### 5.1 NetworkManager (`nmcli`) Integration
- **Array-Based Process Invocations**: Network status inspection and scanning execute via structured argument arrays (e.g., `command: ["nmcli", "-t", "-f", "IN-USE,SSID,SIGNAL,SECURITY", "device", "wifi", "list"]`), avoiding shell expansion vulnerabilities.
- **Zero Wi-Fi Password Exposure**: crazydots never collects, queries, stores, or logs Wi-Fi passwords. The UI only initiates direct connections for open networks; connection requests for secured networks delegate authentication entirely to system authentication agents (`gnome-keyring`, `kwallet`, or `wpa_supplicant`).
- **Truthful Bluetooth Daemon Probing**: Bluetooth daemon status is verified non-interactively via `systemctl is-active bluetooth`. The shell never assumes or simulates Bluetooth hardware or paired devices if the system daemon is inactive.

### 5.2 Backlight Control (`brightnessctl`) Integration
- **Privilege-Free Operations**: Brightness read and write operations execute via `/usr/bin/brightnessctl`, interacting with the Linux `/sys/class/backlight` kernel subsystem through `systemd-logind` and `udev` without requiring `sudo` or privileged escalation.
- **Zero Blackout Clamping**: Brightness updates enforce strict software clamping between 1% and 100%, preventing display blackouts caused by setting brightness to 0%.
- **Safe Hardware Absence Handling**: Systems lacking backlight hardware controllers (e.g., desktop monitors using DDC/CI) report unavailable status gracefully without throwing unhandled exceptions.
