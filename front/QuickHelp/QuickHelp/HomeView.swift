import SwiftUI
import Foundation

struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

struct HomeView: View {
    @ObservedObject private var localizationManager = LocalizationManager.shared
    @StateObject private var contentService = ContentService()
    @ObservedObject var chatService: ChatService
    @Binding var showingSettings: Bool
    @State private var scrollOffset: CGFloat = 0
    
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
        
                
                // Background gradient
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.themeBackground,
                        Color.themeBackground.opacity(0.8)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 32) {
                        // Welcome message for new users (only show if no topic yet)
                        if chatService.currentTopic == nil && !contentService.isInitialContentLoaded {
                            WelcomeCard(message: localizationManager.localizedString(.welcomeMessage))
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
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20) // Increased top padding for more space
                    .padding(.bottom, 40)
                }
                .background(
                    GeometryReader { geometry in
                        Color.clear
                            .preference(key: ScrollOffsetPreferenceKey.self, value: geometry.frame(in: .named("scroll")).minY)
                    }
                )
                .coordinateSpace(name: "scroll")
                .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
                    scrollOffset = value
                }

                .navigationBarTitleDisplayMode(.inline)
                .toolbarBackground(.visible, for: .navigationBar)
                .toolbarBackground(Color.themeBackground, for: .navigationBar)
                .toolbar {
                    ToolbarItem(placement: .principal) {
                        Text("QUICK HELP")
                            .font(.sfProRoundedSemibold(size: 28)) // Larger initial font size
                           
                            .foregroundColor(.primary)
                            .scaleEffect(max(0.8, 1.0 - abs(scrollOffset) * 0.001)) // Scale down when scrolling
                            .offset(y: max(-20, -scrollOffset * 0.3)) // Move up when scrolling
                             .padding(.top, max(10, 20 - scrollOffset * 0.1))  
                            .padding(.bottom, max(10, 20 - scrollOffset * 0.1)) 
                            .animation(.easeInOut(duration: 0.3), value: scrollOffset)
                           
                    }
                }
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: {
                            showingSettings = true
                        }) {
                            Image(systemName: "gearshape.fill")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(Color.themeButton)
                        }
                    }
                }
                
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

                    await contentService.fetchInitialContent()
                }
                
                // Note: Removed topic refresh to avoid conflicts
                // If you need to refresh topic, do it separately
            }
            .onChange(of: currentLanguage) { newLanguage in

                
                // Force topic refresh when language changes
                chatService.forceTopicRefresh()
                
                // Update content service language and refresh content
                contentService.setLanguage(newLanguage)
            }
            .onChange(of: chatService.currentTopic) { newTopic in

                
                // Refresh content when topic changes
                if let topic = newTopic {
                    Task {
        
                        // Set loading state
                        await MainActor.run {
                            chatService.isGeneratingContentForTopic = true
                        }
                        
                        await contentService.loadContentForTopic(topic)
                        
                        // Clear loading state
                        await MainActor.run {
                            chatService.isGeneratingContentForTopic = false
                        }

                    }
                } else {
                    // If topic is cleared, load initial random content
                    Task {
    
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
                // Load content if user has a topic
                if let topic = chatService.currentTopic {

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
            // Quote of the day (personalized for topic)
            QuoteOfTheDayCard(quote: contentService.dailyQuote, isLoading: contentService.isLoading && contentService.dailyQuote == nil, contentService: contentService)
            
            // Articles section (personalized for topic)
            ArticlesSection(articles: contentService.articles, isLoading: contentService.isLoading && contentService.articles.isEmpty, contentService: contentService)
            
                            // Videos section (personalized for topic)
                VideosSection(videos: contentService.videos, isLoading: contentService.isLoading && contentService.videos.isEmpty, isQuotaExceeded: contentService.isYouTubeQuotaExceeded)
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
                VideosSection(videos: contentService.videos, isLoading: contentService.isLoading && contentService.videos.isEmpty, isQuotaExceeded: contentService.isYouTubeQuotaExceeded)
        }
    }
}

// MARK: - Welcome Card
struct WelcomeCard: View {
    let message: String
    @ObservedObject private var localizationManager = LocalizationManager.shared
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with gradient
            VStack(spacing: 20) {
                // Main icon with gradient background
                ZStack {
                    Circle()
                        .fill(
                                                    LinearGradient(
                            gradient: Gradient(colors: [Color.themePrimary.opacity(0.2), Color.themeSecondary.opacity(0.2)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        )
                        .frame(width: 80, height: 80)
                    
                    Image(systemName: "brain.head.profile")
                        .font(.system(size: 36, weight: .medium))
                        .foregroundColor(.blue)
                }
                
                VStack(spacing: 8) {
                    Text(localizationManager.currentLanguage == .russian ? "Добро пожаловать в" : "Welcome to")
                        .font(.title3)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                    
                    Text("Quick Help")    
                        .font(.sfProRoundedHeavy(size: 42))
                        .foregroundColor(.primary)
                }
                
                Text(message)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(nil)
                    .padding(.horizontal, 8)
            }
            .padding(.top, 32)
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.themePrimary.opacity(0.05),
                        Color.themeSecondary.opacity(0.03)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            
            // Features section
            VStack(spacing: 16) {
                                        Text(localizationManager.localizedString(.whatYouGet))
                            .font(.sfProRoundedHeavy(size: 22))
                            .foregroundColor(.primary)
                            .padding(.top, 8)
                
                VStack(spacing: 12) {
                    FeatureRow(icon: "message.circle.fill", 
                              text: localizationManager.localizedString(.threeConversationModes),
                              color: .blue)
                    FeatureRow(icon: "lightbulb.fill", 
                              text: localizationManager.localizedString(.personalizedTopics),
                              color: .orange)
                    FeatureRow(icon: "doc.text.fill", 
                              text: localizationManager.localizedString(.helpfulArticles),
                              color: .green)
                    FeatureRow(icon: "play.circle.fill", 
                              text: localizationManager.localizedString(.motivationalVideos),
                              color: .purple)
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.themeCardBackground)
                .shadow(color: Color.black.opacity(0.08), radius: 20, x: 0, y: 10)
        )
    }
}

// MARK: - Feature Row
struct FeatureRow: View {
    let icon: String
    let text: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.1))
                    .frame(width: 40, height: 40)
                
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(color)
            }
            
            Text(text)
                .font(.body)
                .fontWeight(.medium)
                .foregroundColor(.primary)
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Current Topic Card
struct CurrentTopicCard: View {
    let topic: String
    @ObservedObject private var localizationManager = LocalizationManager.shared
    @ObservedObject private var chatService = ChatService()
    
    var body: some View {
        HStack(spacing: 20) {
            // Icon with gradient background
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.themePrimary.opacity(0.2), Color.themeSecondary.opacity(0.2)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 60, height: 60)
                
                Image(systemName: "lightbulb.fill")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(Color.themeIcon)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text(localizationManager.localizedString(.currentTopicLabel))
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                    .textCase(.uppercase)
                    .tracking(0.5)
                
                if chatService.isGeneratingContent {
                    HStack(spacing: 8) {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text(localizationManager.localizedString(.analyzing))
                            .font(.headlineMedium)
                            .foregroundColor(.primary)
                    }
                } else if chatService.isGeneratingContentForTopic {
                    HStack(spacing: 8) {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text(localizationManager.localizedString(.generatingContentForTopic))
                            .font(.headlineMedium)
                            .foregroundColor(.primary)
                    }
                } else {
                    Text(topic.capitalized)
                        .font(.sfProRoundedHeavy(size: 18))
                        .foregroundColor(.primary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            
            Spacer()
            
            // Status indicator
            if !chatService.isGeneratingContent && !chatService.isGeneratingContentForTopic {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title3)
                    .foregroundColor(Color.themeButton)
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.customCardBackground)
                .shadow(color: Color.black.opacity(0.06), radius: 15, x: 0, y: 8)
        )
    }
}

struct QuoteOfTheDayCard: View {
    let quote: Quote?
    let isLoading: Bool
    @ObservedObject var contentService: ContentService
    @ObservedObject private var localizationManager = LocalizationManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header section
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(localizationManager.localizedString(.quoteOfTheDay))
                            .font(.headlineLarge)
                            .foregroundColor(.primary)
                        
                        Text(localizationManager.localizedString(.quoteOfTheDaySubtitle))
                            .font(.subtitleSmall)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    // Quote icon with gradient
                    ZStack {
                        Circle()
                            .fill(
                                                        LinearGradient(
                            gradient: Gradient(colors: [Color.themePrimary.opacity(0.2), Color.themeSecondary.opacity(0.2)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                            )
                            .frame(width: 50, height: 50)
                        
                        Image(systemName: "quote.bubble.fill")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(Color.themeIcon)
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 24)
            .padding(.bottom, 20)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.themePrimary.opacity(0.05),
                        Color.clear
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            
            // Quote content section
            VStack(spacing: 20) {
                if isLoading {
                    // Loading state
                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.2)
                        Text(localizationManager.localizedString(.loading))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
                } else if let quote = quote {
                    // Quote content
                    VStack(spacing: 16) {
                        Text(quote.text)
                            .font(.sfProRoundedSemibold(size: 20))
                            .multilineTextAlignment(.center)
                            .foregroundColor(.primary)
                            .lineSpacing(6)
                            .padding(.horizontal, 8)
                        
                        HStack {
                            Text("— \(quote.author)")
                                .font(.sfProRoundedSemibold(size: 16))
                                .foregroundColor(.secondary)
                            
                            Spacer()
                        }
                        .padding(.horizontal, 8)
                        
                        // Generate new quote button
                        Button(action: {
                            Task {
                                if let newQuote = await contentService.generateQuote() {
                                    // Quote will be updated via ContentService
                                }
                            }
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: "sparkles")
                                    .font(.caption)
                                Text(localizationManager.localizedString(.newQuoteButton))
                                    .font(.caption)
                                    .fontWeight(.medium)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                Capsule()
                                    .fill(
                                        LinearGradient(
                                            gradient: Gradient(colors: [
                                                Color.themeButton.opacity(0.2),
                                                Color.themeSecondary.opacity(0.1)
                                            ]),
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                            )
                            .foregroundColor(Color.themeButton)
                        }
                    }
                } else {
                    // Fallback content
                    VStack(spacing: 16) {
                        Text(localizationManager.localizedString(.defaultQuote))
                            .font(.title3)
                            .fontWeight(.medium)
                            .multilineTextAlignment(.center)
                            .foregroundColor(.primary)
                            .lineSpacing(6)
                        
                        HStack {
                            Text("— \(localizationManager.localizedString(.defaultQuoteAuthor))")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.secondary)
                            
                            Spacer()
                        }
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.themeCardBackground)
                .shadow(color: Color.black.opacity(0.08), radius: 20, x: 0, y: 10)
        )
    }
}

struct ArticlesSection: View {
    let articles: [Article]
    let isLoading: Bool
    @ObservedObject var contentService: ContentService
    @ObservedObject private var localizationManager = LocalizationManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Section header
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(localizationManager.localizedString(.articlesSectionTitle))
                            .font(.sfProRoundedHeavy(size: 24))
                            .foregroundColor(.primary)
                        
                        Text(localizationManager.localizedString(.articlesSectionSubtitle))
                            .font(.sfProRoundedSemibold(size: 16))
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    // Section icon
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [Color.green.opacity(0.2), Color.blue.opacity(0.2)]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 40, height: 40)
                        
                        Image(systemName: "doc.text.fill")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.green)
                    }
                }
            }
            
            if isLoading {
                // Loading state
                VStack(spacing: 20) {
                    ZStack {
                        Circle()
                            .fill(Color.green.opacity(0.1))
                            .frame(width: 80, height: 80)
                        
                        ProgressView()
                            .scaleEffect(1.2)
                            .progressViewStyle(CircularProgressViewStyle(tint: .green))
                    }
                    
                    VStack(spacing: 8) {
                        Text(localizationManager.localizedString(.loadingArticles))
                            .font(.sfProRoundedSemibold(size: 20))
                            .foregroundColor(.primary)
                        
                        Text(localizationManager.localizedString(.loadingArticlesSubtitle))
                            .font(.sfProRoundedSemibold(size: 16))
                            .foregroundColor(.secondary)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 60)
            } else if articles.isEmpty {
                // Empty state
                VStack(spacing: 20) {
                    ZStack {
                     
                        Image(systemName: "doc.text")
                            .font(.system(size: 32, weight: .medium))
                            .foregroundColor(.green)
                    }
                    
                    VStack(spacing: 8) {
                        Text(localizationManager.localizedString(.articlesWillAppearHere))
                            .font(.sfProRoundedSemibold(size: 20))
                            .foregroundColor(.primary)
                        
                        Text(localizationManager.localizedString(.articlesWillAppearSubtitle))
                            .font(.sfProRoundedSemibold(size: 16))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 60)
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
            VStack(alignment: .leading, spacing: 0) {
                // Header with gradient
                HStack(spacing: 12) {
                    // Article icon with liquid glass effect
                    ZStack {
                        Circle()
                            .fill(.ultraThinMaterial)
                            .overlay(
                                Circle()
                                    .stroke(
                                        LinearGradient(
                                            gradient: Gradient(colors: [
                                                article.approachColor.opacity(0.4),
                                                article.approachColor.opacity(0.2)
                                            ]),
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: 1.5
                                    )
                            )
                            .frame(width: 50, height: 50)
                            .shadow(color: article.approachColor.opacity(0.3), radius: 8, x: 0, y: 4)
                        
                        Image(systemName: article.approachIcon)
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(article.approachColor)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(article.title)
                            .font(.sfProRoundedSemibold(size: 18))
                            .foregroundColor(.primary)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                        
                        HStack(spacing: 6) {
                            // Approach badge with liquid glass effect
                            Text(article.approachDisplayName)
                                .font(.sfProRoundedSemibold(size: 11))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(
                                    Capsule()
                                        .fill(.ultraThinMaterial)
                                        .overlay(
                                            Capsule()
                                                .stroke(
                                                    LinearGradient(
                                                        gradient: Gradient(colors: [
                                                            article.approachColor.opacity(0.3),
                                                            article.approachColor.opacity(0.1)
                                                        ]),
                                                        startPoint: .leading,
                                                        endPoint: .trailing
                                                    ),
                                                    lineWidth: 0.5
                                                )
                                        )
                                )
                                .foregroundColor(article.approachColor)
                                .lineLimit(1)
                            
                            // Topic badge with liquid glass effect
                            Text(article.category)
                                .font(.sfProRoundedSemibold(size: 11))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(
                                    Capsule()
                                        .fill(.ultraThinMaterial)
                                        .overlay(
                                            Capsule()
                                                .stroke(
                                                    LinearGradient(
                                                        gradient: Gradient(colors: [
                                                            Color.green.opacity(0.3),
                                                            Color.green.opacity(0.1)
                                                        ]),
                                                        startPoint: .leading,
                                                        endPoint: .trailing
                                                    ),
                                                    lineWidth: 0.5
                                                )
                                        )
                                )
                                .foregroundColor(.green)
                                .lineLimit(1)
                        }
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Image(systemName: "chevron.right")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        
                        Text(article.readTime)
                            .font(.sfProRoundedSemibold(size: 12))
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(
                                Capsule()
                                    .fill(.ultraThinMaterial)
                                    .overlay(
                                        Capsule()
                                            .stroke(Color.secondary.opacity(0.2), lineWidth: 0.5)
                                    )
                            )
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 12)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            article.approachColor.opacity(0.05),
                            Color.clear
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                
                // Description
                if !article.description.isEmpty {
                    Text(article.description)
                        .font(.sfProRoundedSemibold(size: 15))
                        .foregroundColor(.secondary)
                        .lineLimit(3)
                        .padding(.horizontal, 16)
                        .padding(.bottom, 16)
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color.white.opacity(0.3),
                                        Color.white.opacity(0.1)
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
                    .shadow(color: Color.black.opacity(0.1), radius: 20, x: 0, y: 10)
            )
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
    let isQuotaExceeded: Bool
    @ObservedObject private var localizationManager = LocalizationManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {

            
            // Section header
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(localizationManager.localizedString(.videosSectionTitle))
                            .font(.sfProRoundedHeavy(size: 24))
                            .foregroundColor(.primary)
                        
                        Text(localizationManager.localizedString(.videosSectionSubtitle))
                            .font(.sfProRoundedSemibold(size: 16))
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    // Section icon
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [Color.red.opacity(0.2), Color.orange.opacity(0.2)]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 40, height: 40)
                        
                        Image(systemName: "play.rectangle.fill")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.red)
                    }
                }
            }
            
            if isLoading {
                // Loading state
                VStack(spacing: 20) {
                    ZStack {
                        Circle()
                            .fill(Color.red.opacity(0.1))
                            .frame(width: 80, height: 80)
                        
                        ProgressView()
                            .scaleEffect(1.2)
                            .progressViewStyle(CircularProgressViewStyle(tint: .red))
                    }
                    
                    VStack(spacing: 8) {
                        Text(localizationManager.localizedString(.loadingVideos))
                            .font(.sfProRoundedSemibold(size: 20))
                            .foregroundColor(.primary)
                        
                        Text(localizationManager.localizedString(.loadingVideosSubtitle))
                            .font(.sfProRoundedSemibold(size: 16))
                            .foregroundColor(.secondary)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 60)
            } else if videos.isEmpty {
                // Empty state or quota exceeded
                VStack(spacing: 20) {
                    ZStack {
                        Circle()
                            .fill(Color.red.opacity(0.1))
                            .frame(width: 80, height: 80)
                        
                        Image(systemName: isQuotaExceeded ? "exclamationmark.triangle" : "play.rectangle")
                            .font(.system(size: 32, weight: .medium))
                            .foregroundColor(.red)
                    }
                    
                    VStack(spacing: 8) {
                        Text(isQuotaExceeded ? 
                             localizationManager.localizedString(.youtubeQuotaExceeded) :
                             localizationManager.localizedString(.videosWillAppearHere))
                            .font(.sfProRoundedSemibold(size: 20))
                            .foregroundColor(.primary)
                        
                        Text(isQuotaExceeded ? 
                             localizationManager.localizedString(.youtubeQuotaExceededSubtitle) :
                             localizationManager.localizedString(.videosWillAppearSubtitle))
                            .font(.sfProRoundedSemibold(size: 16))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 60)
            } else {
                // Videos carousel with centered scaling effect
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(Array(videos.enumerated()), id: \.element.id) { index, video in
                            GeometryReader { geometry in
                                VideoCarouselCard(video: video)
                                    .frame(width: 280)
                                    .scaleEffect(getScale(for: geometry))
                                    .opacity(getOpacity(for: geometry))
                                    .animation(.easeInOut(duration: 0.3), value: geometry.frame(in: .global).minX)
                            }
                            .frame(width: 280)
                        }
                    }
                    .padding(.horizontal, 20) // Reduced padding to match other sections
                    .padding(.vertical, 8)
                }
                .frame(height: 400) // Fixed height for the carousel
            }
        }
    }
    
    // MARK: - Carousel Helper Functions
    
    private func getScale(for geometry: GeometryProxy) -> CGFloat {
        let screenWidth = UIScreen.main.bounds.width
        let centerX = screenWidth / 2
        let cardCenterX = geometry.frame(in: .global).midX
        let distanceFromCenter = abs(cardCenterX - centerX)
        let maxDistance = screenWidth / 2
        
        // Scale from 0.85 to 1.0 based on distance from center
        let scale = 1.0 - (distanceFromCenter / maxDistance) * 0.15
        return max(0.85, min(1.0, scale))
    }
    
    private func getOpacity(for geometry: GeometryProxy) -> Double {
        let screenWidth = UIScreen.main.bounds.width
        let centerX = screenWidth / 2
        let cardCenterX = geometry.frame(in: .global).midX
        let distanceFromCenter = abs(cardCenterX - centerX)
        let maxDistance = screenWidth / 2
        
        // Opacity from 0.7 to 1.0 based on distance from center
        let opacity = 1.0 - (distanceFromCenter / maxDistance) * 0.3
        return max(0.7, min(1.0, opacity))
    }
}

struct VideoCard: View {
    let video: Video
    @ObservedObject private var localizationManager = LocalizationManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Video thumbnail with play button overlay
            ZStack(alignment: .center) {
                AsyncImage(url: URL(string: video.thumbnail)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Rectangle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.gray.opacity(0.3), Color.gray.opacity(0.1)]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .overlay(
                            Image(systemName: "play.rectangle")
                                .font(.system(size: 40))
                                .foregroundColor(.white.opacity(0.8))
                        )
                }
                .frame(height: 160)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                
                // Play button overlay
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
                            // Handle failure silently
                        }
                    }
                }) {
                    ZStack {
                        Circle()
                            .fill(Color.white.opacity(0.9))
                            .frame(width: 60, height: 60)
                            .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 5)
                        
                        Image(systemName: "play.fill")
                            .font(.title2)
                            .foregroundColor(.red)
                    }
                }
            }
            
            // Video content
            VStack(alignment: .leading, spacing: 12) {
                Text(video.title)
                    .font(.sfProRoundedSemibold(size: 20))
                    .foregroundColor(.primary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(video.channel)
                            .font(.sfProRoundedSemibold(size: 16))
                            .foregroundColor(.secondary)
                        
                        HStack(spacing: 8) {
                            Image(systemName: "clock")
                                .font(.caption)
                            Text(video.formattedDurationString)
                                .font(.sfProRoundedSemibold(size: 14))
                        }
                        .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "arrow.up.right.square")
                        .font(.title3)
                        .foregroundColor(.red)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 20)
        }
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.themeCardBackground)
                .shadow(color: Color.black.opacity(0.06), radius: 15, x: 0, y: 8)
        )
    }
}

struct VideoCarouselCard: View {
    let video: Video
    @ObservedObject private var localizationManager = LocalizationManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Video thumbnail with gradient overlay and play button
            ZStack(alignment: .center) {
                AsyncImage(url: URL(string: video.thumbnail)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Rectangle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.themePrimary.opacity(0.3),
                                    Color.themeSecondary.opacity(0.1)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .overlay(
                            Image(systemName: "play.rectangle")
                                .font(.system(size: 40))
                                .foregroundColor(.white.opacity(0.8))
                        )
                }
                .frame(height: 180)
                .clipShape(RoundedRectangle(cornerRadius: 20))
                
                // Gradient overlay
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.clear,
                        Color.black.opacity(0.3)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .clipShape(RoundedRectangle(cornerRadius: 20))
                
                // Play button overlay
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
                            // Handle failure silently
                        }
                    }
                }) {
                    ZStack {
                        Circle()
                            .fill(.ultraThinMaterial)
                            .overlay(
                                Circle()
                                    .stroke(
                                        LinearGradient(
                                            gradient: Gradient(colors: [
                                                Color.white.opacity(0.4),
                                                Color.white.opacity(0.2)
                                            ]),
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: 1
                                    )
                            )
                            .frame(width: 70, height: 70)
                            .shadow(color: Color.black.opacity(0.3), radius: 15, x: 0, y: 8)
                        
                        Image(systemName: "play.fill")
                            .font(.title)
                            .foregroundColor(Color.themeButton)
                    }
                }
                
                // Duration badge
                VStack {
                    HStack {
                        Spacer()
                        
                        Text(video.formattedDurationString)
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                Capsule()
                                    .fill(.ultraThinMaterial)
                                    .overlay(
                                        Capsule()
                                            .stroke(Color.white.opacity(0.2), lineWidth: 0.5)
                                    )
                            )
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 12)
                .padding(.top, 12)
            }
            .onAppear {
                // Validate thumbnail URL silently
            }
            
            // Video content
            VStack(alignment: .leading, spacing: 8) {
                Text(video.title)
                    .font(.sfProRoundedSemibold(size: 20))
                    .foregroundColor(.primary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                
                Text(video.channel)
                    .font(.sfProRoundedSemibold(size: 16))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                
                // Action button
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
                            // Handle failure silently
                        }
                    }
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "play.circle.fill")
                            .font(.system(size: 16))
                        
                        Text(localizationManager.localizedString(.watchVideo))
                            .font(.sfProRoundedSemibold(size: 16))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(.ultraThinMaterial)
                            .overlay(
                                Capsule()
                                    .stroke(
                                        LinearGradient(
                                            gradient: Gradient(colors: [
                                                Color.themeButton.opacity(0.6),
                                                Color.themeAccent.opacity(0.4)
                                            ]),
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        ),
                                        lineWidth: 1
                                    )
                            )
                    )
                    .shadow(color: Color.themeButton.opacity(0.2), radius: 8, x: 0, y: 4)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 16)
        }
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.white.opacity(0.3),
                                    Color.white.opacity(0.1)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
                .shadow(color: Color.black.opacity(0.1), radius: 20, x: 0, y: 10)
        )
    }
}



#Preview {
    HomeView(chatService: ChatService(), showingSettings: .constant(false))
} 
