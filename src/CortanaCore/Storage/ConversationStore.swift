import Foundation
import SwiftData

/// Thin persistence layer over SwiftData. Everything the chat UI needs to save and restore conversations.
@MainActor
final class ConversationStore {
    let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    static func makeContainer(inMemory: Bool = false) throws -> ModelContainer {
        try ModelContainer(
            for: Conversation.self, StoredMessage.self,
            configurations: .init(isStoredInMemoryOnly: inMemory))
    }

    func create(firstMessage: String) -> Conversation {
        let conversation = Conversation(title: Self.title(from: firstMessage))
        context.insert(conversation)
        return conversation
    }

    @discardableResult
    func append(_ message: ChatMessage, to conversation: Conversation) -> StoredMessage {
        let stored = StoredMessage(id: message.id, role: message.role, text: message.text)
        context.insert(stored)
        stored.conversation = conversation
        conversation.updatedAt = .now
        save()
        return stored
    }

    func updateText(of id: UUID, in conversation: Conversation, to text: String) {
        guard let stored = conversation.messages.first(where: { $0.id == id }) else { return }
        stored.text = text
        conversation.updatedAt = .now
        save()
    }

    func rename(_ conversation: Conversation, to title: String) {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        conversation.title = trimmed
        save()
    }

    func delete(_ conversation: Conversation) {
        context.delete(conversation)
        save()
    }

    func deleteAll() {
        try? context.delete(model: Conversation.self)
        save()
    }

    func save() {
        do { try context.save() } catch { Log.chat.error("save failed: \(error.localizedDescription)") }
    }

    static func title(from text: String) -> String {
        let firstLine = text.split(whereSeparator: \.isNewline).first.map(String.init) ?? text
        let trimmed = firstLine.trimmingCharacters(in: .whitespaces)
        return trimmed.count > 40 ? String(trimmed.prefix(40)) + "…" : (trimmed.isEmpty ? "New chat" : trimmed)
    }
}
