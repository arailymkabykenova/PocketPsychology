import Foundation
import SwiftUI

// MARK: - Language Models
enum Language: String, CaseIterable, Codable {
    case russian = "ru"
    case english = "en"
    
    var displayName: String {
        switch self {
        case .russian:
            return "Русский"
        case .english:
            return "English"
        }
    }
    
    var flag: String {
        switch self {
        case .russian:
            return "🇷🇺"
        case .english:
            return "🇺🇸"
        }
    }
}

// MARK: - Chat Models
struct ChatMessage: Identifiable, Codable, Equatable {
    let id = UUID()
    let content: String
    let isUser: Bool
    let timestamp: Date
    let mode: ChatMode
    
    static func == (lhs: ChatMessage, rhs: ChatMessage) -> Bool {
        lhs.id == rhs.id
    }
}

enum ChatMode: String, CaseIterable, Codable {
    case support = "support"
    case analysis = "analysis"
    case practice = "practice"
    
    func displayName(for language: Language) -> String {
        switch language {
        case .russian:
            switch self {
            case .support:
                return "Поддержка"
            case .analysis:
                return "Анализ"
            case .practice:
                return "Практика"
            }
        case .english:
            switch self {
            case .support:
                return "Support"
            case .analysis:
                return "Analysis"
            case .practice:
                return "Practice"
            }
        }
    }
    
    func description(for language: Language) -> String {
        switch language {
        case .russian:
            switch self {
            case .support:
                return "Эмпатичное слушание"
            case .analysis:
                return "Сократовский диалог"
            case .practice:
                return "КПТ техники"
            }
        case .english:
            switch self {
            case .support:
                return "Empathetic listening"
            case .analysis:
                return "Socratic dialogue"
            case .practice:
                return "CBT techniques"
            }
        }
    }
    
    var icon: String {
        switch self {
        case .support:
            return "heart.fill"
        case .analysis:
            return "brain.head.profile"
        case .practice:
            return "figure.mind.and.body"
        }
    }
    
    var color: Color {
        switch self {
        case .support:
            return .pink
        case .analysis:
            return .blue
        case .practice:
            return .green
        }
    }
}

// MARK: - API Models
struct ChatRequest: Codable {
    let message: String
    let mode: ChatMode
    let user_id: String
    let language: String
}

struct ChatResponse: Codable {
    let response: String
    let mode: ChatMode
    let topic: String?
    let topic_task_id: String?
    let recommendations_task_id: String?
}

// MARK: - User Models
struct UserTopic: Codable {
    let user_id: String
    let topic: String?
}

struct TopicRefreshResponse: Codable {
    let user_id: String
    let message: String
}

struct UserRecommendations: Codable {
    let topic: String?
    let articles: [Article]?
    let quotes: [Quote]?
    let videos: [Video]?
    let timestamp: String?
}

// MARK: - Initial Content Models
struct InitialContent: Codable {
    let daily_quote: Quote?
    let random_articles: [Article]
    let random_videos: [Video]
    let welcome_message: String
}

// MARK: - Task Status Models
struct TaskStatus: Codable {
    let task_id: String
    let status: String
    let result: TaskResult?
    let error: String?
}

struct TaskResult: Codable {
    let topic: String?
    let user_id: String?
    let timestamp: String?
    let article_task_id: String?
    let quote_task_id: String?
    let recommendations_task_id: String?
    let auto_generation_started: Bool?
    let articles_generated: Int?
    let quotes_generated: Int?
    let topics_processed: Int?
    let cached: Bool?
}

// MARK: - Content Models
struct Quote: Codable, Identifiable {
    let id = UUID()
    let text: String
    let author: String
    let topic: String
    let date: String
    let isGenerated: Bool?
    
    enum CodingKeys: String, CodingKey {
        case text, author, topic, date
        case isGenerated = "is_generated"
    }
}

struct Article: Codable, Identifiable {
    let id = UUID()
    let title: String
    let content: String
    let sourceTopics: [String]
    let createdAt: String
    
    enum CodingKeys: String, CodingKey {
        case title, content
        case sourceTopics = "source_topics"
        case createdAt = "created_at"
    }
    
    // Computed properties for UI
    var description: String {
        // Take first 100 characters of content
        let truncated = content.prefix(100)
        return String(truncated) + (content.count > 100 ? "..." : "")
    }
    
    var readTime: String {
        // Estimate reading time (200 words per minute)
        let words = content.split(separator: " ").count
        let minutes = max(1, words / 200)
        return "\(minutes) мин"
    }
    
    var category: String {
        return sourceTopics.first ?? "Общее"
    }
}

struct Video: Codable, Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let videoId: String
    let thumbnail: String
    let duration: String
    let formattedDuration: String?
    let channel: String
    let publishedAt: String?
    let viewCount: Int?
    let likeCount: Int?
    let url: String?
    
    enum CodingKeys: String, CodingKey {
        case title, description, thumbnail, duration, channel
        case videoId = "id"  // Бэкенд возвращает "id", а не "video_id"
        case formattedDuration = "formatted_duration"
        case publishedAt = "published_at"
        case viewCount = "view_count"
        case likeCount = "like_count"
        case url
    }
    
    // Computed property для обратной совместимости
    var formattedDurationString: String {
        return formattedDuration ?? formatDuration(duration)
    }
    
    // Fallback форматирование длительности
    private func formatDuration(_ duration: String) -> String {
        // Простое форматирование ISO 8601 duration
        if duration.contains("PT") {
            let clean = duration.replacingOccurrences(of: "PT", with: "")
            if clean.contains("M") && clean.contains("S") {
                let parts = clean.components(separatedBy: "M")
                if parts.count >= 2 {
                    let minutes = parts[0]
                    let seconds = parts[1].replacingOccurrences(of: "S", with: "")
                    return "\(minutes):\(seconds.padding(toLength: 2, withPad: "0", startingAt: 0))"
                }
            }
        }
        return "0:00"
    }
}

// MARK: - Response Models
struct ArticlesResponse: Codable {
    let articles: [Article]
}

struct VideosResponse: Codable {
    let videos: [Video]
}

struct GenerateResponse: Codable {
    let message: String
    let content: AnyCodable
}

struct AnyCodable: Codable {
    let value: Any
    
    init(_ value: Any) {
        self.value = value
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        if let string = try? container.decode(String.self) {
            value = string
        } else if let int = try? container.decode(Int.self) {
            value = int
        } else if let double = try? container.decode(Double.self) {
            value = double
        } else if let bool = try? container.decode(Bool.self) {
            value = bool
        } else if let array = try? container.decode([AnyCodable].self) {
            value = array.map { $0.value }
        } else if let dictionary = try? container.decode([String: AnyCodable].self) {
            value = dictionary.mapValues { $0.value }
        } else {
            value = NSNull()
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        
        switch value {
        case let string as String:
            try container.encode(string)
        case let int as Int:
            try container.encode(int)
        case let double as Double:
            try container.encode(double)
        case let bool as Bool:
            try container.encode(bool)
        case let array as [Any]:
            try container.encode(array.map { AnyCodable($0) })
        case let dictionary as [String: Any]:
            try container.encode(dictionary.mapValues { AnyCodable($0) })
        default:
            try container.encodeNil()
        }
    }
} 