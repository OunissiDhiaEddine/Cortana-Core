import Foundation
import SwiftData

/// One fact Cortana remembers about the user, e.g. "My name is Dhia".
@Model
final class Memory {
    @Attribute(.unique) var id: UUID
    var text: String
    var createdAt: Date

    init(text: String, createdAt: Date = .now) {
        id = UUID()
        self.text = text
        self.createdAt = createdAt
    }
}

@MainActor
final class MemoryStore {
    /// Cap on facts injected into the prompt so memory never crowds out the conversation.
    static let promptLimit = 20
    let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func all() -> [Memory] {
        (try? context.fetch(FetchDescriptor<Memory>(sortBy: [SortDescriptor(\.createdAt)]))) ?? []
    }

    /// Most recent facts, oldest first, trimmed to the prompt limit.
    func promptTexts() -> [String] {
        all().suffix(Self.promptLimit).map(\.text)
    }

    @discardableResult
    func add(_ text: String) -> Bool {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !all().contains(where: { $0.text.caseInsensitiveCompare(trimmed) == .orderedSame }) else { return false }
        context.insert(Memory(text: String(trimmed.prefix(200))))
        try? context.save()
        return true
    }

    func delete(_ memory: Memory) {
        context.delete(memory)
        try? context.save()
    }

    func clear() {
        try? context.delete(model: Memory.self)
        try? context.save()
    }
}

/// Spots explicit "remember that ..." requests. Deliberately simple: a 1.7B model is unreliable at
/// deciding what is worth remembering, so memory is only written when the user asks (or adds it by hand).
enum MemoryExtractor {
    private static let triggers = ["remember that ", "remember: ", "remember ", "don't forget that ", "dont forget that ", "don't forget ", "keep in mind that "]
    private static let fillers = ["please ", "cortana, ", "cortana ", "hey cortana, "]

    static func extract(from text: String) -> String? {
        var rest = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !rest.hasSuffix("?") else { return nil }
        var lower = rest.lowercased()
        for filler in fillers where lower.hasPrefix(filler) {
            rest = String(rest.dropFirst(filler.count))
            lower = rest.lowercased()
        }
        guard let trigger = triggers.first(where: { lower.hasPrefix($0) }) else { return nil }
        let fact = rest.dropFirst(trigger.count).trimmingCharacters(in: .whitespacesAndNewlines)
        guard fact.count >= 3 else { return nil }
        return fact.prefix(1).uppercased() + fact.dropFirst()
    }
}
