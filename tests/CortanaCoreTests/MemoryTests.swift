import XCTest
@testable import CortanaCore

@MainActor
final class MemoryTests: XCTestCase {
    func testExtractorFindsExplicitRequests() {
        XCTAssertEqual(MemoryExtractor.extract(from: "Remember that my name is Dhia"), "My name is Dhia")
        XCTAssertEqual(MemoryExtractor.extract(from: "Please remember: I prefer short answers"), "I prefer short answers")
        XCTAssertEqual(MemoryExtractor.extract(from: "cortana, don't forget I have an exam friday"), "I have an exam friday")
    }

    func testExtractorIgnoresQuestionsAndOtherText() {
        XCTAssertNil(MemoryExtractor.extract(from: "Do you remember my name?"))
        XCTAssertNil(MemoryExtractor.extract(from: "Remember?"))
        XCTAssertNil(MemoryExtractor.extract(from: "What's the weather like"))
    }

    func testStoreDedupesAndClears() throws {
        let container = try ConversationStore.makeContainer(inMemory: true)
        let store = MemoryStore(context: container.mainContext)
        XCTAssertTrue(store.add("Likes tea"))
        XCTAssertFalse(store.add("likes TEA"))
        XCTAssertEqual(store.promptTexts(), ["Likes tea"])
        store.clear()
        XCTAssertTrue(store.all().isEmpty)
    }

    func testInstructionsIncludeMemoriesOnlyWhenPresent() {
        var options = GenerationOptions()
        XCTAssertEqual(options.instructions, Persona.systemPrompt)
        options.memories = ["Likes tea"]
        XCTAssertTrue(options.instructions.contains("- Likes tea"))
    }

    func testSavingViaChatTurnReachesTheEngine() async throws {
        let container = try ConversationStore.makeContainer(inMemory: true)
        let memory = MemoryStore(context: container.mainContext)
        let defaults = UserDefaults(suiteName: #function)!
        defaults.removePersistentDomain(forName: #function)
        let model = ChatViewModel(engine: FixedEngine(), memory: memory, defaults: defaults)
        model.input = "Remember that I like tea"
        model.send()
        while model.isResponding { try await Task.sleep(for: .milliseconds(10)) }
        XCTAssertEqual(memory.promptTexts(), ["I like tea"])

        defaults.set(false, forKey: SettingsKey.memoryEnabled)
        model.input = "Remember that I hate coffee"
        model.send()
        while model.isResponding { try await Task.sleep(for: .milliseconds(10)) }
        XCTAssertEqual(memory.promptTexts(), ["I like tea"])
    }
}
