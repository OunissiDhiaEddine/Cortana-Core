import Foundation
import HuggingFace
import MLXHuggingFace
import MLXLLM
import MLXLMCommon
import Tokenizers

/// Runs the model fully on device with MLX. Weights are downloaded once, then cached.
///
/// A `ChatSession` owns the KV cache, so consecutive turns of the same conversation reuse it and only
/// the new message is processed. The session is rebuilt (replaying the trimmed history) whenever the
/// conversation, the options, or the model change, or a reply was interrupted.
actor MLXChatEngine: ChatEngine {
    /// Hard cap on the KV cache (tokens). Older context rotates out, bounding memory on long chats.
    private static let maxKVSize = 2048

    private struct ActiveSession {
        let session: ChatSession
        let modelID: String
        let instructions: String
        let temperature: Float
        let maxTokens: Int
        /// Texts the session has already seen, in order (user and assistant turns).
        var seen: [String]
    }

    private var container: ModelContainer?
    private var target = ModelCatalog.default
    private var active: ActiveSession?

    nonisolated func reply(to history: [ChatMessage], options: GenerationOptions) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            let task = Task {
                do {
                    try await self.generate(history: history, options: options, into: continuation)
                    continuation.finish()
                } catch {
                    Log.engine.error("generation failed: \(error.localizedDescription)")
                    continuation.finish(throwing: error)
                }
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }

    private func generate(
        history: [ChatMessage], options: GenerationOptions,
        into continuation: AsyncThrowingStream<String, Error>.Continuation
    ) async throws {
        guard let last = history.last(where: { $0.role == .user }) else { return }
        let model = try await loadedContainer()
        let prior = history.filter { $0.role != .system && $0.id != last.id && !$0.text.isEmpty }

        var current: ActiveSession
        if let reusable = reusableSession(prior: prior.map(\.text), options: options) {
            current = reusable
        } else {
            let trimmed = Array(prior.suffix(options.maxHistoryMessages))
            let session = ChatSession(
                model,
                instructions: options.instructions,
                history: trimmed.map { $0.role == .user ? Chat.Message.user($0.text) : Chat.Message.assistant($0.text) },
                generateParameters: GenerateParameters(
                    maxTokens: options.maxTokens, maxKVSize: Self.maxKVSize, temperature: options.temperature),
                additionalContext: ["enable_thinking": false]
            )
            current = ActiveSession(
                session: session, modelID: target.id, instructions: options.instructions,
                temperature: options.temperature, maxTokens: options.maxTokens, seen: trimmed.map(\.text))
        }

        // Until this reply completes cleanly the cache is in an unknown state, so don't offer it for reuse.
        active = nil
        var produced = ""
        for try await chunk in current.session.streamResponse(to: last.text) {
            produced += chunk
            continuation.yield(chunk)
        }
        try Task.checkCancellation()
        current.seen += [last.text, produced]
        active = current
    }

    /// The live session if it has seen exactly the conversation so far and nothing relevant has changed.
    private func reusableSession(prior: [String], options: GenerationOptions) -> ActiveSession? {
        guard let active,
              active.modelID == target.id,
              active.instructions == options.instructions,
              active.temperature == options.temperature,
              active.maxTokens == options.maxTokens,
              active.seen == prior,
              prior.count <= options.maxHistoryMessages
        else { return nil }
        return active
    }

    func load(_ model: ModelOption, onProgress: @escaping @Sendable (DownloadProgress) -> Void) async throws {
        if target.id != model.id { container = nil }
        target = model
        _ = try await loadedContainer(onProgress: onProgress)
    }

    func unload() {
        active = nil
        container = nil
    }

    nonisolated func isInstalled(_ model: ModelOption) -> Bool { ModelStorage.isInstalled(model) }
    nonisolated func installedBytes(_ model: ModelOption) -> Int64 { ModelStorage.bytesOnDisk(model) }

    func delete(_ model: ModelOption) throws {
        if target.id == model.id { unload() }
        try ModelStorage.delete(model)
    }

    private func loadedContainer(
        onProgress: @escaping @Sendable (DownloadProgress) -> Void = { _ in }
    ) async throws -> ModelContainer {
        if let container { return container }
        let model = target
        active = nil
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
