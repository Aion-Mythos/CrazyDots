# crazydots — Development Guide

This document outlines the development workflow, coding standards, and testing procedures for crazydots.

---

## 1. Development Principles

### 1.1 Isolated Execution
Never test changes by overwriting system configurations or restarting the user's primary desktop session.
Run crazydots from the project root using its explicit path:
```bash
quickshell -p /home/aion/crazydots/shell
```

To run a specific QML file or component test in isolation:
```bash
quickshell -p /home/aion/crazydots/shell/tests/TestPanel.qml
```

### 1.2 QML Coding Conventions
- **Explicit Pragmas**: Always include `pragma ComponentBehavior: Bound` where component scoping applies.
- **Strict Typing**: Use strict QML types (`int`, `real`, `string`, `bool`, `color`, `var`) instead of generic un-typed properties.
- **Descriptive IDs**: Name component IDs after their semantic purpose (`id: root`, `id: backgroundCard`, `id: workspaceRepeater`).
- **Small Components**: If a QML component exceeds ~200 lines, extract sub-elements into dedicated files under `components/` or `panels/`.
- **Formatting**: 4-space indentation; group properties logically:
  1. ID and object name
  2. Public properties (`property ...`)
  3. Signal declarations
  4. Geometry and anchors (`width`, `height`, `anchors`)
  5. Visual properties (`color`, `opacity`, `radius`)
  6. States and transitions
  7. Event handlers and methods (`onClicked`, `function ...`)
  8. Child items

---

## 2. Static Code Verification

All QML files must pass `qmllint` without syntax errors before milestone commits:
```bash
qmllint shell/**/*.qml
```
