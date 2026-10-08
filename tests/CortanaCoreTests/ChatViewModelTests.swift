import XCTest
@testable import CortanaCore

struct FixedEngine: ChatEngine {
    func reply(to history: [ChatMessage]) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { c in
            c.yield("Hello, ")
            c.yield("Chief.")
            c.finish()
        }
    }
}

@MainActor
final class ChatViewModelTests: XCTestCase {
    func testSendStreamsReplyIntoLastMessage() async throws {
        let model = ChatViewModel(engine: FixedEngine())
        model.input = "Hi"
        model.send()
        while model.isResponding { try await Task.sleep(for: .milliseconds(10)) }

        XCTAssertEqual(model.messages.suffix(2).map(\.role), [.user, .assistant])
        XCTAssertEqual(model.messages.last?.text, "Hello, Chief.")
        XCTAssertEqual(model.input, "")
    }

    func testEmptyInputIsIgnored() {
        let model = ChatViewModel(engine: FixedEngine())
        let before = model.messages.count
        model.input = "   "
        model.send()
        XCTAssertEqual(model.messages.count, before)
    }

    func testPhaseIsIdleBeforeAndAfterReply() async throws {
        let model = ChatViewModel(engine: FixedEngine())
        XCTAssertEqual(model.phase, .idle)
        model.input = "Hi"
        model.send()
        while model.isResponding { try await Task.sleep(for: .milliseconds(10)) }
        XCTAssertEqual(model.phase, .idle)
    }
}
