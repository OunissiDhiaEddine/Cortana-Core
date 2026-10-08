# Dev log
Newest first. One entry per stage: what changed, why, what is unverified.

## Stage 8: cleanup and performance (2026-10-08)
- **Structure:** feature folders, `MemoryView` split out of settings. Chose to keep MLX Swift, SwiftUI `@Observable` and SwiftData; no framework swap was justified (MLX is already the fastest native option on Apple GPUs, and SwiftData removes the need for any third-party store).
- **Speed:** `MLXChatEngine` keeps a `ChatSession` between turns. It is reused only when the session has seen exactly the conversation so far and model, prompt, temperature and length are unchanged; otherwise it is rebuilt with the last N messages. Replying to turn N no longer re-processes turns 1..N-1.
- **Memory:** `maxKVSize` 2048 rotates old context out of the KV cache. Weights unload on background (iOS also forbids Metal work there, so generation is stopped first) and reload when active again.
- **UI:** 40 ms token batching, `Equatable` bubbles so only the streaming bubble re-renders, orb capped below 60 fps, cached storage sizes.
- **Deferred:** (1) Swift 6 language mode: `SWIFT_STRICT_CONCURRENCY=complete` is on as warnings; flip `SWIFT_VERSION` once the build log shows none. (2) `MLX.Memory.cacheLimit` and quantized KV cache (`kvBits`): need the `mlx-swift` product linked directly, and quantized cache does not combine with the rotating cache; revisit after measuring on device.
- **Unverified on device:** all of the above; measure time-to-first-token on turn 5 and peak memory on iPhone 14 with Instruments before and after.

## Stage 7: settings and memory (2026-10-08)
- Settings live in `UserDefaults` via `@AppStorage`; the view model snapshots them into `GenerationOptions` on each send, so the engine stays free of UI state.
- Memory is explicit on purpose: only "remember that …" (or the manual add field) writes a memory. A 1.7B model is unreliable at choosing what to remember, and a wrong auto-memory is worse than none. Facts (max 20 most recent) are appended to the system prompt.
- `ChatEngine.reply` now takes `GenerationOptions`.
- **Unverified on device:** how well Qwen3-1.7B uses injected memories; may need a prompt tweak.

## Stage 6: chat history (2026-10-08)
- SwiftData (`Conversation`, `StoredMessage`, cascade delete) behind a small `ConversationStore`; iOS 17 floor already allows it and it is the native choice (no third-party DB).
- A chat is saved on first send, not on "new chat", so empty chats never pile up. The assistant reply is written to disk once when streaming ends (or is stopped), not per token.
- Search uses `localizedStandardContains` on title and message text in the `@Query` predicate.
- If the on-disk store cannot be opened the app falls back to in-memory history instead of crashing.
- **Unverified on device:** predicate behavior with large histories; schema migrations (none yet, v1).

## Stage 5: model download progress and management (2026-10-08)
- `ModelCatalog` (Lite 0.6B / Core 1.7B / Prime 4B, all MLX 4-bit Qwen3), `ModelManager` (@Observable) for selection and download/load state, `ModelStorage` for on-disk size and delete via the Hugging Face hub cache.
- Progress comes from the `progressHandler` of `#huggingFaceLoadModelContainer` (mlx-swift-lm 3.31.3). Byte readout is `fraction * approxBytes`, since the handler reports a fraction.
- Chat input stays disabled until a model is loaded, so a send can never trigger a silent download.
- Simulator `PlaceholderEngine` fakes a download so the UI can be exercised without a GPU.
- **Unverified on device:** real progress callback cadence, cancel mid-download, delete while loaded.

## Stage 4: persona and voice hook (2026-10-08)
- Rewrote the system prompt as short rules (personality, style, constraints) because small models follow rules better than prose. Wording is original; no game dialogue copied.
- Added `SpeechOutput` protocol and `docs/voice.md` (plan plus licensing concern with the original voice).
- **Unverified:** persona quality on Qwen3-1.7B needs hands-on tuning on device; prompt is the main lever.

## Stage 3: Cortana UI (2026-10-08)
- Dark gradient theme, `CortanaOrb` (TimelineView-driven rings, three phases), inline markdown in bubbles, multi-line input with stop/send button, auto-scroll while streaming.
- Removed the Microsoft logo and silver background assets from the in-app UI; the app icon is the only Microsoft artwork left.
- **Unverified:** not compiled or viewed; the orb's look needs a pass on a real screen.

## Stage 2: on-device model (2026-10-08)
- Chose MLX Swift + Qwen3-1.7B 4-bit; rationale in `docs/model-runtime.md`.
- API shapes (`ChatSession(history:instructions:generateParameters:additionalContext:)`, `streamResponse`, `LLMRegistry` names) taken from mlx-swift-lm 3.31.x source.
- Simulator falls back to the placeholder engine.
- **Unverified:** no build, no device run; memory and speed on iPhone 14 still to be measured.

## Stage 1: repo hygiene and cloud removal (2026-10-08)
- Surveyed the old app: single SwiftUI view + `Network` class POSTing to a Gemini URL read from the `API_KEY` env var; deps `generative-ai-swift` (unused in code) and `swift-dotenv`; iOS 16/17.5 targets; ~240 lines total.
- Moved sources to `src/`, replaced hand-maintained `.xcodeproj` with XcodeGen `project.yml` to keep the layout clean and diffs reviewable.
- Replaced `Network` with `ChatEngine` + `PlaceholderEngine`; the real on-device engine arrives in stage 2.
- Fixed old bugs on the way: fixed 2s delay before showing a reply, `[USER]` string tag for roles, `fatalError` on missing URL.
- **Unverified:** written without a Swift toolchain (Linux sandbox); first build/CI run on macOS is the real check.

## 2026-10-08 first local build
- bootstrap.sh OK; Xcode needs -skipMacroValidation (MLXHuggingFaceMacros) and the Metal Toolchain.
- iPhone simulator build: succeeded, no compile errors.
- Tests on iPhone 18 Pro simulator: 3 passed, 0 failed.
