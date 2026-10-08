import Foundation
import MLXLMCommon

/// A downloadable on-device model. The catalog below is the one place models are chosen.
/// See docs/model-runtime.md for why MLX and why Qwen3.
struct ModelOption: Identifiable, Hashable, Sendable {
    /// Hugging Face repo id, e.g. `mlx-community/Qwen3-1.7B-4bit`.
    let id: String
    let name: String
    let detail: String
    /// Approximate download size, used for the progress readout and the "installed" sanity check.
    let approxBytes: Int64
    /// Minimum physical RAM (GB) the model is comfortable on; smaller devices see it disabled.
    let minRAMGB: Int

    var configuration: ModelConfiguration { ModelConfiguration(id: id) }

    /// Folder name inside the Hugging Face hub cache (`models--org--name`).
    var cacheFolderName: String { "models--" + id.replacingOccurrences(of: "/", with: "--") }

    var isSupportedOnThisDevice: Bool {
        ProcessInfo.processInfo.physicalMemory >= UInt64(minRAMGB) * 900_000_000
    }
}

enum ModelCatalog {
    static let lite = ModelOption(
        id: "mlx-community/Qwen3-0.6B-4bit", name: "Cortana Lite",
        detail: "Fastest and smallest. Good for quick questions.",
        approxBytes: 350_000_000, minRAMGB: 4)
    static let core = ModelOption(
        id: "mlx-community/Qwen3-1.7B-4bit", name: "Cortana Core",
        detail: "Balanced speed and quality. Recommended.",
        approxBytes: 980_000_000, minRAMGB: 6)
    static let prime = ModelOption(
        id: "mlx-community/Qwen3-4B-4bit", name: "Cortana Prime",
        detail: "Smartest, slower. Needs 8 GB of RAM.",
        approxBytes: 2_300_000_000, minRAMGB: 8)

    static let all = [lite, core, prime]
    static let `default` = core

    static func option(id: String) -> ModelOption? { all.first { $0.id == id } }
}
