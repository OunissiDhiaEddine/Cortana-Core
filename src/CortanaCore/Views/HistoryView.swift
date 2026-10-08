import SwiftData
import SwiftUI

/// Saved conversations: search, rename, delete, start a new chat.
struct HistoryView: View {
    let chat: ChatViewModel
    let store: ConversationStore
    @Environment(\.dismiss) private var dismiss
    @State private var search = ""
    @State private var renaming: Conversation?
    @State private var renameText = ""

    var body: some View {
        NavigationStack {
            ConversationList(search: search, selected: chat.current, onOpen: open, onRename: beginRename, onDelete: delete)
                .searchable(text: $search, prompt: "Search chats")
                .navigationTitle("Chats")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) { Button("Done") { dismiss() } }
                    ToolbarItem(placement: .topBarTrailing) {
                        Button { chat.newChat(); dismiss() } label: { Image(systemName: "square.and.pencil") }
                            .accessibilityLabel("New chat")
                    }
                }
                .alert("Rename chat", isPresented: Binding(get: { renaming != nil }, set: { if !$0 { renaming = nil } })) {
                    TextField("Title", text: $renameText)
                    Button("Save") { if let renaming { store.rename(renaming, to: renameText) } }
                    Button("Cancel", role: .cancel) {}
                }
        }
        .preferredColorScheme(.dark)
    }

    private func open(_ conversation: Conversation) {
        chat.open(conversation)
        dismiss()
    }

    private func beginRename(_ conversation: Conversation) {
        renameText = conversation.title
        renaming = conversation
    }

    private func delete(_ conversation: Conversation) {
        chat.conversationDeleted(conversation)
        store.delete(conversation)
    }
}

private struct ConversationList: View {
    @Query private var conversations: [Conversation]
    let selected: Conversation?
    let onOpen: (Conversation) -> Void
    let onRename: (Conversation) -> Void
    let onDelete: (Conversation) -> Void

    init(search: String, selected: Conversation?,
         onOpen: @escaping (Conversation) -> Void,
         onRename: @escaping (Conversation) -> Void,
         onDelete: @escaping (Conversation) -> Void) {
        let query = search.trimmingCharacters(in: .whitespaces)
        let predicate: Predicate<Conversation>? = query.isEmpty ? nil : #Predicate { conversation in
            conversation.title.localizedStandardContains(query)
                || conversation.messages.contains { $0.text.localizedStandardContains(query) }
        }
        _conversations = Query(filter: predicate, sort: \.updatedAt, order: .reverse)
        self.selected = selected
        self.onOpen = onOpen
        self.onRename = onRename
        self.onDelete = onDelete
    }

    var body: some View {
        if conversations.isEmpty {
            ContentUnavailableView("No chats yet", systemImage: "bubble.left.and.bubble.right",
                                   description: Text("Your conversations with Cortana show up here."))
        } else {
            List {
                ForEach(HistoryGroup.allCases, id: \.self) { group in
                    let items = conversations.filter { HistoryGroup(for: $0.updatedAt) == group }
                    if !items.isEmpty {
                        Section(group.title) {
                            ForEach(items) { conversation in
                                Button { onOpen(conversation) } label: {
                                    HStack {
                                        Text(conversation.title).lineLimit(1)
                                        Spacer()
                                        if conversation === selected {
                                            Image(systemName: "checkmark").foregroundStyle(Theme.cyan)
                                        }
                                    }
                                }
                                .foregroundStyle(.primary)
                                .swipeActions {
                                    Button("Delete", role: .destructive) { onDelete(conversation) }
                                    Button("Rename") { onRename(conversation) }.tint(Theme.cortanaBlue)
                                }
                                .contextMenu {
                                    Button("Rename", systemImage: "pencil") { onRename(conversation) }
                                    Button("Delete", systemImage: "trash", role: .destructive) { onDelete(conversation) }
                                }
                            }
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Theme.background)
        }
    }
}

enum HistoryGroup: CaseIterable {
    case today, yesterday, week, older

    init(for date: Date, now: Date = .now, calendar: Calendar = .current) {
        if calendar.isDate(date, inSameDayAs: now) { self = .today }
        else if calendar.isDateInYesterday(date) { self = .yesterday }
        else if let days = calendar.dateComponents([.day], from: date, to: now).day, days < 7 { self = .week }
        else { self = .older }
    }

    var title: String {
        switch self {
        case .today: "Today"
        case .yesterday: "Yesterday"
        case .week: "Previous 7 days"
        case .older: "Older"
        }
    }
}
