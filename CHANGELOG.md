# Changelog

All notable changes to **Classic Era Finder** are documented in this file.

Format: [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).  
Versioning: [Semantic Versioning](https://semver.org/) (`MAJOR.MINOR.PATCH`).

The live CurseForge release is always the `## Version` in `ClassicEraFinder.toc`.

---

## [Unreleased]

### Changed
### Fixed
### Added

---

## [1.1.3] - 2026-07-22

### Changed
- TOC Interface updated for Classic Era patch **1.15.9** (`11509`). TBC Anniversary remains **2.5.6** (`20506`).

---

## [1.1.2] - 2026-07-17

### Added
- Premade: hover tooltip with party members (leader, class colors, level, roles), member counts, and activities.

### Changed
- Premade tooltip activities use the same colors and level ranges as the Activity column.
- Premade tooltip width scales to content (no extra empty space on short listings).

---

## [1.1.1] - 2026-07-14

### Fixed
- Ignore Hardcore death broadcasts (`HardcoreDeaths` channel and “has been slain by…” style messages) so they are not shown as Chat LFG listings.
- Settings: chat-listing alert row background now sizes to the label (works across locales).

### Added
- CurseForge project ID in the TOC (`X-Curse-Project-ID`) for BigWigs / packager tooling.

---

## [1.1.0] - 2026-07-14

### Added
- First CurseForge release (Classic Era + Classic TBC Anniversary).
- Home, Chat, Premade, Guild, Messages, and Group tabs.
- Multilingual UI / instance / zone support.
