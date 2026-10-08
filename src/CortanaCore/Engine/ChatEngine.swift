import Foundation

enum ChatRole: String, Sendable {
    case system, user, assistant
}

struct ChatMessage: Identifiable, Equatable, Sendable {
    var id = UUID()
    let role: ChatRole
    var text: String
}

struct DownloadProgress: Sendable, Equatable {
    /// 0...1
    var fraction: Double
}

/// Anything that can turn a conversation into a stream of reply text chunks and manage its own model files.
/// The on-device model engine implements this; the UI never talks to a model directly.
protocol ChatEngine: Sendable {
    func reply(to history: [ChatMessage]) -> AsyncThrowingStream<String, Error>

    /// Downloads the model if needed and loads it into memory, making it the model used for replies.
    func load(_ model: ModelOption, onProgress: @escaping @Sendable (DownloadProgress) -> Void) async throws
    func unload() async
    func isInstalled(_ model: ModelOption) -> Bool
    func installedBytes(_ model: ModelOption) -> Int64
    func delete(_ model: ModelOption) async throws
}

extension ChatEngine {
    func load(_ model: ModelOption, onProgress: @escaping @Sendable (DownloadProgress) -> Void) async throws {}
    func unload() async {}
    func isInstalled(_ model: ModelOption) -> Bool { true }
    func installedBytes(_ model: ModelOption) -> Int64 { 0 }
    func delete(_ model: ModelOption) async throws {}
}

/// Stand-in for the simulator (MLX needs a real GPU). Fakes a download so the model UI can be exercised.
final class PlaceholderEngine: ChatEngine, @unchecked Sendable {
    private let lock = NSLock()
    private var installed: Set<String> = [ModelCatalog.default.id]

    func reply(to history: [ChatMessage]) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            let task = Task {
                for word in "On-device model not available in the simulator, Chief.".split(separator: " ") {
                    try await Task.sleep(for: .milliseconds(60))
                    continuation.yield(word + " ")
                }
                continuation.finish()
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }

    func load(_ model: ModelOption, onProgress: @escaping @Sendable (DownloadProgress) -> Void) async throws {
        if !isInstalled(model) {
            for step in 1...20 {
                try await Task.sleep(for: .milliseconds(100))
                onProgress(DownloadProgress(fraction: Double(step) / 20))
            }
            lock.withLock { _ = installed.insert(model.id) }
        }
    }

    func isInstalled(_ model: ModelOption) -> Bool { lock.withLock { installed.contains(model.id) } }
    func installedBytes(_ model: ModelOption) -> Int64 { isInstalled(model) ? model.approxBytes : 0 }
    func delete(_ model: ModelOption) async throws { lock.withLock { _ = installed.remove(model.id) } }
}
