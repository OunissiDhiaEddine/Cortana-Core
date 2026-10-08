import SwiftData
import XCTest
@testable import CortanaCore

@MainActor
final class ConversationStoreTests: XCTestCase {
    private func makeStore() throws -> (ConversationStore, ModelContainer) {
        let container = try ConversationStore.makeContainer(inMemory: true)
        return (ConversationStore(context: container.mainContext), container)
    }

    func testTitleIsTruncatedFirstLine() {
        XCTAssertEqual(ConversationStore.title(from: "Hello there\nsecond line"), "Hello there")
        XCTAssertEqual(ConversationStore.title(from: String(repeating: "a", count: 60)), String(repeating: "a", count: 40) + "…")
        XCTAssertEqual(ConversationStore.title(from: "   "), "New chat")
    }

    func testAppendRenameAndCascadeDelete() throws {
        let (store, container) = try makeStore()
        let conversation = store.create(firstMessage: "Plan the mission")
        store.append(ChatMessage(role: .user, text: "Plan the mission"), to: conversation)
        store.append(ChatMessage(role: .assistant, text: "On it."), to: conversation)
        XCTAssertEqual(conversation.orderedMessages.map(\.text), ["Plan the mission", "On it."])

        store.rename(conversation, to: "Mission")
        XCTAssertEqual(conversation.title, "Mission")
        store.rename(conversation, to: "  ")
        XCTAssertEqual(conversation.title, "Mission")

        store.delete(conversation)
        XCTAssertEqual(try container.mainContext.fetchCount(FetchDescriptor<Conversation>()), 0)
        XCTAssertEqual(try container.mainContext.fetchCount(FetchDescriptor<StoredMessage>()), 0)
    }

    func testViewModelPersistsAndRestoresConversation() async throws {
        // The container must outlive the store: a ModelContext without its container crashes.
        let (store, container) = try makeStore()
        defer { withExtendedLifetime(container) {} }
        let model = ChatViewModel(engine: FixedEngine(), store: store)
        model.input = "Hi"
        model.send()
        while model.isResponding { try await Task.sleep(for: .milliseconds(10)) }

        let saved = try XCTUnwrap(model.current)
        XCTAssertEqual(saved.orderedMessages.map(\.text), ["Hi", "Hello, Chief."])

        model.newChat()
        XCTAssertNil(model.current)
        XCTAssertEqual(model.messages.count, 1)

        model.open(saved)
        XCTAssertEqual(model.messages.map(\.text), [Persona.greeting, "Hi", "Hello, Chief."])
    }

    func testHistoryGrouping() {
        let now = Date()
        XCTAssertEqual(HistoryGroup(for: now), .today)
        XCTAssertEqual(HistoryGroup(for: now.addingTimeInterval(-86400 * 30)), .older)
    }
}
