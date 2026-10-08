# Changelog
Format: [Keep a Changelog](https://keepachangelog.com). Versions not yet released.

## [Unreleased]
### Added
- Standard repo layout (`src/`, `tests/`, `docs/`, `scripts/`), XcodeGen `project.yml`, CI, MIT license.
- `ChatEngine` protocol as the single seam between UI and model; `os.Logger` loggers.
- Streaming chat view model with unit tests.
### Removed
- Gemini/Google API calls, `swift-dotenv`, and the committed `.xcodeproj` (now generated).
- API-key-from-environment handling.
