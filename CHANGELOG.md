# Changelog

All notable changes to the **crazydots** desktop shell project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### [0.1.0] - 2026-10-25 - Milestone M0: Foundation and Specification

#### Added
- Initialized local Git repository on `main` branch.
- Created root governance and specification files:
  - `AGENTS.md`: Operating principles, API verification rules, and git commit guidelines for development agents.
  - `SPEC.md`: Complete engineering specification covering architecture, dependencies, boundaries, and panel state lifecycles.
  - `LICENSE`: Full GNU General Public License v3.0 text (GPL-3.0-or-later).
  - `packages.txt`: Tiered package dependency manifest across Required, Recommended, Optional, and Dev categories.
  - `.gitignore`: Ignore rules for Qt Quick caches, QML compiler outputs, editor files, and temporary test artifacts.
  - `install.sh`: Safe installation script with `--dry-run`, directory creation, and non-destructive symlink management.
  - `uninstall.sh`: Clean removal script targeting crazydots configurations without affecting other desktop files.
- Added comprehensive documentation suite under `docs/`:
  - `docs/ARCHITECTURE.md`: Crazydots internal architecture, pure QML/JS stack, state management, and layer-shell integration.
  - `docs/COMPONENTS.md`: Catalog of core components, properties, signals, and styling principles.
  - `docs/CONFIGURATION.md`: Centralized configuration schema (`config.json`), validation rules, and persistence API.
  - `docs/DEPENDENCIES.md`: Dependency tier analysis, system requirements, verification procedures, and fallback modes.
  - `docs/DEVELOPMENT.md`: Developer setup, isolated testing with `quickshell -p ~/crazydots/shell`, and linting rules.
  - `docs/TESTING.md`: Verification plan including static checks (`qmllint`), component testbeds, and safety boundaries.
  - `docs/TROUBLESHOOTING.md`: Common diagnostic scenarios, Wayland socket checks, and layer-shell grab handling.
  - `docs/SECURITY.md`: Process execution security, argument escaping, and D-Bus boundaries.
- Preserved existing `ARCHITECTURE.md` as reference analysis of Caelestia.
