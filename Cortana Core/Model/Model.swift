import Foundation
import SwiftUI

final class Network: ObservableObject {
    
    @Published var response: TranslationResponse
    @Published var prompt: String = "Hello"
    
    init(response: TranslationResponse) {
        self.response = response
    }
    
    // Function to fetch response from the Gemini API
    func getGeminiResponse() {
        let apiKey = ProcessInfo.processInfo.environment["API_KEY"] ?? ""
        guard let url = URL(string: apiKey) else {
            fatalError("Missing URL")
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Structure for the Gemini request body
        let requestBody: [String: Any] = [
            "contents": [
                [
                    "parts": [
                        ["text": prompt]
                    ]
                ]
            ]
        ]
        
        // Convert request body to JSON data
        guard let httpBody = try? JSONSerialization.data(withJSONObject: requestBody) else {
            print("Error encoding JSON data")
            return
        }
        
        urlRequest.httpBody = httpBody
        
        let dataTask = URLSession.shared.dataTask(with: urlRequest) { (data, response, error) in
            if let error = error {
                print("Request error: ", error)
                return
            }
            
            guard let response = response as? HTTPURLResponse else { return }
            
            print("Status Code: \(response.statusCode)")
            
            if response.statusCode == 200 {
                guard let data = data else { return }
                
                DispatchQueue.main.async {
                    do {
                        // Debug: Print raw JSON response
                        let jsonString = String(data: data, encoding: .utf8)
                        print("Raw JSON Response: \(String(describing: jsonString))")
                        
                        // Decode the JSON response from Gemini
                        if let jsonResponse = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                           let candidates = jsonResponse["candidates"] as? [[String: Any]],
                           let content = candidates.first?["content"] as? [String: Any],
                           let parts = content["parts"] as? [[String: Any]],
                           let botResponse = parts.first?["text"] as? String {
                            print("Gemini Response: \(botResponse)")
                            self.response = TranslationResponse(id: "gemini_response", object: "text", created: Int(Date().timeIntervalSince1970), choices: [TranslationResponse.TextCompletionChoice(index: 0, message: Messages(role: "assistant", content: botResponse), finish_reason: "complete")])
                        } else {
                            print("Error parsing Gemini response")
                        }
                    } catch let error {
                        print("Error decoding: ", error)
                    }
                }
            } else {
                print("Failed with status code: \(response.statusCode)")
            }
        }
        dataTask.resume()
    }
}

// Request and response data structures
struct RequestData: Codable {
    var model: String
    var messages: [Messages]
}

struct Messages: Codable {
    let role: String
    let content: String
}

struct TranslationResponse: Decodable {
    var id: String
    var object: String
    var created: Int
    var choices: [TextCompletionChoice]
    
    var resultText: String {
        choices.map(\.message.content).joined(separator: "\n")
    }
}

extension TranslationResponse {
    struct TextCompletionChoice: Decodable {
        var index: Int
        var message: Messages
        var finish_reason: String
    }
}
