import SwiftUI
import Foundation

struct HomeView: View {
    @ObservedObject private var localizationManager = LocalizationManager.shared
    @StateObject private var contentService = ContentService()
    @ObservedObject var chatService: ChatService
    
    // Sync language between localization manager and content service
    private var currentLanguage: Language {
        localizationManager.currentLanguage
    }
    
    // Show error alert only if there's an error AND no content is loaded
    private var shouldShowErrorAlert: Bool {
        guard let errorMessage = contentService.errorMessage, !errorMessage.isEmpty else {
            return false
        }
        
        // Don't show error if we have any content loaded
        let hasArticles = !contentService.articles.isEmpty
        let hasVideos = !contentService.videos.isEmpty
        let hasQuote = contentService.dailyQuote != nil
        let hasInitialContent = contentService.isInitialContentLoaded
        
        // Only show error if no content at all is available
        return !hasArticles && !hasVideos && !hasQuote && !hasInitialContent
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                let _ = print("🏠 HomeView: Rendering with topic='\(chatService.currentTopic ?? "nil")', articles=\(contentService.articles.count), videos=\(contentService.videos.count)")
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Welcome message for new users (only show if no topic yet)
                        if chatService.currentTopic == nil && !contentService.isInitialContentLoaded {
                            WelcomeCard(message: localizationManager.currentLanguage == .russian ? 
                                "Добро пожаловать в QuickHelp! Начните общение в чате, чтобы я мог определить ваши интересы и подобрать персонализированный контент." :
                                "Welcome to QuickHelp! Start chatting to help me understand your interests and provide personalized content.")
                        }
                        
                        // Current topic indicator
                        if let currentTopic = chatService.currentTopic {
                            CurrentTopicCard(topic: currentTopic)
                        }
                        
                        // Content sections - show different content based on whether user has a topic
                        if let currentTopic = chatService.currentTopic {
                            // Personalized content based on user's topic
                            PersonalizedContentSection(
                                topic: currentTopic,
                                contentService: contentService,
                                chatService: chatService
                            )
                        } else {
                            // General content for new users
                            GeneralContentSection(contentService: contentService)
                        }
                        
                        // Account management section
                        AccountManagementSection(chatService: chatService)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    .padding(.bottom, 32)
                }
                .background(Color(.systemGray6))
                .navigationTitle("QuickHelp")
                
                // Full screen loading overlay when content is being generated for a new topic
                if let currentTopic = chatService.currentTopic, 
                   chatService.isGeneratingContentForTopic {
                    ContentLoadingOverlay(topic: currentTopic, isLoading: true)
                        .animation(.easeInOut(duration: 0.3), value: chatService.isGeneratingContentForTopic)
                        .zIndex(1000) // Ensure it's on top
                }
            }
            .refreshable {
                // Pull to refresh - only refresh content, don't change topic
                if let topic = chatService.currentTopic {
                    print("🔄 HomeView: Pull-to-refresh - refreshing content for topic: '\(topic)'")
                    // Set loading state
                    await MainActor.run {
                        chatService.isGeneratingContentForTopic = true
                    }
                    
                    await contentService.loadContentForTopic(topic)
                    
                    // Clear loading state
                    await MainActor.run {
                        chatService.isGeneratingContentForTopic = false
                    }
                } else {
                    print("🔄 HomeView: Pull-to-refresh - no topic, loading initial content")
                    await contentService.fetchInitialContent()
                }
                
                // Note: Removed topic refresh to avoid conflicts
                // If you need to refresh topic, do it separately
            }
            .onChange(of: currentLanguage) { newLanguage in
                // Update content service language and refresh content
                contentService.setLanguage(newLanguage)
            }
            .onChange(of: chatService.currentTopic) { newTopic in
                print("🏠 HomeView: Topic changed to '\(newTopic ?? "nil")'")
                
                // Refresh content when topic changes
                if let topic = newTopic {
                    Task {
                        print("🏠 HomeView: Starting to load content for topic '\(topic)'")
                        // Set loading state
                        await MainActor.run {
                            chatService.isGeneratingContentForTopic = true
                        }
                        
                        await contentService.loadContentForTopic(topic)
                        
                        // Clear loading state
                        await MainActor.run {
                            chatService.isGeneratingContentForTopic = false
                        }
                        print("🏠 HomeView: Finished loading content for topic '\(topic)'")
                    }
                } else {
                    // If topic is cleared, load initial random content
                    Task {
                        print("🏠 HomeView: Loading initial random content")
                        await contentService.fetchInitialContent()
                    }
                }
            }
            .alert("Ошибка", isPresented: .constant(shouldShowErrorAlert)) {
                Button("OK") {
                    contentService.clearError()
                }
            } message: {
                if let errorMessage = contentService.errorMessage {
                    Text(errorMessage)
                }
            }
            .onAppear {
                print("🏠 HomeView: onAppear called")
                
                // Load content if user has a topic
                if let topic = chatService.currentTopic {
                    print("🏠 HomeView: onAppear - Loading content for existing topic '\(topic)'")
                    Task {
                        // Set loading state only if no content is loaded yet
                        if contentService.articles.isEmpty && contentService.videos.isEmpty && contentService.dailyQuote == nil {
                            await MainActor.run {
                                chatService.isGeneratingContentForTopic = true
                            }
                        }
                        
                        await contentService.loadContentForTopic(topic)
                        
                        // Clear loading state
                        await MainActor.run {
                            chatService.isGeneratingContentForTopic = false
                        }
                    }
                } else {
                    print("🏠 HomeView: onAppear - No topic, loading initial random content")
                    Task {
                        await contentService.fetchInitialContent()
                    }
                }
            }
        }
    }
}

// MARK: - Personalized Content Section
struct PersonalizedContentSection: View {
    let topic: String
    @ObservedObject var contentService: ContentService
    @ObservedObject var chatService: ChatService
    @ObservedObject private var localizationManager = LocalizationManager.shared
    
    var body: some View {
        VStack(spacing: 24) {
            let _ = print("🎯 PersonalizedContentSection: topic='\(topic)', articles=\(contentService.articles.count), videos=\(contentService.videos.count)")
            
            // Quote of the day (personalized for topic)
            QuoteOfTheDayCard(quote: contentService.dailyQuote, isLoading: contentService.isLoading && contentService.dailyQuote == nil, contentService: contentService)
            
            // Articles section (personalized for topic)
            ArticlesSection(articles: contentService.articles, isLoading: contentService.isLoading && contentService.articles.isEmpty, contentService: contentService)
            
            // Videos section (personalized for topic)
            VideosSection(videos: contentService.videos, isLoading: contentService.isLoading && contentService.videos.isEmpty)
        }
    }
}

// MARK: - General Content Section
struct GeneralContentSection: View {
    @ObservedObject var contentService: ContentService
    @ObservedObject private var localizationManager = LocalizationManager.shared
    
    var body: some View {
        VStack(spacing: 24) {
            // Quote of the day
            QuoteOfTheDayCard(quote: contentService.dailyQuote, isLoading: contentService.isLoading && contentService.dailyQuote == nil, contentService: contentService)
            
            // Articles section
            ArticlesSection(articles: contentService.articles, isLoading: contentService.isLoading && contentService.articles.isEmpty, contentService: contentService)
            
            // Videos section
            VideosSection(videos: contentService.videos, isLoading: contentService.isLoading && contentService.videos.isEmpty)
        }
    }
}

// MARK: - Welcome Card
struct WelcomeCard: View {
    let message: String
    @ObservedObject private var localizationManager = LocalizationManager.shared
    
    var body: some View {
        VStack(spacing: 20) {
            // Main icon and title
            VStack(spacing: 12) {
                Image(systemName: "brain.head.profile")
                    .font(.system(size: 48))
                    .foregroundColor(.blue)
                
                Text(localizationManager.currentLanguage == .russian ? "Добро пожаловать в QuickHelp!" : "Welcome to QuickHelp!")
                    .font(.title2)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
            }
            
            // Message
            Text(message)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .lineLimit(nil)
            
            // Features list
            VStack(alignment: .leading, spacing: 8) {
                FeatureRow(icon: "message.circle.fill", 
                          text: localizationManager.currentLanguage == .russian ? "Три режима общения" : "Three conversation modes")
                FeatureRow(icon: "lightbulb.fill", 
                          text: localizationManager.currentLanguage == .russian ? "Персонализированные темы" : "Personalized topics")
                FeatureRow(icon: "doc.text.fill", 
                          text: localizationManager.currentLanguage == .russian ? "Полезные статьи" : "Helpful articles")
                FeatureRow(icon: "play.circle.fill", 
                          text: localizationManager.currentLanguage == .russian ? "Мотивационные видео" : "Motivational videos")
            }
            .padding(.top, 8)
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    LinearGradient(
                        colors: [Color.blue.opacity(0.1), Color.purple.opacity(0.05)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(
                            LinearGradient(
                                colors: [Color.blue.opacity(0.3), Color.purple.opacity(0.2)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
        )
    }
}

// MARK: - Feature Row
struct FeatureRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(.blue)
                .frame(width: 20)
            
            Text(text)
                .font(.subheadline)
                .foregroundColor(.primary)
            
            Spacer()
        }
    }
}

// MARK: - Current Topic Card
struct CurrentTopicCard: View {
    let topic: String
    @ObservedObject private var localizationManager = LocalizationManager.shared
    @ObservedObject private var chatService = ChatService()
    
    var body: some View {
        HStack {
            Image(systemName: "lightbulb.fill")
                .font(.title2)
                .foregroundColor(.yellow)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(localizationManager.currentLanguage == .russian ? "Текущая тема:" : "Current topic:")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                if chatService.isGeneratingContent {
                    HStack(spacing: 4) {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text(localizationManager.localizedString(.analyzing))
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                    }
                } else if chatService.isGeneratingContentForTopic {
                    HStack(spacing: 4) {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text(localizationManager.localizedString(.generatingContentForTopic))
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                    }
                } else {
                    Text(topic.capitalized)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            
            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.yellow.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.yellow.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

struct QuoteOfTheDayCard: View {
    let quote: Quote?
    let isLoading: Bool
    @ObservedObject var contentService: ContentService
    @ObservedObject private var localizationManager = LocalizationManager.shared
    
    var body: some View {
        VStack(spacing: 16) {
            // Quote icon
            Image(systemName: "quote.bubble.fill")
                .font(.system(size: 32))
                .foregroundColor(.blue.opacity(0.7))
            
            if isLoading {
                // Loading state
                ProgressView()
                    .scaleEffect(1.2)
            } else if let quote = quote {
                // Quote content
                VStack(spacing: 12) {
                    Text(quote.text)
                        .font(.title2)
                        .fontWeight(.medium)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.primary)
                    
                    Text("— \(quote.author)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .italic()
                    
                    // Generate new quote button
                    Button(action: {
                        Task {
                            if let newQuote = await contentService.generateQuote() {
                                // Quote will be updated via ContentService
                            }
                        }
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "sparkles")
                                .font(.caption)
                            Text(localizationManager.currentLanguage == .russian ? "Новая цитата" : "New Quote")
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(Color.blue.opacity(0.1))
                        )
                        .foregroundColor(.blue)
                    }
                }
            } else {
                // Fallback content
                VStack(spacing: 12) {
                    Text(localizationManager.currentLanguage == .russian ? 
                        "Будь изменением, которое ты хочешь видеть в мире" :
                        "Be the change you wish to see in the world")
                        .font(.title2)
                        .fontWeight(.medium)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.primary)
                    
                    Text(localizationManager.currentLanguage == .russian ? 
                        "— Махатма Ганди" :
                        "— Mahatma Gandhi")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .italic()
                }
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.blue.opacity(0.1),
                            Color.purple.opacity(0.05)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.blue.opacity(0.2), lineWidth: 1)
                )
        )
        .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 5)
    }
}

struct ArticlesSection: View {
    let articles: [Article]
    let isLoading: Bool
    @ObservedObject var contentService: ContentService
    @ObservedObject private var localizationManager = LocalizationManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            let _ = print("📄 ArticlesSection: articles.count=\(articles.count), isLoading=\(isLoading)")
            
            // Section header
            HStack {
                Text(localizationManager.localizedString(.selfHelpArticles))
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Spacer()
            }
            
            if isLoading {
                // Loading state
                HStack {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text(localizationManager.currentLanguage == .russian ? "Загрузка..." : "Loading...")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 20)
            } else if articles.isEmpty {
                // Empty state
                VStack(spacing: 12) {
                    Image(systemName: "doc.text")
                        .font(.system(size: 40))
                        .foregroundColor(.gray.opacity(0.5))
                    
                    Text(localizationManager.currentLanguage == .russian ? 
                        "Нет статей" : "No articles")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    Text(localizationManager.currentLanguage == .russian ? 
                        "Статьи появятся после общения с чат-ботом" : 
                        "Articles will appear after chatting with the bot")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            } else {
                // Articles list
                LazyVStack(spacing: 12) {
                    ForEach(articles.prefix(3), id: \.id) { article in
                        ArticleCard(article: article, contentService: contentService)
                    }
                }
            }
        }
    }
}

struct ArticleCard: View {
    let article: Article
    @ObservedObject var contentService: ContentService
    @ObservedObject private var localizationManager = LocalizationManager.shared
    @State private var showingArticleDetail = false
    
    var body: some View {
        Button(action: {
            showingArticleDetail = true
        }) {
            HStack(spacing: 16) {
                // Article icon with approach color
                VStack {
                    Image(systemName: article.approachIcon)
                        .font(.system(size: 24))
                        .foregroundColor(article.approachColor)
                }
                .frame(width: 50, height: 50)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(article.approachColor.opacity(0.1))
                )
                
                // Article content
                VStack(alignment: .leading, spacing: 4) {
                    Text(article.title)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Text(article.description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                    
                    HStack {
                        // Approach badge
                        Text(article.approachDisplayName)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                Capsule()
                                    .fill(article.approachColor.opacity(0.1))
                            )
                            .foregroundColor(article.approachColor)
                        
                        // Topic badge
                        Text(article.category)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                Capsule()
                                    .fill(Color.green.opacity(0.1))
                            )
                            .foregroundColor(.green)
                        
                        Spacer()
                        
                        Text(article.readTime)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemBackground))
            )
            .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
        .sheet(isPresented: $showingArticleDetail) {
            ArticleDetailView(article: article)
        }
    }
}

struct VideosSection: View {
    let videos: [Video]
    let isLoading: Bool
    @ObservedObject private var localizationManager = LocalizationManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            let _ = print("🎥 VideosSection: videos.count=\(videos.count), isLoading=\(isLoading)")
            
            // Section header
            HStack {
                Text(localizationManager.currentLanguage == .russian ? "Мотивационные видео" : "Motivational Videos")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Spacer()
            }
            
            if isLoading {
                // Loading state
                HStack {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text(localizationManager.currentLanguage == .russian ? "Загрузка..." : "Loading...")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 20)
            } else if videos.isEmpty {
                // Empty state
                VStack(spacing: 12) {
                    Image(systemName: "play.rectangle")
                        .font(.system(size: 40))
                        .foregroundColor(.gray.opacity(0.5))
                    
                    Text(localizationManager.currentLanguage == .russian ? 
                        "Нет видео" : "No videos")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    Text(localizationManager.currentLanguage == .russian ? 
                        "Видео появятся после общения с чат-ботом" : 
                        "Videos will appear after chatting with the bot")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            } else {
                // Videos list
                LazyVStack(spacing: 12) {
                    ForEach(videos.prefix(3), id: \.id) { video in
                        VideoCard(video: video)
                    }
                }
            }
        }
    }
}

struct VideoCard: View {
    let video: Video
    @ObservedObject private var localizationManager = LocalizationManager.shared
    
    var body: some View {
        HStack(spacing: 16) {
            // Video thumbnail
            AsyncImage(url: URL(string: video.thumbnail)) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .overlay(
                        Image(systemName: "play.fill")
                            .font(.title2)
                            .foregroundColor(.white)
                    )
            }
            .frame(width: 80, height: 60)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .onAppear {
                // Validate thumbnail URL
                if let url = URL(string: video.thumbnail) {
                    print("Loading thumbnail: \(url)")
                } else {
                    print("Invalid thumbnail URL: \(video.thumbnail)")
                }
            }
            
            // Video content
            VStack(alignment: .leading, spacing: 4) {
                Text(video.title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                    .lineLimit(2)
                
                Text(video.channel)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                HStack {
                    Text(video.formattedDurationString)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Button(action: {
                        // Open YouTube video
                        let videoUrl: String
                        if let url = video.url {
                            videoUrl = url
                        } else {
                            videoUrl = "https://www.youtube.com/watch?v=\(video.videoId)"
                        }
                        
                        if let url = URL(string: videoUrl) {
                            UIApplication.shared.open(url) { success in
                                if !success {
                                    print("Failed to open YouTube video: \(video.videoId)")
                                }
                            }
                        }
                    }) {
                        Image(systemName: "play.circle.fill")
                            .font(.title2)
                            .foregroundColor(.red)
                    }
                }
            }
            
            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
        )
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

// MARK: - Account Management Section
struct AccountManagementSection: View {
    @ObservedObject var chatService: ChatService
    @ObservedObject private var localizationManager = LocalizationManager.shared
    @State private var showingDeleteAlert = false
    @State private var isDeleting = false
    
    var body: some View {
        VStack(spacing: 16) {
            // Section header
            HStack {
                Text(localizationManager.localizedString(.accountManagement))
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Spacer()
            }
            
            // Delete account button
            Button(action: {
                showingDeleteAlert = true
            }) {
                HStack {
                    Image(systemName: "trash")
                        .font(.system(size: 16))
                        .foregroundColor(.red)
                    
                    Text(localizationManager.localizedString(.deleteAccount))
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(.red)
                    
                    Spacer()
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.red.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.red.opacity(0.3), lineWidth: 1)
                        )
                )
            }
            .disabled(isDeleting)
            .alert(localizationManager.localizedString(.deleteAccountAlert), isPresented: $showingDeleteAlert) {
                Button(localizationManager.localizedString(.cancel), role: .cancel) { }
                Button(localizationManager.localizedString(.delete), role: .destructive) {
                    Task {
                        await deleteAccount()
                    }
                }
            } message: {
                Text(localizationManager.localizedString(.deleteAccountMessage))
            }
        }
    }
    
    private func deleteAccount() async {
        isDeleting = true
        
        do {
            let userId = chatService.userId
            let url = URL(string: "http://localhost:8000/user/\(userId)/delete")!
            
            var request = URLRequest(url: url)
            request.httpMethod = "DELETE"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode == 200 {
                    // Successfully deleted account
                    DispatchQueue.main.async {
                        // Clear local data
                        chatService.clearAllData()
                        
                        // Show success message (you might want to add a success alert here)
                        print("Account deleted successfully")
                    }
                } else {
                    print("Failed to delete account: HTTP \(httpResponse.statusCode)")
                }
            }
        } catch {
            print("Error deleting account: \(error)")
        }
        
        isDeleting = false
    }
}

#Preview {
    HomeView(chatService: ChatService())
} 
