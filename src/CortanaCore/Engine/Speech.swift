/// Extension point for voice output. Not wired into the UI yet.
/// See docs/voice.md for the plan and the licensing concern with the original Windows voice.
protocol SpeechOutput: Sendable {
    func speak(_ text: String) async
    func stop() async
}

struct SilentSpeech: SpeechOutput {
    func speak(_ text: String) async {}
    func stop() async {}
}
