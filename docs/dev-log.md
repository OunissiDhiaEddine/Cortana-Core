# Dev log
Newest first. One entry per stage: what changed, why, what is unverified.

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
