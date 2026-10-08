import SwiftData
import SwiftUI

@main
struct CortanaCoreApp: App {
    @State private var chat: ChatViewModel
    @State private var models: ModelManager
    private let store: ConversationStore
    private let container: ModelContainer

    init() {
        let engine = Self.makeEngine()
        // Falls back to memory-only history if the on-disk store cannot be opened, rather than crashing at launch.
        let container = (try? ConversationStore.makeContainer()) ?? (try! ConversationStore.makeContainer(inMemory: true))
        let store = ConversationStore(context: container.mainContext)
        self.container = container
        self.store = store
        _chat = State(initialValue: ChatViewModel(engine: engine, store: store))
        _models = State(initialValue: ModelManager(engine: engine))
    }

    var body: some Scene {
        WindowGroup {
            ChatView(model: chat, models: models, store: store)
                .task { models.prepareSelected() }
        }
    }

    private static func makeEngine() -> ChatEngine {
        #if targetEnvironment(simulator)
        // MLX needs a real GPU; the simulator gets the placeholder.
        PlaceholderEngine()
        #else
        MLXChatEngine()
        #endif
    }
}
