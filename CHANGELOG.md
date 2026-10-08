# Changelog
Format: [Keep a Changelog](https://keepachangelog.com). Versions not yet released.

## [Unreleased]
### Added
- Standard repo layout (`src/`, `tests/`, `docs/`, `scripts/`), XcodeGen `project.yml`, CI, MIT license.
- `ChatEngine` protocol as the single seam between UI and model; `os.Logger` loggers.
- Streaming chat view model with unit tests.
- On-device inference via MLX Swift (`MLXChatEngine`, Qwen3-1.7B 4-bit); model choice documented in `docs/model-runtime.md`.
- Increased-memory-limit entitlement.
- Cortana-style dark UI: animated blue ring (idle/thinking/responding), streaming markdown bubbles, stop button.
- Halo-style Cortana persona prompt; `SpeechOutput` extension point and voice plan (`docs/voice.md`).
### Removed
- Gemini/Google API calls, `swift-dotenv`, and the committed `.xcodeproj` (now generated).
- API-key-from-environment handling.
- Silver background and in-app Microsoft Cortana logo image.
