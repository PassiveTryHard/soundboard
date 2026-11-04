# Changelog

All notable changes to this project are documented in this file.
Newest versions are at the top. Format based on Keep a Changelog.

## [Unreleased]
<!-- Write changes here as you make them. When you commit a new version,
     rename this heading to the version number and date, then add a
     fresh empty Unreleased section above it. -->

### Fixed
- Pause strip, progress bars, and Stop All appear inconsistently (investigating)

## [0.10.1] - 2026-06-18
### Added
- Solo mode toggle (only one button plays at a time)
- Haptic feedback on button tap
- Pause strip on individual buttons
### Changed
- Input device selector disabled and kept as comments for the desktop phase
### Fixed
- Progress bar activating before audio started
- Android back-gesture manifest warning

## [0.9.0] - 2026-06-11
### Added
- Settings screen with theme selector (dark, light, system)
- Stop All button
### Changed
- Playback mode now controls per-button overlap vs. restart

## [0.8.0] - 2026-06-07
### Added
- Edit mode with rename, recolor, and delete
- Drag-to-reorder buttons