import Foundation
import Combine

class ChatService: ObservableObject {
    // Backend URL - change this to your actual backend URL
   //private let baseURL = "http://localhost:8000"
    private let baseURL = "http://10.68.96.57:8000"
    
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var isConnected = false
    
    // UserDefaults keys
    private let userDefaults = UserDefaults.standard
    private let chatHistoryKey = "chat_history"
    private let modeHistoryKey = "mode_history"
    
    init() {
        // Test connection on init
        Task {
            await testConnection()
        }
    }
    
    // MARK: - Chat History Management
    
    func saveChatHistory(_ messages: [ChatMessage]) {
        do {
            let data = try JSONEncoder().encode(messages)
            userDefaults.set(data, forKey: chatHistoryKey)
        } catch {
            print("Error saving chat history: \(error)")
        }
    }
    
    func loadChatHistory() -> [ChatMessage] {
        guard let data = userDefaults.data(forKey: chatHistoryKey) else {
            return []
        }
        
        do {
            let messages = try JSONDecoder().decode([ChatMessage].self, from: data)
            return messages
        } catch {
            print("Error loading chat history: \(error)")
            return []
        }
    }
    
    func clearChatHistory() {
        userDefaults.removeObject(forKey: chatHistoryKey)
        userDefaults.removeObject(forKey: modeHistoryKey)
    }
    
    func clearServerHistory(mode: ChatMode? = nil) async {
        do {
            var urlString = "\(baseURL)/clear-history"
            if let mode = mode {
                urlString += "?mode=\(mode.rawValue)"
            }
            
            let url = URL(string: urlString)!
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            
            let (_, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode == 200 {
                    print("Server history cleared successfully")
                } else {
                    print("Failed to clear server history: \(httpResponse.statusCode)")
                }
            }
        } catch {
            print("Error clearing server history: \(error)")
        }
    }
    
    func saveSelectedMode(_ mode: ChatMode) {
        userDefaults.set(mode.rawValue, forKey: modeHistoryKey)
    }
    
    func loadSelectedMode() -> ChatMode {
        guard let modeString = userDefaults.string(forKey: modeHistoryKey),
              let mode = ChatMode(rawValue: modeString) else {
            return .support
        }
        return mode
    }
    
    func testConnection() async {
        do {
            let url = URL(string: "\(baseURL)/health")!
            let (_, response) = try await URLSession.shared.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                await MainActor.run {
                    isConnected = false
                }
                return
            }
            
            await MainActor.run {
                isConnected = httpResponse.statusCode == 200
            }
        } catch {
            await MainActor.run {
                isConnected = false
            }
        }
    }
    
    func retryConnection() async {
        await testConnection()
    }
    
    func sendMessage(_ message: String, mode: ChatMode) async -> String? {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        
        do {
            let request = ChatRequest(message: message, mode: mode)
            let url = URL(string: "\(baseURL)/chat")!
            
            var urlRequest = URLRequest(url: url)
            urlRequest.httpMethod = "POST"
            urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
            urlRequest.httpBody = try JSONEncoder().encode(request)
            
            let (data, response) = try await URLSession.shared.data(for: urlRequest)
            
            await MainActor.run {
                isLoading = false
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                await MainActor.run {
                    errorMessage = "Invalid response from server"
                }
                return nil
            }
            
            if httpResponse.statusCode == 200 {
                let chatResponse = try JSONDecoder().decode(ChatResponse.self, from: data)
                return chatResponse.response
            } else {
                let errorText = String(data: data, encoding: .utf8) ?? "Unknown error"
                await MainActor.run {
                    errorMessage = "Server error: \(errorText)"
                }
                return nil
            }
            
        } catch {
            await MainActor.run {
                isLoading = false
                errorMessage = "Network error: \(error.localizedDescription)"
            }
            return nil
        }
    }
} 
