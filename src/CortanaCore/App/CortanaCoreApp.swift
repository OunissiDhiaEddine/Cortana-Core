import SwiftUI

@main
struct CortanaCoreApp: App {
    @State private var chat: ChatViewModel
    @State private var models: ModelManager

    init() {
        let engine = Self.makeEngine()
        _chat = State(initialValue: ChatViewModel(engine: engine))
        _models = State(initialValue: ModelManager(engine: engine))
    }

    var body: some Scene {
        WindowGroup {
            ChatView(model: chat, models: models)
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
