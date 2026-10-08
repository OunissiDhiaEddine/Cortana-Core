# Dev log
Newest first. One entry per stage: what changed, why, what is unverified.

## Stage 1: repo hygiene and cloud removal (2026-10-08)
- Surveyed the old app: single SwiftUI view + `Network` class POSTing to a Gemini URL read from the `API_KEY` env var; deps `generative-ai-swift` (unused in code) and `swift-dotenv`; iOS 16/17.5 targets; ~240 lines total.
- Moved sources to `src/`, replaced hand-maintained `.xcodeproj` with XcodeGen `project.yml` to keep the layout clean and diffs reviewable.
- Replaced `Network` with `ChatEngine` + `PlaceholderEngine`; the real on-device engine arrives in stage 2.
- Fixed old bugs on the way: fixed 2s delay before showing a reply, `[USER]` string tag for roles, `fatalError` on missing URL.
- **Unverified:** written without a Swift toolchain (Linux sandbox); first build/CI run on macOS is the real check.
