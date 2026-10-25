# crazydots — Security Policy & Guidelines

This document details security boundaries, command execution policies, and external process safety in crazydots.

---

## 1. Subprocess Execution Guidelines

### 1.1 Array-Based Arguments
Never concatenate un-sanitized user input into a raw shell string (e.g., `sh -c "command " + userInput`).
Always use `Quickshell.Io.Process` with array-based arguments:
```qml
Process {
    command: ["ghostty", "-e", "btop"]
}
```
This guarantees that arguments are passed directly through `execvp()` without shell word-splitting or command injection vulnerabilities.

---

## 2. D-Bus & IPC Boundaries

- **Hyprland IPC**: Read-only tracking of window titles, workspaces, and monitor geometry. Dispatcher calls are strictly restricted to verified compositor actions (`workspace`, `movetoworkspace`).
- **Polkit & Authentication**: crazydots does not handle raw user passwords or run privileged PAM operations directly. Authentication requests are delegated to system authentication agents (`polkit-gnome` or similar).
- **System Configuration**: crazydots never executes commands with `sudo` or modifies system files outside the user's home directory.
