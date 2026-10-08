import Foundation
import Observation

enum ChatPhase: Equatable {
    case idle, thinking, responding

    var caption: String {
        switch self {
        case .idle: "Listening"
        case .thinking: "Thinking…"
        case .responding: "Responding"
        }
    }
}

@MainActor
@Observable
final class ChatViewModel {
    private(set) var messages: [ChatMessage] = [
        ChatMessage(role: .assistant, text: "Hi there, Chief! How can I help today?")
    ]
    var input = ""
    private(set) var isResponding = false

    var phase: ChatPhase {
        guard isResponding else { return .idle }
        return messages.last?.text.isEmpty == true ? .thinking : .responding
    }

    private let engine: ChatEngine
    private var task: Task<Void, Never>?

    init(engine: ChatEngine) {
        self.engine = engine
    }

    func send() {
        let text = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, !isResponding else { return }
        input = ""
        messages.append(ChatMessage(role: .user, text: text))
        messages.append(ChatMessage(role: .assistant, text: ""))
        isResponding = true
        Log.chat.info("send: \(text.count) chars")

        let history = Array(messages.dropLast())
        task = Task {
            do {
                for try await chunk in engine.reply(to: history) {
                    messages[messages.count - 1].text += chunk
                }
            } catch is CancellationError {
                Log.chat.info("reply cancelled")
            } catch {
                Log.chat.error("reply failed: \(error.localizedDescription)")
                messages[messages.count - 1].text = "Something went wrong, Chief."
            }
            isResponding = false
        }
    }

    func stop() {
        task?.cancel()
    }
}
