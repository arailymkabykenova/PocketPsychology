import Foundation
import Combine

class ChatService: ObservableObject {
    // Backend URL - change this to your actual backend URL
    //private let baseURL = "http://localhost:8000"
    private let baseURL = "https://pinkponys.org"
    
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var isConnected = false
    
    // User management
    @Published var currentUserId: String = ""
    @Published var currentTopic: String?
    @Published var isGeneratingContent = false
    @Published var isGeneratingContentForTopic = false
    
    // Computed property for easy access to user ID
    var userId: String {
        return currentUserId
    }
    
    // Language support
    @Published var currentLanguage: Language = .russian
    
    // UserDefaults keys
    private let userDefaults = UserDefaults.standard
    private let chatHistoryKey = "chat_history"
    private let modeHistoryKey = "mode_history"
    private let userIdKey = "user_id"
    private let currentTopicKey = "current_topic"
    private let languageKey = "chat_language"
    
    init() {
        // Generate or load user ID
        if let savedUserId = userDefaults.string(forKey: userIdKey) {
            self.currentUserId = savedUserId
            print("🔄 ChatService: Loaded existing user_id: '\(currentUserId)'")
        } else {
            self.currentUserId = UUID().uuidString
            userDefaults.set(self.currentUserId, forKey: userIdKey)
            print("🆕 ChatService: Generated new user_id: '\(currentUserId)'")
        }
        
        // Load current topic
        self.currentTopic = userDefaults.string(forKey: currentTopicKey)
        
        // Load current language
        if let savedLanguage = userDefaults.string(forKey: languageKey),
           let language = Language(rawValue: savedLanguage) {
            self.currentLanguage = language
        }
        
        // Test connection on init
        DispatchQueue.main.async {
            Task {
                await self.testConnection()
            }
        }
    }
    
    // MARK: - User Management
    
    func updateCurrentTopic(_ topic: String?) {
        let oldTopic = self.currentTopic
        self.currentTopic = topic
        userDefaults.set(topic, forKey: currentTopicKey)
        
        if let newTopic = topic {
            print("💬 ChatService: Topic updated: '\(oldTopic ?? "nil")' -> '\(newTopic)'")
        } else {
            print("💬 ChatService: Topic cleared: '\(oldTopic ?? "nil")' -> 'nil'")
        }
    }
    
    func forceTopicRefresh() {
        print("🔄 ChatService: Forcing topic refresh")
        self.updateCurrentTopic(nil)
        // Clear any cached content to force fresh content loading
        userDefaults.removeObject(forKey: "daily_quote")
        userDefaults.removeObject(forKey: "last_quote_date")
    }
    
    func smartUpdateTopic(_ newTopic: String?) {
        // Only update if topic is significantly different
        if let newTopic = newTopic, let currentTopic = self.currentTopic {
            // Check if topics are similar (case-insensitive comparison)
            let normalizedNew = newTopic.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
            let normalizedCurrent = currentTopic.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
            
            if normalizedNew != normalizedCurrent {
                print("🔄 ChatService: Smart topic update: '\(currentTopic)' -> '\(newTopic)'")
                self.updateCurrentTopic(newTopic)
            } else {
                print("ℹ️ ChatService: Topic unchanged: '\(currentTopic)' (similar to '\(newTopic)')")
            }
        } else if newTopic != nil {
            // New topic provided but no current topic
            print("🆕 ChatService: Setting new topic: '\(newTopic!)'")
            self.updateCurrentTopic(newTopic)
        } else {
            // Clearing topic
            print("🗑️ ChatService: Clearing topic")
            self.updateCurrentTopic(nil)
        }
    }
    
    func updateCurrentLanguage(_ language: Language) {
        let oldLanguage = self.currentLanguage
        self.currentLanguage = language
        userDefaults.set(language.rawValue, forKey: languageKey)
        
        // Clear current topic when language changes to force new topic extraction
        if oldLanguage != language {
            print("🌍 ChatService: Language changed from \(oldLanguage.rawValue) to \(language.rawValue), clearing topic")
            self.updateCurrentTopic(nil)
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
        userDefaults.removeObject(forKey: currentTopicKey)
        currentTopic = nil
    }
    
    func clearAllData() {
        // Clear all UserDefaults data
        userDefaults.removeObject(forKey: chatHistoryKey)
        userDefaults.removeObject(forKey: modeHistoryKey)
        userDefaults.removeObject(forKey: userIdKey)
        userDefaults.removeObject(forKey: currentTopicKey)
        userDefaults.removeObject(forKey: languageKey)
        
        // Reset published properties
        currentUserId = ""
        currentTopic = nil
        currentLanguage = .russian
        isLoading = false
        errorMessage = nil
        isGeneratingContent = false
        
        // Generate new user ID
        currentUserId = UUID().uuidString
        userDefaults.set(currentUserId, forKey: userIdKey)
        
        print("🗑️ ChatService: All data cleared, new user_id generated: '\(currentUserId)'")
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
    
    // MARK: - Connection Management
    
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
    
    // MARK: - Chat API
    
    func sendMessage(_ message: String, mode: ChatMode) async -> String? {
        print("🚀 ChatService: Sending message with user_id: '\(currentUserId)'")
        print("📝 Message: '\(message)'")
        print("🎯 Mode: \(mode.rawValue)")
        print("🌍 Language: \(currentLanguage.rawValue)")
        
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        
        do {
            let request = ChatRequest(message: message, mode: mode, user_id: currentUserId, language: currentLanguage.rawValue)
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
                
                print("✅ ChatService: Received response for user_id: '\(currentUserId)'")
                print("📊 Response topic: '\(chatResponse.topic ?? "nil")'")
                print("🆔 Topic task ID: '\(chatResponse.topic_task_id ?? "nil")'")
                
                // Update current topic if provided
                if let topic = chatResponse.topic {
                    await MainActor.run {
                        self.smartUpdateTopic(topic)
                    }
                }
                
                // Start monitoring content generation if tasks are provided
                if let topicTaskId = chatResponse.topic_task_id {
                    Task {
                        await monitorContentGeneration(topicTaskId: topicTaskId)
                    }
                }
                
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
    
    // MARK: - Content Generation Monitoring
    
    private func monitorContentGeneration(topicTaskId: String) async {
        print("🔍 ChatService: Starting topic extraction monitoring for task: \(topicTaskId)")
        await MainActor.run {
            isGeneratingContent = true
        }
        
        // Poll task status every 1.5 seconds for up to 20 seconds (faster, shorter timeout)
        for attempt in 0..<13 {
            do {
                let url = URL(string: "\(baseURL)/task/\(topicTaskId)/status")!
                let (data, response) = try await URLSession.shared.data(from: url)
                
                if let httpResponse = response as? HTTPURLResponse,
                   httpResponse.statusCode == 200 {
                    let taskStatus = try JSONDecoder().decode(TaskStatus.self, from: data)
                    
                    print("📊 ChatService: Task status check \(attempt + 1)/13: \(taskStatus.status)")
                    
                    if taskStatus.status == "completed" {
                        // Task completed successfully
                        if let result = taskStatus.result,
                           let topic = result.topic {
                            await MainActor.run {
                                self.smartUpdateTopic(topic)
                                self.isGeneratingContent = false
                            }
                            print("✅ ChatService: Topic extracted successfully: '\(topic)'")
                        } else {
                            await MainActor.run {
                                self.isGeneratingContent = false
                            }
                            print("⚠️ ChatService: Task completed but no topic found")
                        }
                        return
                    } else if taskStatus.status == "failed" {
                        // Task failed
                        await MainActor.run {
                            self.isGeneratingContent = false
                        }
                        print("❌ ChatService: Topic extraction failed")
                        return
                    } else if taskStatus.status == "pending" {
                        // Task still pending, continue polling
                        print("⏳ ChatService: Topic extraction still pending...")
                    }
                } else {
                    print("⚠️ ChatService: Invalid response from task status endpoint")
                }
            } catch {
                print("❌ ChatService: Error monitoring task: \(error)")
            }
            
            // Wait 1.5 seconds before next poll (faster polling)
            try? await Task.sleep(nanoseconds: 1_500_000_000)
        }
        
        // Timeout - try fallback immediately
        await MainActor.run {
            isGeneratingContent = false
        }
        print("⏰ ChatService: Topic extraction timed out after 20 seconds")
        
        // Try to fetch topic directly from user endpoint as fallback
        print("🔄 ChatService: Attempting fallback topic fetch...")
        if let fallbackTopic = await fetchUserTopic() {
            await MainActor.run {
                self.smartUpdateTopic(fallbackTopic)
            }
            print("✅ ChatService: Fallback topic fetch successful: '\(fallbackTopic)'")
        } else {
            print("ℹ️ ChatService: No fallback topic available, keeping current topic")
            // Don't clear the current topic if fallback fails
            // This ensures user always sees some content
        }
    }
    

    
    // MARK: - User Recommendations
    
    func fetchUserRecommendations() async -> UserRecommendations? {
        do {
            let url = URL(string: "\(baseURL)/user/\(currentUserId)/recommendations")!
            let (data, response) = try await URLSession.shared.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                return nil
            }
            
            let recommendations = try JSONDecoder().decode(UserRecommendations.self, from: data)
            return recommendations
            
        } catch {
            print("Error fetching user recommendations: \(error)")
            return nil
        }
    }
    
    func fetchUserTopic() async -> String? {
        print("🔍 ChatService: Fetching topic for user_id: '\(currentUserId)'")
        do {
            let url = URL(string: "\(baseURL)/user/\(currentUserId)/topic")!
            let (data, response) = try await URLSession.shared.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                return nil
            }
            
            let userTopic = try JSONDecoder().decode(UserTopic.self, from: data)
            print("📊 ChatService: Fetched topic for user_id '\(currentUserId)': '\(userTopic.topic ?? "nil")'")
            return userTopic.topic
            
        } catch {
            print("Error fetching user topic: \(error)")
            return nil
        }
    }
    

} 
