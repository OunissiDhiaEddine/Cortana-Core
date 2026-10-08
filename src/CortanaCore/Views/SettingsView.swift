import SwiftData
import SwiftUI

struct SettingsView: View {
    let chat: ChatViewModel
    let models: ModelManager
    let store: ConversationStore
    let memory: MemoryStore
    @Environment(\.dismiss) private var dismiss

    @AppStorage(SettingsKey.systemPrompt) private var systemPrompt = SettingsDefault.systemPrompt
    @AppStorage(SettingsKey.temperature) private var temperature = SettingsDefault.temperature
    @AppStorage(SettingsKey.maxTokens) private var maxTokens = SettingsDefault.maxTokens
    @AppStorage(SettingsKey.maxHistory) private var maxHistory = SettingsDefault.maxHistory
    @AppStorage(SettingsKey.memoryEnabled) private var memoryEnabled = SettingsDefault.memoryEnabled
    @Query private var memories: [Memory]
    @Query private var conversations: [Conversation]
    @State private var confirmClearChats = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Model") {
                    NavigationLink {
                        ModelsList(manager: models).navigationTitle("Models")
                    } label: {
                        LabeledContent("Active model", value: models.selected.name)
                    }
                }

                Section {
                    NavigationLink {
                        PersonaEditor(prompt: $systemPrompt)
                    } label: {
                        LabeledContent("Persona", value: systemPrompt == SettingsDefault.systemPrompt ? "Cortana" : "Custom")
                    }
                } header: {
                    Text("Personality")
                }

                Section {
                    Toggle("Remember things", isOn: $memoryEnabled)
                    NavigationLink {
                        MemoryView(memory: memory)
                    } label: {
                        LabeledContent("Saved memories", value: "\(memories.count)")
                    }
                } header: {
                    Text("Memory")
                } footer: {
                    Text("Say \"remember that …\" and Cortana keeps it for future chats. Memories stay on this iPhone.")
                }

                Section {
                    VStack(alignment: .leading) {
                        LabeledContent("Creativity", value: temperature.formatted(.number.precision(.fractionLength(1))))
                        Slider(value: $temperature, in: 0...1.2, step: 0.1)
                    }
                    Stepper("Max reply length: \(maxTokens)", value: $maxTokens, in: 128...1024, step: 128)
                    Stepper("Context: last \(maxHistory) messages", value: $maxHistory, in: 4...24, step: 2)
                } header: {
                    Text("Generation")
                } footer: {
                    Text("Longer replies and more context use more memory and are slower.")
                }

                Section("Storage") {
                    LabeledContent("Models", value: ByteCountFormatter.string(fromByteCount: models.totalInstalledBytes, countStyle: .file))
                    LabeledContent("Chats", value: "\(conversations.count)")
                    Button("Delete all chats", role: .destructive) { confirmClearChats = true }
                        .disabled(conversations.isEmpty)
                }

                Section {
                    Button("Reset settings to defaults") { reset() }
                }

                Section("About") {
                    LabeledContent("Version", value: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")
                    Text("Cortana runs fully on this iPhone. No account, no cloud.").font(.footnote).foregroundStyle(.secondary)
                }
            }
            .scrollContentBackground(.hidden)
            .background(Theme.background)
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { Button("Done") { dismiss() } }
            .confirmationDialog("Delete all chats?", isPresented: $confirmClearChats, titleVisibility: .visible) {
                Button("Delete all chats", role: .destructive) {
                    store.deleteAll()
                    chat.newChat()
                }
            } message: {
                Text("This can't be undone.")
            }
        }
        .preferredColorScheme(.dark)
    }

    private func reset() {
        systemPrompt = SettingsDefault.systemPrompt
        temperature = SettingsDefault.temperature
        maxTokens = SettingsDefault.maxTokens
        maxHistory = SettingsDefault.maxHistory
        memoryEnabled = SettingsDefault.memoryEnabled
    }
}

private struct PersonaEditor: View {
    @Binding var prompt: String

    var body: some View {
        Form {
            Section {
                TextEditor(text: $prompt).frame(minHeight: 320).font(.callout)
            } footer: {
                Text("This is the instruction Cortana starts every chat with. Short, concrete rules work best on a small model.")
            }
            Section {
                Button("Restore Cortana default") { prompt = SettingsDefault.systemPrompt }
                    .disabled(prompt == SettingsDefault.systemPrompt)
            }
        }
        .scrollContentBackground(.hidden)
        .background(Theme.background)
        .navigationTitle("Persona")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct MemoryView: View {
    let memory: MemoryStore
    @Query(sort: \Memory.createdAt, order: .reverse) private var memories: [Memory]
    @State private var newFact = ""
    @State private var confirmClear = false

    var body: some View {
        List {
            Section {
                HStack {
                    TextField("Add something to remember", text: $newFact).onSubmit(add)
                    Button("Add", action: add).disabled(newFact.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            if memories.isEmpty {
                Section {
                    Text("Nothing saved yet. Try telling Cortana: \"Remember that I prefer short answers.\"")
                        .font(.footnote).foregroundStyle(.secondary)
                }
            } else {
                Section("Saved") {
                    ForEach(memories) { item in
                        Text(item.text).swipeActions { Button("Delete", role: .destructive) { memory.delete(item) } }
                    }
                }
                Section {
                    Button("Clear all memories", role: .destructive) { confirmClear = true }
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(Theme.background)
        .navigationTitle("Memory")
        .navigationBarTitleDisplayMode(.inline)
        .confirmationDialog("Clear all memories?", isPresented: $confirmClear, titleVisibility: .visible) {
            Button("Clear all memories", role: .destructive) { memory.clear() }
        }
    }

    private func add() {
        if memory.add(newFact) { newFact = "" }
    }
}
