import SwiftUI

struct ChatView: View {
    @Bindable var model: ChatViewModel

    var body: some View {
        VStack {
            HStack {
                Text("Cortana Core")
                    .font(.largeTitle).bold()
                Image("customImage")
                    .resizable().scaledToFit()
                    .frame(width: 50, height: 50)
                    .clipShape(Circle())
            }

            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 10) {
                        ForEach(model.messages) { message in
                            bubble(message)
                        }
                    }
                    .padding(.horizontal, 16)
                }
                .onChange(of: model.messages.last?.text) {
                    if let id = model.messages.last?.id {
                        proxy.scrollTo(id, anchor: .bottom)
                    }
                }
            }

            HStack {
                TextField("Type something", text: $model.input)
                    .padding()
                    .background(Color.white)
                    .cornerRadius(20)
                    .onSubmit { model.send() }

                Button { model.send() } label: {
                    Image(systemName: "paperplane.fill")
                }
                .font(.system(size: 26))
                .padding(.horizontal, 10)
                .disabled(model.isResponding)
            }
            .padding()
        }
        .background(
            Image("Background")
                .resizable().scaledToFill()
                .ignoresSafeArea()
        )
    }

    @ViewBuilder
    private func bubble(_ message: ChatMessage) -> some View {
        let isUser = message.role == .user
        HStack {
            if isUser { Spacer() }
            Text(message.text)
                .padding()
                .foregroundColor(isUser ? .white : .primary)
                .background(isUser ? Color.blue.opacity(0.8) : Color.gray.opacity(0.3))
                .cornerRadius(20)
            if !isUser { Spacer() }
        }
        .id(message.id)
    }
}

#Preview {
    ChatView(model: ChatViewModel(engine: PlaceholderEngine()))
}
