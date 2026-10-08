import SwiftUI

@main
struct CortanaCoreApp: App {
    var body: some Scene {
        WindowGroup {
            ChatView(model: ChatViewModel(engine: Self.makeEngine()))
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
