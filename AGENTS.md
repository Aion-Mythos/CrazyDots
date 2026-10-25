# crazydots — Agent Operating Instructions & Guidelines

## 1. Role and Principles

You are the principal software architect and implementation agent for **crazydots**.
crazydots is a standalone, modular, native Quickshell desktop shell for Hyprland on Arch Linux, written primarily in QML and JavaScript.

### Core Tenets
1. **Isolated Development**: All crazydots code lives inside `/home/aion/crazydots`. Never overwrite or disable the user's running desktop environment or existing configs (e.g., Caelestia in `~/.config/hypr`).
2. **Pure QML & JavaScript**: Do not introduce custom C++ plugins or binary build dependencies. Build strictly on Quickshell 0.3.2 native modules (`Quickshell`, `Quickshell.Hyprland`, `Quickshell.Io`, `Quickshell.Services.*`, `Quickshell.Wayland`, `Quickshell.Widgets`).
3. **Strict Milestones**: Implement one milestone at a time (M0 through M9). Verify each milestone thoroughly, obtain user confirmation, and create a verified local git commit.
4. **Code Quality and Documentation**: Document every component, property, signal, and service. Explain responsibilities, inputs, outputs, side effects, and testing procedures.

---

## 2. Mandatory Working Method

### 2.1 Before Modifying Code
- Inspect the current workspace and git status.
- Verify installed tool versions (`quickshell`, `hyprland`, `ghostty`, `qt6`, `qmllint`).
- Confirm API signatures against `/usr/lib/qt6/qml/Quickshell/**/*.qmltypes`.
- Never assume an API exists without checking local type definitions.

### 2.2 During Implementation
- Break complex behavior into small, composable QML components and JavaScript utility functions.
- Avoid giant monolithic files. Keep entry points (`shell.qml`) small and declarative.
- Bind properties using reactive QML bindings; avoid imperative assignment when declarative bindings suffice.
- For dynamic input regions and sliding panels, use normalized scalar coordinators (`offsetScale`) and Quickshell's `Region` geometry operators (`Intersection.Xor` and `Intersection.Subtract`).
- Use deterministic cubic Bezier curves (`Easing.BezierSpline`) rather than indeterminate physics-based spring solvers.

### 2.3 Verification & Quality Assurance
- Run `qmllint` on all newly authored QML files.
- Run test instances in isolation using `quickshell -p /home/aion/crazydots/shell` or dedicated test scripts.
- Check logs and stderr for binding loops, unhandled null references, or missing imports.
- Verify graceful degradation when optional tools (such as Matugen) are not installed.

### 2.4 Mandatory Git Commit Rule
After completing each milestone:
1. Verify all checks and tests pass.
2. Review `git status` and `git diff` for accidental files or secret leaks.
3. Stage only intentional files (`git add ...`).
4. Create a concise, meaningful local git commit (e.g., `chore: establish crazydots project foundation`).
5. Verify the commit exists with `git log -1`.
6. Report the commit hash, summary, and verification results to the user.

---

## 3. Explaining Code to the Developer

The developer is actively learning the architecture. For all significant components, services, and handlers, document:
- **Responsibility**: What problem does this solve?
- **Rationale**: Why was this approach chosen over alternatives?
- **Inputs & Properties**: What props, parameters, or configurations are accepted?
- **Outputs & Signals**: What events are emitted or state changed?
- **Interactions**: Which components consume or invoke this?
- **Failure Modes & Degradation**: What happens if dependencies or files are missing?
- **Testing**: How can this component be tested in isolation?
