# crazydots — Testing & Verification Strategy

This document describes the quality assurance strategy for crazydots.

---

## 1. Testing Tiers

### 1.1 Static Analysis (Tier 1)
- **Tool**: `qmllint`
- **Scope**: All `.qml` files in the repository.
- **Criteria**: Zero syntax errors, zero unresolved import statements, and zero deprecated API warnings.

### 1.2 Isolated Runtime Testing (Tier 2)
- **Tool**: `quickshell -p <path>`
- **Scope**: Executing standalone shell instances in a running Hyprland session without interfering with existing shells.
- **Checklist**:
  - [ ] No crash or uncaught exception on startup.
  - [ ] No Qt binding loops reported in stderr.
  - [ ] Dynamic input regions correctly intercept clicks when open and pass through when closed.
  - [ ] Smooth 60fps+ animations without dropped frames.
  - [ ] Panel dismisses cleanly on outside click and `Escape` keypress.

### 1.3 Service Degradation & Resilience (Tier 3)
- Verify that the shell starts and functions cleanly under failure scenarios:
  - Missing `config.json` (falls back to defaults).
  - Corrupted JSON (graceful recovery without crash).
  - Offline network (network indicator shows disconnected).
  - No active MPRIS players (media widget collapses cleanly).
  - Missing `matugen` executable (falls back to static color themes).
  - Missing or disconnected Hyprland compositor (graceful fallback without invented state).
  - Missing or failing terminal emulator (graceful fallback without shell crashes).

---

## 2. Automated Test Suite (`tests/run_tests.sh`)
- Automated execution of all unit and integration test harnesses:
  - `TestThemeEngine.qml` (M1: 29 assertions)
  - `TestConfig.qml` (M2: 32 assertions)
  - `TestBaseComponents.qml` (M3: 23 assertions)
  - `TestBar.qml` (M4: 29 assertions)
  - `TestLauncher.qml` (M5: 37 assertions)
  - `TestWallpaper.qml` (M6: 39 assertions)
  - `TestDashboard.qml` (M7: 37 assertions)
  - `TestHyprlandGhostty.qml` (M8: 42 assertions)
  - `TestPopoversUX.qml` (M10: 41 assertions)
- Combined suite executes **309 automated assertions** with 0 failures.
- End-to-end live Quickshell process lifecycle and IPC protocol verification across 28 IPC methods.

---

## 3. Milestone Acceptance Criteria

Before any milestone is committed to Git:
1. All newly introduced QML files must pass `qmllint`.
2. The runtime behavior must be verified in an isolated Quickshell process.
3. Git diff must be reviewed to ensure no temporary clutter or secrets are staged.
