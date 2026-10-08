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
### Changed
- Source tree reorganised by feature (`Features/Chat|History|Models|Settings`, `Engine`, `Storage`, `DesignSystem`, `Core`).
- Chat turns reuse the model's KV cache instead of replaying history; KV cache capped at 2048 tokens.
- Streaming text is batched to ~25 redraws/s; unchanged bubbles skip re-rendering; orb animation capped at 20-30 fps.
- Model weights unload and generation stops when the app goes to the background; weights reload on return.
- Storage sizes are cached instead of read from disk on every redraw.
- Strict concurrency checking enabled (warnings).
### Removed
- Gemini/Google API calls, `swift-dotenv`, and the committed `.xcodeproj` (now generated).
- API-key-from-environment handling.
- Silver background and in-app Microsoft Cortana logo image.
