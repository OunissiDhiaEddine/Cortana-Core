import SwiftData
import SwiftUI

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
