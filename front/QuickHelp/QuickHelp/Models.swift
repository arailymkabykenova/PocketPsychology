import Foundation
import SwiftUI

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
    
    var displayName: String {
        switch self {
        case .support:
            return "Поддержка"
        case .analysis:
            return "Анализ"
        case .practice:
            return "Практика"
        }
    }
    
    var description: String {
        switch self {
        case .support:
            return "Эмпатичное слушание"
        case .analysis:
            return "Сократовский диалог"
        case .practice:
            return "КПТ техники"
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