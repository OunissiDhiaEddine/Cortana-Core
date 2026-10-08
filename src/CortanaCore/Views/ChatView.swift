import SwiftUI

struct ChatView: View {
    @Bindable var model: ChatViewModel
    var models: ModelManager
    @FocusState private var inputFocused: Bool
    @State private var showModels = false

    var body: some View {
        VStack(spacing: 0) {
            header
            ModelStatusBanner(manager: models) { showModels = true }
            messageList
            inputBar
        }
        .background(Theme.background)
        .preferredColorScheme(.dark)
        .sheet(isPresented: $showModels) { ModelsView(manager: models) }
    }

    private var header: some View {
        VStack(spacing: 6) {
            CortanaOrb(phase: model.phase, size: 72)
            Text(model.phase.caption)
                .font(.footnote)
                .foregroundStyle(Theme.cyan.opacity(0.8))
                .animation(.default, value: model.phase)
        }
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity)
        .overlay(alignment: .topTrailing) {
            Button { showModels = true } label: {
                Image(systemName: "cpu").font(.title3).foregroundStyle(Theme.cyan).padding(16)
            }
            .accessibilityLabel("Models")
        }
    }

    private var messageList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 10) {
                    ForEach(model.messages) { message in
                        MessageBubble(message: message, showTyping: model.phase == .thinking && message.id == model.messages.last?.id)
                            .id(message.id)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 8)
            }
            .scrollDismissesKeyboard(.interactively)
            .onChange(of: model.messages.last?.text) {
                if let id = model.messages.last?.id {
                    proxy.scrollTo(id, anchor: .bottom)
                }
            }
        }
    }

    private var inputBar: some View {
        HStack(spacing: 10) {
            TextField(models.loadedID == nil ? "Waiting for a model…" : "Ask Cortana", text: $model.input, axis: .vertical)
                .lineLimit(1...4)
                .focused($inputFocused)
                .padding(.horizontal, 16).padding(.vertical, 10)
                .background(Theme.assistantBubble, in: RoundedRectangle(cornerRadius: 22))
                .overlay(RoundedRectangle(cornerRadius: 22).stroke(Theme.cortanaBlue.opacity(inputFocused ? 0.8 : 0.25)))
                .submitLabel(.send)
                .onSubmit { if models.loadedID != nil { model.send() } }

            Button {
                model.isResponding ? model.stop() : model.send()
            } label: {
                Image(systemName: model.isResponding ? "stop.circle.fill" : "arrow.up.circle.fill")
                    .font(.system(size: 34))
                    .foregroundStyle(Theme.cortanaBlue)
            }
            .disabled(models.loadedID == nil && !model.isResponding)
            .accessibilityLabel(model.isResponding ? "Stop" : "Send")
        }
        .padding(.horizontal, 16).padding(.vertical, 10)
    }
}

private struct MessageBubble: View {
    let message: ChatMessage
    let showTyping: Bool

    var body: some View {
        let isUser = message.role == .user
        HStack {
            if isUser { Spacer(minLength: 48) }
            Group {
                if showTyping {
                    Text("…").foregroundStyle(Theme.cyan)
                } else {
                    Text(markdown(message.text))
                }
            }
            .padding(.horizontal, 14).padding(.vertical, 10)
            .foregroundStyle(.white)
            .background(isUser ? Theme.userBubble : Theme.assistantBubble, in: RoundedRectangle(cornerRadius: 20))
            .textSelection(.enabled)
            if !isUser { Spacer(minLength: 48) }
        }
    }

    /// Inline markdown (bold, italics, code, links) that tolerates half-streamed text.
    private func markdown(_ text: String) -> AttributedString {
        let options = AttributedString.MarkdownParsingOptions(interpretedSyntax: .inlineOnlyPreservingWhitespace)
        return (try? AttributedString(markdown: text, options: options)) ?? AttributedString(text)
    }
}

#Preview {
    let engine = PlaceholderEngine()
    ChatView(model: ChatViewModel(engine: engine), models: ModelManager(engine: engine))
}
