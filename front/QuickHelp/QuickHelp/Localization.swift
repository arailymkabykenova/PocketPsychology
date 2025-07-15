import Foundation

class LocalizationManager: ObservableObject {
    @Published var currentLanguage: Language = .russian
    
    static let shared = LocalizationManager()
    
    private init() {
        // Load saved language preference
        if let savedLanguage = UserDefaults.standard.string(forKey: "selected_language"),
           let language = Language(rawValue: savedLanguage) {
            currentLanguage = language
        }
    }
    
    func setLanguage(_ language: Language) {
        currentLanguage = language
        UserDefaults.standard.set(language.rawValue, forKey: "selected_language")
    }
    
    func localizedString(_ key: LocalizationKey) -> String {
        switch currentLanguage {
        case .russian:
            return key.russian
        case .english:
            return key.english
        }
    }
}

enum LocalizationKey {
    case welcomeTitle
    case welcomeSubtitle
    case selectMode
    case selectModeSubtitle
    case done
    case clearHistory
    case clearHistoryAlert
    case clearHistoryMessage
    case cancel
    case error
    case unknownError
    case connectedToServer
    case notConnectedToServer
    case enterMessage
    case chooseLanguage
    case home
    case chat
    case selfHelpArticles
    case motivationalVideos
    case all
    case quoteOfTheDay
    
    var russian: String {
        switch self {
        case .welcomeTitle:
            return "Добро пожаловать в QuickHelp!"
        case .welcomeSubtitle:
            return "Выберите режим общения и начните диалог. Я здесь, чтобы помочь вам."
        case .selectMode:
            return "Выберите режим"
        case .selectModeSubtitle:
            return "Каждый режим предлагает разный подход к общению"
        case .done:
            return "Готово"
        case .clearHistory:
            return "Очистить историю"
        case .clearHistoryAlert:
            return "Очистить историю"
        case .clearHistoryMessage:
            return "Вы уверены, что хотите очистить всю историю чата? Это действие нельзя отменить."
        case .cancel:
            return "Отмена"
        case .error:
            return "Ошибка"
        case .unknownError:
            return "Неизвестная ошибка"
        case .connectedToServer:
            return "Подключено к серверу"
        case .notConnectedToServer:
            return "Нет подключения к серверу"
        case .enterMessage:
            return "Введите сообщение..."
        case .chooseLanguage:
            return "Выберите язык"
        case .home:
            return "Главная"
        case .chat:
            return "Чат"
        case .selfHelpArticles:
            return "Статьи для самопомощи"
        case .motivationalVideos:
            return "Мотивационные видео"
        case .all:
            return "Все"
        case .quoteOfTheDay:
            return "Цитата дня"
        }
    }
    
    var english: String {
        switch self {
        case .welcomeTitle:
            return "Welcome to QuickHelp!"
        case .welcomeSubtitle:
            return "Choose a conversation mode and start chatting. I'm here to help you."
        case .selectMode:
            return "Select Mode"
        case .selectModeSubtitle:
            return "Each mode offers a different approach to communication"
        case .done:
            return "Done"
        case .clearHistory:
            return "Clear History"
        case .clearHistoryAlert:
            return "Clear History"
        case .clearHistoryMessage:
            return "Are you sure you want to clear all chat history? This action cannot be undone."
        case .cancel:
            return "Cancel"
        case .error:
            return "Error"
        case .unknownError:
            return "Unknown error"
        case .connectedToServer:
            return "Connected to server"
        case .notConnectedToServer:
            return "No connection to server"
        case .enterMessage:
            return "Enter message..."
        case .chooseLanguage:
            return "Choose Language"
        case .home:
            return "Home"
        case .chat:
            return "Chat"
        case .selfHelpArticles:
            return "Self-Help Articles"
        case .motivationalVideos:
            return "Motivational Videos"
        case .all:
            return "All"
        case .quoteOfTheDay:
            return "Quote of the Day"
        }
    }
} 