import Foundation
import HuggingFace

/// Looks at the Hugging Face hub cache on disk so the UI can show what is installed and how big it is.
enum ModelStorage {
    private static var cacheRoot: URL { HubCache.default.cacheDirectory }

    static func folder(for model: ModelOption) -> URL {
        cacheRoot.appendingPathComponent(model.cacheFolderName, isDirectory: true)
    }

    static func bytesOnDisk(_ model: ModelOption) -> Int64 {
        let keys: Set<URLResourceKey> = [.totalFileAllocatedSizeKey, .isRegularFileKey]
        guard let walker = FileManager.default.enumerator(
            at: folder(for: model), includingPropertiesForKeys: Array(keys)) else { return 0 }
        var total: Int64 = 0
        for case let url as URL in walker {
            guard let values = try? url.resourceValues(forKeys: keys), values.isRegularFile == true else { continue }
            total += Int64(values.totalFileAllocatedSize ?? 0)
        }
        return total
    }

    /// Fully downloaded: no partial blobs left and most of the expected bytes are present.
    static func isInstalled(_ model: ModelOption) -> Bool {
        let blobs = folder(for: model).appendingPathComponent("blobs")
        let names = (try? FileManager.default.contentsOfDirectory(atPath: blobs.path)) ?? []
        guard !names.isEmpty, !names.contains(where: { $0.hasSuffix(".incomplete") }) else { return false }
        return bytesOnDisk(model) > model.approxBytes / 2
    }

    static func delete(_ model: ModelOption) throws {
        let url = folder(for: model)
        if FileManager.default.fileExists(atPath: url.path) {
            try FileManager.default.removeItem(at: url)
        }
    }
}
