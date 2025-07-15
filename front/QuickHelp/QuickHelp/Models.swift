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
}

struct ChatResponse: Codable {
    let response: String
    let mode: ChatMode
} 