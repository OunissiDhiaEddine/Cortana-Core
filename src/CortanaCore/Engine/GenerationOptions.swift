import Foundation

/// Keys and defaults for user-tunable settings. Views bind with `@AppStorage`; the engine reads a snapshot.
enum SettingsKey {
    static let systemPrompt = "settings.systemPrompt"
    static let temperature = "settings.temperature"
    static let maxTokens = "settings.maxTokens"
    static let maxHistory = "settings.maxHistory"
    static let memoryEnabled = "settings.memoryEnabled"
}

enum SettingsDefault {
    static let systemPrompt = Persona.systemPrompt
    static let temperature = 0.7
    static let maxTokens = 512
    static let maxHistory = 12
    static let memoryEnabled = true
}

/// Everything the engine needs for one reply, captured when the user hits send.
struct GenerationOptions: Sendable, Equatable {
    var systemPrompt = SettingsDefault.systemPrompt
    var memories: [String] = []
    var temperature: Float = Float(SettingsDefault.temperature)
    var maxTokens = SettingsDefault.maxTokens
    var maxHistoryMessages = SettingsDefault.maxHistory

    /// System prompt plus remembered facts, as sent to the model.
    var instructions: String {
        let base = systemPrompt.trimmingCharacters(in: .whitespacesAndNewlines)
        let prompt = base.isEmpty ? Persona.systemPrompt : base
        guard !memories.isEmpty else { return prompt }
        return prompt + "\n\nThings you remember about the Chief (use them naturally, don't recite them):\n"
            + memories.map { "- \($0)" }.joined(separator: "\n")
    }

    static func current(memories: [String], defaults: UserDefaults = .standard) -> GenerationOptions {
        GenerationOptions(
            systemPrompt: defaults.string(forKey: SettingsKey.systemPrompt) ?? SettingsDefault.systemPrompt,
            memories: memories,
            temperature: Float(defaults.object(forKey: SettingsKey.temperature) as? Double ?? SettingsDefault.temperature),
            maxTokens: defaults.object(forKey: SettingsKey.maxTokens) as? Int ?? SettingsDefault.maxTokens,
            maxHistoryMessages: defaults.object(forKey: SettingsKey.maxHistory) as? Int ?? SettingsDefault.maxHistory)
    }

    static func isMemoryEnabled(_ defaults: UserDefaults = .standard) -> Bool {
        defaults.object(forKey: SettingsKey.memoryEnabled) as? Bool ?? SettingsDefault.memoryEnabled
    }
}
