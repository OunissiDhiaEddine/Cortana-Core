import Foundation
import Observation

/// Owns model lifecycle for the UI: which model is selected, download/load progress, installed sizes.
@MainActor
@Observable
final class ModelManager {
    enum Activity: Equatable {
        case idle
        case downloading(modelID: String, fraction: Double)
        case loading(modelID: String)
        case failed(modelID: String, message: String)
    }

    private(set) var activity: Activity = .idle
    private(set) var selected: ModelOption
    private(set) var loadedID: String?
    /// Installed flag and size per model id. Cached because walking the disk on every redraw is slow.
    private(set) var storage: [String: StorageInfo] = [:]

    struct StorageInfo: Equatable, Sendable {
        var installed: Bool
        var bytes: Int64
    }

    private let engine: ChatEngine
    private var task: Task<Void, Never>?
    private let defaults: UserDefaults
    private static let selectedKey = "selectedModelID"

    init(engine: ChatEngine, defaults: UserDefaults = .standard) {
        self.engine = engine
        self.defaults = defaults
        let saved = defaults.string(forKey: Self.selectedKey).flatMap(ModelCatalog.option(id:))
        selected = saved ?? ModelCatalog.default
        storage = Self.scan(engine)
    }

    var isBusy: Bool { activity != .idle && !isFailed }
    private var isFailed: Bool { if case .failed = activity { true } else { false } }

    func isInstalled(_ model: ModelOption) -> Bool { storage[model.id]?.installed ?? false }
    func installedBytes(_ model: ModelOption) -> Int64 { storage[model.id]?.bytes ?? 0 }
    var totalInstalledBytes: Int64 { ModelCatalog.all.reduce(0) { $0 + installedBytes($1) } }

    /// Called at launch: load the selected model if it is already on disk. Never starts a surprise download.
    func prepareSelected() {
        guard isInstalled(selected), loadedID != selected.id else { return }
        start(selected)
    }

    /// Download (if needed), load and switch to `model`.
    func activate(_ model: ModelOption) {
        guard model.isSupportedOnThisDevice, !isBusy else { return }
        selected = model
        defaults.set(model.id, forKey: Self.selectedKey)
        start(model)
    }

    func cancel() {
        task?.cancel()
    }

    func delete(_ model: ModelOption) {
        guard !isBusy else { return }
        Task {
            if loadedID == model.id { loadedID = nil }
            try? await engine.delete(model)
            await refreshStorage()
        }
    }

    /// Free memory without touching files, e.g. when the app goes to the background.
    func unloadFromMemory() {
        guard loadedID != nil, !isBusy else { return }
        loadedID = nil
        let previous = task
        task = Task {
            await previous?.value
            await engine.unload()
        }
    }

    private func start(_ model: ModelOption) {
        let needsDownload = !engine.isInstalled(model)
        activity = needsDownload ? .downloading(modelID: model.id, fraction: 0) : .loading(modelID: model.id)
        let previous = task
        let onProgress: @Sendable (DownloadProgress) -> Void = { [weak self] progress in
            Task { @MainActor in self?.report(progress, for: model) }
        }
        task = Task {
            await previous?.value
            do {
                try await engine.load(model, onProgress: onProgress)
                loadedID = model.id
                activity = .idle
            } catch is CancellationError {
                activity = .idle
            } catch {
                Log.engine.error("model load failed: \(error.localizedDescription)")
                activity = Task.isCancelled ? .idle : .failed(modelID: model.id, message: error.localizedDescription)
            }
            await refreshStorage()
        }
    }

    private func refreshStorage() async {
        let engine = engine
        storage = await Task.detached { Self.scan(engine) }.value
    }

    nonisolated private static func scan(_ engine: ChatEngine) -> [String: StorageInfo] {
        Dictionary(uniqueKeysWithValues: ModelCatalog.all.map { model in
            (model.id, StorageInfo(installed: engine.isInstalled(model), bytes: engine.installedBytes(model)))
        })
    }

    private func report(_ progress: DownloadProgress, for model: ModelOption) {
        guard case .downloading = activity else { return }
        // Downloads report 0...1; once complete the weights are being mapped into memory.
        activity = progress.fraction >= 0.999
            ? .loading(modelID: model.id)
            : .downloading(modelID: model.id, fraction: progress.fraction)
    }
}
