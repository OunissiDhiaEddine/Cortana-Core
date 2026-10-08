import Foundation
import HuggingFace
import MLXHuggingFace
import MLXLLM
import MLXLMCommon
import Tokenizers

/// Runs the model fully on device with MLX. Weights are downloaded once on first use, then cached.
actor MLXChatEngine: ChatEngine {
    private var container: ModelContainer?

    nonisolated func reply(to history: [ChatMessage]) -> AsyncThrowingStream<String, Error> {
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
                        .suffix(ModelConfig.maxHistoryMessages)
                        .map { $0.role == .user ? Chat.Message.user($0.text) : Chat.Message.assistant($0.text) }

                    let session = ChatSession(
                        model,
                        instructions: Persona.systemPrompt,
                        history: Array(prior),
                        generateParameters: GenerateParameters(maxTokens: ModelConfig.maxTokens, temperature: 0.7),
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

    private func loadedContainer() async throws -> ModelContainer {
        if let container { return container }
        Log.engine.info("loading model \(ModelConfig.model.name)")
        let loaded = try await #huggingFaceLoadModelContainer(configuration: ModelConfig.model)
        container = loaded
        Log.engine.info("model ready")
        return loaded
    }
}
