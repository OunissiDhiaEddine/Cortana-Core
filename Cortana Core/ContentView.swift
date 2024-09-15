import SwiftUI

struct ContentView: View {
    @State private var messageText = ""
    @State var messages: [String] = ["Hi there chief ! How can i help today ? "]
    
    @ObservedObject var network = Network(response: TranslationResponse(id: "", object: "", created: 0, choices: [])) // Initialize Network

    
    var body: some View {
        VStack {
            HStack {
                Text("Cortana Core")
                    .font(.largeTitle)
                    .bold()
                
                Image("customImage")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 50, height: 50)
                                    .clipShape(Circle())
                                    .padding(0)
                            }
            
            ScrollView {
                ForEach(messages, id: \.self) { message in
                    if message.contains("[USER]") {
                        let newMessage = message.replacingOccurrences(of: "[USER]", with: "")
                        HStack {
                            Spacer()
                            Text(newMessage)
                                .padding()
                                .foregroundColor(Color.white)
                                .background(Color.blue.opacity(0.8))
                                .cornerRadius(10)
                                .padding(.horizontal, 16)
                                .padding(.bottom, 10)
                        }
                    } else {
                        HStack {
                            Text(message)
                                .padding()
                                .background(Color.gray.opacity(0.15))
                                .cornerRadius(10)
                                .padding(.horizontal, 16)
                                .padding(.bottom, 10)
                                .font(.system(size: 17))
                            Spacer()
                        }
                    }
                }.rotationEffect(.degrees(180))
            }
            .rotationEffect(.degrees(180))
            .background(Color.gray.opacity(0.1))
            
            HStack {
                TextField("Type something", text: $messageText)
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(10)
                    .onSubmit {
                        sendMessage(message: messageText)
                    }
                
                Button {
                    sendMessage(message: messageText)
                } label: {
                    Image(systemName: "paperplane.fill")
                }
                .font(.system(size: 26))
                .padding(.horizontal, 10)
            }
            .padding()
        }
    }
    
    func sendMessage(message: String) {
        withAnimation {
            messages.append("[USER]" + message)
            self.messageText = ""

            // Update the prompt and make the Gemini API call
            network.prompt = message
            network.getGeminiResponse() // Call Gemini response function

            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {  // Allow for a short delay
                withAnimation {
                    // Add the response from Gemini to the messages array once available
                    let botResponse = network.response.resultText
                    messages.append(botResponse)
                }
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
