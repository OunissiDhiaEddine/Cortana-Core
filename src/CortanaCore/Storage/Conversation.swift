import Foundation
import SwiftData

@Model
final class Conversation {
    @Attribute(.unique) var id: UUID
    var title: String
    var createdAt: Date
    var updatedAt: Date
    @Relationship(deleteRule: .cascade, inverse: \StoredMessage.conversation)
    var messages: [StoredMessage] = []

    init(title: String = "New chat", now: Date = .now) {
        id = UUID()
        self.title = title
        createdAt = now
        updatedAt = now
    }

    /// Messages in the order they were written.
    var orderedMessages: [StoredMessage] { messages.sorted { $0.createdAt < $1.createdAt } }
}

@Model
final class StoredMessage {
    @Attribute(.unique) var id: UUID
    var roleRaw: String
    var text: String
    var createdAt: Date
    var conversation: Conversation?

    init(id: UUID = UUID(), role: ChatRole, text: String, createdAt: Date = .now) {
        self.id = id
        roleRaw = role.rawValue
        self.text = text
        self.createdAt = createdAt
    }

    var role: ChatRole { ChatRole(rawValue: roleRaw) ?? .assistant }
    var asChatMessage: ChatMessage { ChatMessage(id: id, role: role, text: text) }
}
