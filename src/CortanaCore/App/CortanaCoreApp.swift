import SwiftData
import SwiftUI

@main
struct CortanaCoreApp: App {
    @State private var chat: ChatViewModel
    @State private var models: ModelManager
    @Environment(\.scenePhase) private var scenePhase
    private let store: ConversationStore
    private let memory: MemoryStore
    private let container: ModelContainer

    init() {
        let engine = Self.makeEngine()
        // Falls back to memory-only history if the on-disk store cannot be opened, rather than crashing at launch.
        let container = (try? ConversationStore.makeContainer()) ?? (try! ConversationStore.makeContainer(inMemory: true))
        let store = ConversationStore(context: container.mainContext)
        self.container = container
        self.store = store
        let memory = MemoryStore(context: container.mainContext)
        self.memory = memory
        _chat = State(initialValue: ChatViewModel(engine: engine, store: store, memory: memory))
        _models = State(initialValue: ModelManager(engine: engine))
    }

    var body: some Scene {
        WindowGroup {
            ChatView(model: chat, models: models, store: store, memory: memory)
                .task { models.prepareSelected() }
                .onChange(of: scenePhase) { _, phase in
                    switch phase {
                    case .background:
                        // Metal work is not allowed in the background and the weights are the biggest memory user.
                        chat.stop()
                        models.unloadFromMemory()
                    case .active:
                        models.prepareSelected()
                    default:
                        break
                    }
                }
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
