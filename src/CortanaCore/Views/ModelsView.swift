import SwiftUI

/// Model management: pick, download, delete, and see how much space models use.
struct ModelsView: View {
    var manager: ModelManager
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ModelsList(manager: manager)
            .navigationTitle("Models")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { Button("Done") { dismiss() } }
        }
        .preferredColorScheme(.dark)
    }
}

struct ModelsList: View {
    var manager: ModelManager

    var body: some View {
        List {
            Section {
                ForEach(ModelCatalog.all) { model in
                    ModelRow(model: model, manager: manager)
                }
            } footer: {
                Text("Models run entirely on this iPhone. Downloads happen once, then work offline.")
            }
            Section("Storage") {
                LabeledContent("Models on this iPhone", value: ByteCountFormatter.string(fromByteCount: manager.totalInstalledBytes, countStyle: .file))
            }
        }
        .scrollContentBackground(.hidden)
        .background(Theme.background)
    }
}

private struct ModelRow: View {
    let model: ModelOption
    let manager: ModelManager

    private var installed: Bool { manager.isInstalled(model) }
    private var isSelected: Bool { manager.selected.id == model.id }
    private var activity: ModelManager.Activity { manager.activity }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(model.name).font(.headline)
                        if isSelected && installed { Image(systemName: "checkmark.circle.fill").foregroundStyle(Theme.cyan) }
                    }
                    Text(model.detail).font(.footnote).foregroundStyle(.secondary)
                    Text(sizeText).font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                action
            }
            progress
        }
        .padding(.vertical, 4)
        .opacity(model.isSupportedOnThisDevice ? 1 : 0.5)
        .swipeActions {
            if installed && !manager.isBusy {
                Button("Delete", role: .destructive) { manager.delete(model) }
            }
        }
    }

    private var sizeText: String {
        let bytes = installed ? manager.installedBytes(model) : model.approxBytes
        let size = ByteCountFormatter.string(fromByteCount: bytes, countStyle: .file)
        return model.isSupportedOnThisDevice ? size : "\(size) · needs a newer iPhone"
    }

    @ViewBuilder private var action: some View {
        if !model.isSupportedOnThisDevice {
            EmptyView()
        } else if isActive {
            Button("Cancel") { manager.cancel() }.buttonStyle(.bordered)
        } else if installed && isSelected {
            Text("In use").font(.footnote).foregroundStyle(Theme.cyan)
        } else if installed {
            Button("Use") { manager.activate(model) }.buttonStyle(.borderedProminent).disabled(manager.isBusy)
        } else {
            Button("Get") { manager.activate(model) }.buttonStyle(.borderedProminent).disabled(manager.isBusy)
        }
    }

    private var isActive: Bool {
        switch activity {
        case .downloading(let id, _), .loading(let id): id == model.id
        default: false
        }
    }

    @ViewBuilder private var progress: some View {
        switch activity {
        case .downloading(let id, let fraction) where id == model.id:
            DownloadProgressBar(fraction: fraction, totalBytes: model.approxBytes)
        case .loading(let id) where id == model.id:
            ProgressView().progressViewStyle(.linear).tint(Theme.cyan)
            Text("Loading into memory…").font(.caption).foregroundStyle(.secondary)
        case .failed(let id, let message) where id == model.id:
            Text(message).font(.caption).foregroundStyle(.red)
        default:
            EmptyView()
        }
    }
}

struct DownloadProgressBar: View {
    let fraction: Double
    let totalBytes: Int64

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            ProgressView(value: fraction).tint(Theme.cyan)
            Text("\(ByteCountFormatter.string(fromByteCount: Int64(fraction * Double(totalBytes)), countStyle: .file)) of \(ByteCountFormatter.string(fromByteCount: totalBytes, countStyle: .file)) · \(Int(fraction * 100))%")
                .font(.caption).foregroundStyle(.secondary).monospacedDigit()
        }
    }
}

/// Shown at the top of the chat while a model downloads or loads, or when none is installed yet.
struct ModelStatusBanner: View {
    let manager: ModelManager
    let openModels: () -> Void

    var body: some View {
        switch manager.activity {
        case .downloading(_, let fraction):
            card {
                Text("Downloading \(manager.selected.name)").font(.subheadline.bold())
                DownloadProgressBar(fraction: fraction, totalBytes: manager.selected.approxBytes)
                Button("Cancel", action: manager.cancel).font(.footnote)
            }
        case .loading:
            card {
                Text("Waking up \(manager.selected.name)…").font(.subheadline.bold())
                ProgressView().progressViewStyle(.linear).tint(Theme.cyan)
            }
        case .failed(_, let message):
            card {
                Text("Model problem").font(.subheadline.bold())
                Text(message).font(.caption).foregroundStyle(.secondary)
                Button("Retry") { manager.activate(manager.selected) }.font(.footnote)
            }
        case .idle where !manager.isInstalled(manager.selected):
            card {
                Text("Cortana needs her brain, Chief.").font(.subheadline.bold())
                Text("\(manager.selected.name) · \(ByteCountFormatter.string(fromByteCount: manager.selected.approxBytes, countStyle: .file)), one-time download")
                    .font(.caption).foregroundStyle(.secondary)
                HStack {
                    Button("Download") { manager.activate(manager.selected) }.buttonStyle(.borderedProminent)
                    Button("Choose model", action: openModels).buttonStyle(.bordered)
                }
            }
        default:
            EmptyView()
        }
    }

    private func card<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8, content: content)
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.assistantBubble, in: RoundedRectangle(cornerRadius: 16))
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Theme.cortanaBlue.opacity(0.4)))
            .padding(.horizontal, 16)
    }
}
