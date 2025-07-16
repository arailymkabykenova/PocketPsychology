import Foundation
import Combine

class ContentService: ObservableObject {
    // Backend URL - same as ChatService
    private let baseURL = "https://pinkponys.org"
    
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // Published content
    @Published var dailyQuote: Quote?
    @Published var articles: [Article] = []
    @Published var videos: [Video] = []
    
    // Initial content for new users
    @Published var initialContent: InitialContent?
    @Published var isInitialContentLoaded = false
    
    // Language support
    @Published var currentLanguage: Language = .russian
    
    // UserDefaults keys
    private let userDefaults = UserDefaults.standard
    private let dailyQuoteKey = "daily_quote"
    private let lastQuoteDateKey = "last_quote_date"
    private let initialContentKey = "initial_content"
    private let languageKey = "content_language"
    
    init() {
        // Load cached content on init
        loadCachedContent()
        loadCachedInitialContent()
        loadCachedLanguage()
        
        // Sync with LocalizationManager
        let localizationManager = LocalizationManager.shared
        if currentLanguage != localizationManager.currentLanguage {
            currentLanguage = localizationManager.currentLanguage
            userDefaults.set(currentLanguage.rawValue, forKey: languageKey)
        }
        
        // Fetch fresh content after a short delay to avoid loading state on launch
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            Task {
                await self.fetchInitialContent()
            }
        }
    }
    
    // MARK: - Topic-Based Content Loading
    
    func loadContentForTopic(_ topic: String) async {
        print("🔄 ContentService: Loading content for topic: '\(topic)'")
        print("🌐 ContentService: Using baseURL: '\(baseURL)'")
        
        await MainActor.run {
            isLoading = true
            errorMessage = nil
            // Don't clear content immediately - only clear if new content loads successfully
            print("🔄 ContentService: Starting content refresh for topic: '\(topic)'")
        }
        
        // Track successful loads
        var articlesLoaded = false
        var videosLoaded = false
        var quoteLoaded = false
        
        // Load articles, videos, and quote for the specific topic
        await withTaskGroup(of: (String, Bool).self) { group in
            group.addTask { 
                print("📄 ContentService: Fetching articles for topic: '\(topic)'")
                let success = await self.fetchArticles(topic: topic)
                return ("articles", success)
            }
            group.addTask { 
                print("🎥 ContentService: Fetching videos for topic: '\(topic)'")
                let success = await self.fetchVideos(topic: topic)
                return ("videos", success)
            }
            group.addTask { 
                print("💬 ContentService: Fetching daily quote for topic: '\(topic)'")
                let success = await self.fetchDailyQuote(topic: topic)
                return ("quote", success)
            }
            
            // Collect results
            for await (contentType, success) in group {
                switch contentType {
                case "articles":
                    articlesLoaded = success
                case "videos":
                    videosLoaded = success
                case "quote":
                    quoteLoaded = success
                default:
                    break
                }
            }
        }
        
        await MainActor.run {
            isLoading = false
            print("✅ ContentService: Content loading completed for topic: '\(topic)'")
            print("📊 ContentService: Articles: \(self.articles.count) (loaded: \(articlesLoaded)), Videos: \(self.videos.count) (loaded: \(videosLoaded)), Quote: \(self.dailyQuote != nil ? "loaded" : "none") (loaded: \(quoteLoaded))")
            
            // Only show error if all content failed to load
            if !articlesLoaded && !videosLoaded && !quoteLoaded {
                errorMessage = "Не удалось загрузить контент для темы '\(topic)'"
            }
        }
    }
    
    // MARK: - Language Management
    
    func setLanguage(_ language: Language) {
        currentLanguage = language
        userDefaults.set(language.rawValue, forKey: languageKey)
        
        // Refresh content with new language
        Task {
            // If we have a current topic, refresh content for that topic
            // Otherwise, fetch initial content
            if let currentTopic = getCurrentTopic() {
                await loadContentForTopic(currentTopic)
            } else {
                await fetchInitialContent()
            }
        }
    }
    
    // Helper method to get current topic from ChatService
    private func getCurrentTopic() -> String? {
        // This is a simple approach - in a real app you might want to inject ChatService
        // For now, we'll rely on the fact that HomeView handles topic changes
        return nil
    }
    
    private func loadCachedLanguage() {
        if let savedLanguage = userDefaults.string(forKey: languageKey),
           let language = Language(rawValue: savedLanguage) {
            currentLanguage = language
        }
    }
    
    // MARK: - Initial Content
    
    func fetchInitialContent() async {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        
        do {
            let languageParam = currentLanguage.rawValue
            guard let url = URL(string: "\(baseURL)/content/initial?language=\(languageParam)") else {
                await MainActor.run {
                    errorMessage = "Invalid URL"
                    isLoading = false
                }
                return
            }
            
            // Create URLRequest with timeout
            var request = URLRequest(url: url)
            request.timeoutInterval = 30.0
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                await MainActor.run {
                    errorMessage = "Server error"
                    isLoading = false
                }
                return
            }
            
            let initialContent = try JSONDecoder().decode(InitialContent.self, from: data)
            
            await MainActor.run {
                self.initialContent = initialContent
                self.isInitialContentLoaded = true
                self.isLoading = false
                
                // Update other content from initial content
                if let quote = initialContent.daily_quote {
                    self.dailyQuote = quote
                }
                if !initialContent.random_articles.isEmpty {
                    self.articles = initialContent.random_articles
                }
                if !initialContent.random_videos.isEmpty {
                    self.videos = initialContent.random_videos
                }
                
                // Cache initial content
                self.cacheInitialContent(initialContent)
            }
            
        } catch let error as URLError {
            await MainActor.run {
                if error.code == .cancelled {
                    errorMessage = "Request was cancelled"
                } else {
                    errorMessage = "Network error: \(error.localizedDescription)"
                }
                isLoading = false
            }
        } catch {
            await MainActor.run {
                errorMessage = "Failed to fetch initial content: \(error.localizedDescription)"
                isLoading = false
            }
        }
    }
    
    private func cacheInitialContent(_ content: InitialContent) {
        do {
            let data = try JSONEncoder().encode(content)
            userDefaults.set(data, forKey: initialContentKey)
        } catch {
            print("Error caching initial content: \(error)")
        }
    }
    
    private func loadCachedInitialContent() {
        guard let data = userDefaults.data(forKey: initialContentKey) else {
            return
        }
        
        do {
            let content = try JSONDecoder().decode(InitialContent.self, from: data)
            self.initialContent = content
            self.isInitialContentLoaded = true
        } catch {
            print("Error loading cached initial content: \(error)")
        }
    }
    
    // MARK: - Topic-Based Content
    
    func fetchArticles(topic: String? = nil) async -> Bool {
        print("📄 ContentService: fetchArticles called with topic: '\(topic ?? "nil")'")
        
        do {
            var urlString = "\(baseURL)/content/articles?language=\(currentLanguage.rawValue)"
            if let topic = topic {
                let encodedTopic = topic.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? topic
                urlString += "&topic=\(encodedTopic)"
                print("📄 ContentService: Encoded topic '\(topic)' to '\(encodedTopic)'")
            }
            
            guard let url = URL(string: urlString) else {
                print("📄 ContentService: Invalid URL for articles")
                return false
            }
            
            print("📄 ContentService: Fetching articles from: \(url)")
            
            let (data, response) = try await URLSession.shared.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("📄 ContentService: Invalid response for articles")
                return false
            }
            
            if httpResponse.statusCode != 200 {
                let errorText = String(data: data, encoding: .utf8) ?? "Unknown error"
                print("📄 ContentService: Server error: \(httpResponse.statusCode) - \(errorText)")
                return false
            }
            
            // Print response data for debugging
            let responseString = String(data: data, encoding: .utf8) ?? "Unable to decode response"
            print("📄 ContentService: Response data: \(responseString)")
            
            let articlesResponse = try JSONDecoder().decode(ArticlesResponse.self, from: data)
            
            await MainActor.run {
                self.articles = articlesResponse.articles
                print("📄 ContentService: Articles loaded: \(articlesResponse.articles.count) articles")
            }
            return true
            
        } catch {
            print("📄 ContentService: Failed to fetch articles: \(error.localizedDescription)")
            return false
        }
    }
    

    
    // MARK: - Daily Quote
    
    func fetchDailyQuote(topic: String? = nil) async -> Bool {
        let today = Date().formatted(date: .numeric, time: .omitted) // <-- переместил сюда
        // Check if we need to fetch new quote (once per day) - only for general quotes
        if topic == nil {
            let lastDate = userDefaults.string(forKey: lastQuoteDateKey)
            
            if lastDate == today && dailyQuote != nil {
                return true // Already have today's quote
            }
        }
        
        do {
            let languageParam = currentLanguage.rawValue
            var urlString = "\(baseURL)/content/daily-quote?language=\(languageParam)"
            if let topic = topic {
                let encodedTopic = topic.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? topic
                urlString += "&topic=\(encodedTopic)"
                print("💬 ContentService: Fetching quote for topic: '\(topic)' (encoded: '\(encodedTopic)')")
            }
            
            guard let url = URL(string: urlString) else {
                print("💬 ContentService: Invalid URL for daily quote")
                return false
            }
            
            let (data, response) = try await URLSession.shared.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                print("💬 ContentService: Server error for daily quote")
                return false
            }
            
            let quote = try JSONDecoder().decode(Quote.self, from: data)
            
            await MainActor.run {
                self.dailyQuote = quote
                print("💬 ContentService: Daily quote loaded")
                
                // Cache the quote
                self.cacheDailyQuote(quote, date: today)
            }
            return true
            
        } catch {
            print("💬 ContentService: Failed to fetch quote: \(error.localizedDescription)")
            return false
        }
    }
    
    func generateQuote(topic: String? = nil) async -> Quote? {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        
        do {
            let languageParam = currentLanguage.rawValue
            var urlString = "\(baseURL)/content/generate?content_type=quote&language=\(languageParam)"
            if let topic = topic {
                urlString += "&topic=\(topic.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? topic)"
            }
            
            guard let url = URL(string: urlString) else {
                await MainActor.run {
                    errorMessage = "Invalid URL"
                    isLoading = false
                }
                return nil
            }
            
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                await MainActor.run {
                    errorMessage = "Server error"
                    isLoading = false
                }
                return nil
            }
            
            let generateResponse = try JSONDecoder().decode(GenerateResponse.self, from: data)
            
            // Extract quote from AnyCodable
            if let contentDict = generateResponse.content.value as? [String: Any],
               let text = contentDict["text"] as? String,
               let author = contentDict["author"] as? String,
               let topic = contentDict["topic"] as? String,
               let date = contentDict["date"] as? String {
                
                let quote = Quote(
                    text: text, 
                    author: author, 
                    topic: topic, 
                    date: date, 
                    isGenerated: true,
                    language: currentLanguage.rawValue,
                    createdAt: Date().formatted()
                )
                
                await MainActor.run {
                    self.isLoading = false
                }
                
                return quote
            }
            
            await MainActor.run {
                errorMessage = "Invalid response format"
                isLoading = false
            }
            return nil
            
        } catch {
            await MainActor.run {
                errorMessage = "Failed to generate quote: \(error.localizedDescription)"
                isLoading = false
            }
            return nil
        }
    }
    
    // MARK: - Articles
    
    func generateArticles() async {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        
        do {
            let languageParam = currentLanguage.rawValue
            guard let url = URL(string: "\(baseURL)/content/generate?content_type=article&language=\(languageParam)") else {
                await MainActor.run {
                    errorMessage = "Invalid URL"
                    isLoading = false
                }
                return
            }
            
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                await MainActor.run {
                    errorMessage = "Server error"
                    isLoading = false
                }
                return
            }
            
            let generateResponse = try JSONDecoder().decode(GenerateResponse.self, from: data)
            
            // Extract articles from AnyCodable
            if let contentArray = generateResponse.content.value as? [[String: Any]] {
                var newArticles: [Article] = []
                
                for articleDict in contentArray {
                    if let title = articleDict["title"] as? String,
                       let content = articleDict["content"] as? String,
                       let topic = articleDict["topic"] as? String {
                        
                        let article = Article(
                            title: title,
                            content: content,
                            sourceTopics: [topic],
                            createdAt: Date().formatted(),
                            topic: topic,
                            approach: articleDict["approach"] as? String
                        )
                        newArticles.append(article)
                    }
                }
                
                await MainActor.run {
                    self.articles = newArticles + self.articles
                    self.isLoading = false
                }
            } else {
                await MainActor.run {
                    errorMessage = "Invalid response format"
                    isLoading = false
                }
            }
            
        } catch {
            await MainActor.run {
                errorMessage = "Failed to generate articles: \(error.localizedDescription)"
                isLoading = false
            }
        }
    }
    
    // MARK: - Videos
    
    func fetchVideos(topic: String? = nil, limit: Int = 10) async -> Bool {
        print("🎥 ContentService: fetchVideos called with topic: '\(topic ?? "nil")'")
        
        do {
            let languageParam = currentLanguage.rawValue
            var urlString = "\(baseURL)/content/videos?limit=\(limit)&language=\(languageParam)"
            if let topic = topic {
                let encodedTopic = topic.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? topic
                urlString += "&topic=\(encodedTopic)"
                print("🎥 ContentService: Encoded topic '\(topic)' to '\(encodedTopic)'")
            }
            
            guard let url = URL(string: urlString) else {
                print("🎥 ContentService: Invalid URL for videos")
                return false
            }
            
            print("🎥 ContentService: Fetching videos from: \(url)")
            
            let (data, response) = try await URLSession.shared.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("🎥 ContentService: Invalid response for videos")
                return false
            }
            
            if httpResponse.statusCode != 200 {
                let errorText = String(data: data, encoding: .utf8) ?? "Unknown error"
                print("Server error: \(httpResponse.statusCode) - \(errorText)")
                return false
            }
            
            // Print response data for debugging
            let responseString = String(data: data, encoding: .utf8) ?? "Unable to decode response"
            print("Response data: \(responseString)")
            
            let videosResponse = try JSONDecoder().decode(VideosResponse.self, from: data)
            
            await MainActor.run {
                self.videos = videosResponse.videos
                print("🎥 ContentService: Successfully loaded \(videosResponse.videos.count) videos")
                
                // Debug: print first video structure
                if let firstVideo = videosResponse.videos.first {
                    print("🎥 ContentService: First video structure: \(firstVideo)")
                }
            }
            return true
            
        } catch {
            print("🎥 ContentService: Failed to fetch videos: \(error.localizedDescription)")
            return false
        }
    }
    
    // MARK: - Caching
    
    private func loadCachedContent() {
        // Load cached daily quote
        if let data = userDefaults.data(forKey: dailyQuoteKey),
           let quote = try? JSONDecoder().decode(Quote.self, from: data) {
            dailyQuote = quote
        }
        // Load cached initial content
        loadCachedInitialContent()
    }
    
    private func cacheDailyQuote(_ quote: Quote, date: String) {
        if let data = try? JSONEncoder().encode(quote) {
            userDefaults.set(data, forKey: dailyQuoteKey)
            userDefaults.set(date, forKey: lastQuoteDateKey)
        }
    }
    
    // MARK: - Error Handling
    
    func clearError() {
        errorMessage = nil
    }
} 