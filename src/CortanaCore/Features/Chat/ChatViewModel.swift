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
    private static let flushInterval = Duration.milliseconds(40)
    private static let greeting = ChatMessage(role: .assistant, text: Persona.greeting)

    private(set) var messages: [ChatMessage] = [greeting]
    var input = ""
    private(set) var isResponding = false
    /// The saved conversation being shown; nil for a fresh chat that has not been sent yet.
    private(set) var current: Conversation?

    var phase: ChatPhase {
        guard isResponding else { return .idle }
        return messages.last?.text.isEmpty == true ? .thinking : .responding
    }

    private let engine: ChatEngine
    private let store: ConversationStore?
    private let memory: MemoryStore?
    private let defaults: UserDefaults
    private var task: Task<Void, Never>?

    init(engine: ChatEngine, store: ConversationStore? = nil, memory: MemoryStore? = nil, defaults: UserDefaults = .standard) {
        self.engine = engine
        self.store = store
        self.memory = memory
        self.defaults = defaults
    }

    func send() {
        let text = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, !isResponding else { return }
        input = ""
        let userMessage = ChatMessage(role: .user, text: text)
        let reply = ChatMessage(role: .assistant, text: "")
        messages.append(userMessage)
        messages.append(reply)
        isResponding = true
        Log.chat.info("send: \(text.count) chars")

        var conversation: Conversation?
        if let store {
            let target = current ?? store.create(firstMessage: text)
            current = target
            store.append(userMessage, to: target)
            store.append(reply, to: target)
            conversation = target
        }

        let memoryOn = GenerationOptions.isMemoryEnabled(defaults)
        if memoryOn, let memory, let fact = MemoryExtractor.extract(from: text) {
            memory.add(fact)
        }
        let options = GenerationOptions.current(memories: memoryOn ? memory?.promptTexts() ?? [] : [], defaults: defaults)
        let history = Array(messages.dropLast())
        task = Task {
            do {
                // Tokens arrive far faster than the screen refreshes; batch them so each frame redraws once.
                var pending = ""
                var lastFlush = ContinuousClock.now
                for try await chunk in engine.reply(to: history, options: options) {
                    pending += chunk
                    if ContinuousClock.now - lastFlush >= Self.flushInterval {
                        update(reply.id) { $0.text += pending }
                        pending = ""
                        lastFlush = .now
                    }
                }
                if !pending.isEmpty { update(reply.id) { $0.text += pending } }
            } catch is CancellationError {
                Log.chat.info("reply cancelled")
            } catch {
                Log.chat.error("reply failed: \(error.localizedDescription)")
                update(reply.id) { $0.text = "Something went wrong, Chief." }
            }
            isResponding = false
            if let conversation, let text = messages.first(where: { $0.id == reply.id })?.text {
                store?.updateText(of: reply.id, in: conversation, to: text)
            }
        }
    }

    func stop() {
        task?.cancel()
    }

    func newChat() {
        stop()
        current = nil
        messages = [Self.greeting]
        input = ""
    }

    func open(_ conversation: Conversation) {
        guard conversation !== current else { return }
        stop()
        current = conversation
        messages = [Self.greeting] + conversation.orderedMessages.map(\.asChatMessage)
    }

    /// Called after a conversation is deleted from the history list.
    func conversationDeleted(_ conversation: Conversation) {
        if conversation === current { newChat() }
    }

    private func update(_ id: UUID, _ change: (inout ChatMessage) -> Void) {
        guard let index = messages.lastIndex(where: { $0.id == id }) else { return }
        change(&messages[index])
    }
}
