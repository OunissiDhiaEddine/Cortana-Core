import Foundation

enum ChatRole: String, Sendable {
    case system, user, assistant
}

struct ChatMessage: Identifiable, Equatable, Sendable {
    let id = UUID()
    let role: ChatRole
    var text: String
}

/// Anything that can turn a conversation into a stream of reply text chunks.
/// The on-device model engine implements this; the UI never talks to a model directly.
protocol ChatEngine: Sendable {
    func reply(to history: [ChatMessage]) -> AsyncThrowingStream<String, Error>
}

/// Stand-in used until the on-device model lands. Makes no network calls.
struct PlaceholderEngine: ChatEngine {
    func reply(to history: [ChatMessage]) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            let task = Task {
                for word in "On-device model not installed yet, Chief.".split(separator: " ") {
                    try await Task.sleep(for: .milliseconds(60))
                    continuation.yield(word + " ")
                }
                continuation.finish()
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }
}
