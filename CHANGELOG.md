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
- Model management: catalog of three on-device models, download/loading progress bar, in-chat status banner, Models screen (switch, delete, storage used).
- Chat history: conversations saved with SwiftData, chats list grouped by date with search, rename, delete, and a new-chat button.
- Settings screen: editable persona prompt, creativity / reply length / context size, model link, storage use, delete all chats, reset.
- Memory: "remember that …" saves a fact; memories can be viewed, added, deleted, cleared or switched off, and are added to the prompt.
### Removed
- Gemini/Google API calls, `swift-dotenv`, and the committed `.xcodeproj` (now generated).
- API-key-from-environment handling.
- Silver background and in-app Microsoft Cortana logo image.
