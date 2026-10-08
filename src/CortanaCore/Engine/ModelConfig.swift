import MLXLLM

/// The one place the on-device model is chosen. See docs/model-runtime.md for why.
enum ModelConfig {
    static let model = LLMRegistry.qwen3_1_7b_4bit
    /// Most recent messages sent back to the model each turn; older ones are dropped to bound memory and latency.
    static let maxHistoryMessages = 12
    static let maxTokens = 512
}
