import SwiftUI

struct HomeView: View {
    @ObservedObject private var localizationManager = LocalizationManager.shared
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Quote of the day
                    QuoteOfTheDayCard()
                    
                    // Articles section
                    ArticlesSection()
                    
                    // Videos section
                    VideosSection()
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 32)
            }
            .background(Color(.systemGray6))
            .navigationTitle("QuickHelp")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

struct QuoteOfTheDayCard: View {
    @ObservedObject private var localizationManager = LocalizationManager.shared
    
    var body: some View {
        VStack(spacing: 16) {
            // Quote icon
            Image(systemName: "quote.bubble.fill")
                .font(.system(size: 32))
                .foregroundColor(.blue.opacity(0.7))
            
            // Quote text
            Text(localizationManager.currentLanguage == .russian ? 
                "Будь изменением, которое ты хочешь видеть в мире" :
                "Be the change you wish to see in the world")
                .font(.title2)
                .fontWeight(.medium)
                .multilineTextAlignment(.center)
                .foregroundColor(.primary)
            
            // Author
            Text(localizationManager.currentLanguage == .russian ? 
                "— Махатма Ганди" :
                "— Mahatma Gandhi")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .italic()
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
    @ObservedObject private var localizationManager = LocalizationManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Section header
            HStack {
                Text(localizationManager.localizedString(.selfHelpArticles))
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button(localizationManager.localizedString(.all)) {
                    // TODO: Navigate to all articles
                }
                .font(.subheadline)
                .foregroundColor(.blue)
            }
            
            // Articles list
            LazyVStack(spacing: 12) {
                ForEach(sampleArticles, id: \.id) { article in
                    ArticleCard(article: article)
                }
            }
        }
    }
    
    private var sampleArticles: [Article] {
        if localizationManager.currentLanguage == .russian {
            return [
                Article(
                    title: "Как справиться со стрессом",
                    description: "Практические техники для управления стрессом в повседневной жизни",
                    readTime: "5 мин",
                    category: "Стресс"
                ),
                Article(
                    title: "Техники медитации для начинающих",
                    description: "Простые упражнения для развития осознанности и спокойствия",
                    readTime: "8 мин",
                    category: "Медитация"
                ),
                Article(
                    title: "Улучшение качества сна",
                    description: "Научно обоснованные методы для здорового сна",
                    readTime: "6 мин",
                    category: "Сон"
                )
            ]
        } else {
            return [
                Article(
                    title: "How to Deal with Stress",
                    description: "Practical techniques for managing stress in daily life",
                    readTime: "5 min",
                    category: "Stress"
                ),
                Article(
                    title: "Meditation Techniques for Beginners",
                    description: "Simple exercises for developing mindfulness and calmness",
                    readTime: "8 min",
                    category: "Meditation"
                ),
                Article(
                    title: "Improving Sleep Quality",
                    description: "Science-based methods for healthy sleep",
                    readTime: "6 min",
                    category: "Sleep"
                )
            ]
        }
    }
}

struct ArticleCard: View {
    let article: Article
    @ObservedObject private var localizationManager = LocalizationManager.shared
    
    var body: some View {
        HStack(spacing: 16) {
            // Article icon
            VStack {
                Image(systemName: "doc.text.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.blue)
            }
            .frame(width: 50, height: 50)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.blue.opacity(0.1))
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
            
            // Read button
            Button(action: {
                // TODO: Open article
            }) {
                Image(systemName: "arrow.right.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.blue)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
        )
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

struct VideosSection: View {
    @ObservedObject private var localizationManager = LocalizationManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Section header
            HStack {
                Text(localizationManager.localizedString(.motivationalVideos))
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button(localizationManager.localizedString(.all)) {
                    // TODO: Navigate to all videos
                }
                .font(.subheadline)
                .foregroundColor(.blue)
            }
            
            // Videos grid
            LazyVStack(spacing: 12) {
                ForEach(sampleVideos, id: \.id) { video in
                    VideoCard(video: video)
                }
            }
        }
    }
    
    private var sampleVideos: [Video] {
        if localizationManager.currentLanguage == .russian {
            return [
                Video(
                    title: "Как преодолеть страх неудачи",
                    description: "Практические советы для развития уверенности в себе",
                    duration: "12:34",
                    thumbnail: "video.1"
                ),
                Video(
                    title: "Техники дыхания для спокойствия",
                    description: "Упражнения для мгновенного снятия напряжения",
                    duration: "8:45",
                    thumbnail: "video.2"
                ),
                Video(
                    title: "Создание позитивных привычек",
                    description: "Пошаговое руководство по формированию полезных привычек",
                    duration: "15:20",
                    thumbnail: "video.3"
                )
            ]
        } else {
            return [
                Video(
                    title: "How to Overcome Fear of Failure",
                    description: "Practical tips for building self-confidence",
                    duration: "12:34",
                    thumbnail: "video.1"
                ),
                Video(
                    title: "Breathing Techniques for Calmness",
                    description: "Exercises for instant stress relief",
                    duration: "8:45",
                    thumbnail: "video.2"
                ),
                Video(
                    title: "Creating Positive Habits",
                    description: "Step-by-step guide to forming healthy habits",
                    duration: "15:20",
                    thumbnail: "video.3"
                )
            ]
        }
    }
}

struct VideoCard: View {
    let video: Video
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Video thumbnail with play button
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.blue.opacity(0.3),
                                Color.purple.opacity(0.2)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(height: 120)
                
                // Play button
                Button(action: {
                    // TODO: Play video
                }) {
                    Image(systemName: "play.circle.fill")
                        .font(.system(size: 48))
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.3), radius: 5, x: 0, y: 2)
                }
            }
            
            // Video info
            VStack(alignment: .leading, spacing: 4) {
                Text(video.title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text(video.description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                
                HStack {
                    Text(video.duration)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Button(action: {
                        // TODO: Add to favorites
                    }) {
                        Image(systemName: "heart")
                            .font(.caption)
                            .foregroundColor(.red.opacity(0.7))
                    }
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
        )
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

// MARK: - Models
struct Article {
    let id = UUID()
    let title: String
    let description: String
    let readTime: String
    let category: String
}

struct Video {
    let id = UUID()
    let title: String
    let description: String
    let duration: String
    let thumbnail: String
}

#Preview {
    HomeView()
} 