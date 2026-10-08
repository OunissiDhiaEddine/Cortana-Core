import Foundation
import HuggingFace
import MLXHuggingFace
import MLXLLM
import MLXLMCommon
import Tokenizers

/// Runs the model fully on device with MLX. Weights are downloaded once, then cached.
actor MLXChatEngine: ChatEngine {
    private var container: ModelContainer?
    private var target = ModelCatalog.default

    nonisolated func reply(to history: [ChatMessage], options: GenerationOptions) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            let task = Task {
                do {
                    let model = try await self.loadedContainer()
                    guard let last = history.last(where: { $0.role == .user }) else {
                        continuation.finish()
                        return
                    }
                    let prior = history
                        .filter { $0.role != .system && $0.id != last.id && !$0.text.isEmpty }
                        .suffix(options.maxHistoryMessages)
                        .map { $0.role == .user ? Chat.Message.user($0.text) : Chat.Message.assistant($0.text) }

                    let session = ChatSession(
                        model,
                        instructions: options.instructions,
                        history: Array(prior),
                        generateParameters: GenerateParameters(maxTokens: options.maxTokens, temperature: options.temperature),
                        additionalContext: ["enable_thinking": false]
                    )
                    for try await chunk in session.streamResponse(to: last.text) {
                        continuation.yield(chunk)
                    }
                    continuation.finish()
                } catch {
                    Log.engine.error("generation failed: \(error.localizedDescription)")
                    continuation.finish(throwing: error)
                }
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }

    func load(_ model: ModelOption, onProgress: @escaping @Sendable (DownloadProgress) -> Void) async throws {
        if target.id != model.id { container = nil }
        target = model
        _ = try await loadedContainer(onProgress: onProgress)
    }

    func unload() {
        container = nil
    }

    nonisolated func isInstalled(_ model: ModelOption) -> Bool { ModelStorage.isInstalled(model) }
    nonisolated func installedBytes(_ model: ModelOption) -> Int64 { ModelStorage.bytesOnDisk(model) }

    func delete(_ model: ModelOption) throws {
        if target.id == model.id { container = nil }
        try ModelStorage.delete(model)
    }

    private func loadedContainer(
        onProgress: @escaping @Sendable (DownloadProgress) -> Void = { _ in }
    ) async throws -> ModelContainer {
        if let container { return container }
        let model = target
        Log.engine.info("loading model \(model.name)")
        let loaded = try await #huggingFaceLoadModelContainer(
            configuration: model.configuration,
            progressHandler: { progress in
                onProgress(DownloadProgress(fraction: progress.fractionCompleted))
            })
        // The target may have changed while loading; keep the result only if it still matches.
        if target.id == model.id { container = loaded }
        Log.engine.info("model ready")
        return loaded
    }
}
