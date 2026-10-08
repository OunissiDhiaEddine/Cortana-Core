import SwiftUI

@main
struct CortanaCoreApp: App {
    var body: some Scene {
        WindowGroup {
            ChatView(model: ChatViewModel(engine: PlaceholderEngine()))
        }
    }
}
