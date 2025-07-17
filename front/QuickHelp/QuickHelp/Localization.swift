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
    case practicalArticle
    case theoreticalArticle
    case motivationalArticle
    case accountManagement
    case deleteAccount
    case deleteAccountAlert
    case deleteAccountMessage
    case delete
    case generatingContent
    case generatingContentForTopic
    case analyzing
    case loading
    case noArticles
    case noVideos
    case articlesWillAppear
    case videosWillAppear
    case newQuote
    case defaultQuote
    case defaultQuoteAuthor
    case welcomeMessage
    case threeConversationModes
    case personalizedTopics
    case helpfulArticles
    case currentTopic
    case close
    case article
    case forTopic
    case sourceTopics
    case settings
    case appearance
    case selectTheme
    case account
    case deleteAccountWarning
    case deleteAccountConfirmation
    case currentTopicLabel
    case quoteOfTheDaySubtitle
    case articlesSectionTitle
    case articlesSectionSubtitle
    case videosSectionTitle
    case videosSectionSubtitle
    case whatYouGet
    case loadingArticles
    case loadingArticlesSubtitle
    case articlesWillAppearHere
    case articlesWillAppearSubtitle
    case loadingVideos
    case loadingVideosSubtitle
    case videosWillAppearHere
    case videosWillAppearSubtitle
    case newQuoteButton
    case keyPoints
    case practicalSteps
    case preview
    case previewDescription
    case exampleCard
    case exampleCardDescription
    case exampleButton
    case watchVideo
    
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
        case .practicalArticle:
            return "Практическая статья"
        case .theoreticalArticle:
            return "Теоретическая статья"
        case .motivationalArticle:
            return "Мотивационная статья"
        case .accountManagement:
            return "Управление аккаунтом"
        case .deleteAccount:
            return "Удалить аккаунт"
        case .deleteAccountAlert:
            return "Удалить аккаунт?"
        case .deleteAccountMessage:
            return "Это действие удалит все ваши данные, включая историю чата и персонализированные настройки. Это действие нельзя отменить."
        case .delete:
            return "Удалить"
        case .generatingContent:
            return "Генерируем контент"
        case .generatingContentForTopic:
            return "Генерирую контент..."
        case .analyzing:
            return "Анализирую..."
        case .loading:
            return "Загрузка..."
        case .noArticles:
            return "Нет статей для отображения."
        case .noVideos:
            return "Нет видео для отображения."
        case .articlesWillAppear:
            return "Статьи скоро появятся."
        case .videosWillAppear:
            return "Видео скоро появятся."
        case .newQuote:
            return "Новая цитата"
        case .defaultQuote:
            return "Цитата дня"
        case .defaultQuoteAuthor:
            return "Автор"
        case .welcomeMessage:
            return "Добро пожаловать в QuickHelp! Начните общение в чате, чтобы я мог определить ваши интересы и подобрать персонализированный контент."
        case .threeConversationModes:
            return "Три режима общения"
        case .personalizedTopics:
            return "Персонализированные темы"
        case .helpfulArticles:
            return "Полезные статьи"
        case .currentTopic:
            return "Текущая тема:"
        case .close:
            return "Закрыть"
        case .article:
            return "Статья"
        case .forTopic:
            return "для темы"
        case .sourceTopics:
            return "Источники тем"
        case .settings:
            return "Настройки"
        case .appearance:
            return "Внешний вид"
        case .selectTheme:
            return "Выбрать тему"
        case .account:
            return "Аккаунт"
        case .deleteAccountWarning:
            return "Это действие удалит все ваши данные и историю чата. Это действие нельзя отменить."
        case .deleteAccountConfirmation:
            return "Вы уверены, что хотите удалить свой аккаунт? Это действие нельзя отменить."
        case .currentTopicLabel:
            return "Текущая тема"
        case .quoteOfTheDaySubtitle:
            return "Вдохновение для вашего дня"
        case .articlesSectionTitle:
            return "Статьи"
        case .articlesSectionSubtitle:
            return "Полезные материалы для самопомощи"
        case .videosSectionTitle:
            return "Видео"
        case .videosSectionSubtitle:
            return "Мотивационные и обучающие видео"
        case .whatYouGet:
            return "Что вы получите:"
        case .loadingArticles:
            return "Загружаем статьи..."
        case .loadingArticlesSubtitle:
            return "Подбираем лучшие материалы для вас"
        case .articlesWillAppearHere:
            return "Статьи появятся здесь"
        case .articlesWillAppearSubtitle:
            return "Начните чат, чтобы получить персонализированные материалы"
        case .loadingVideos:
            return "Загружаем видео..."
        case .loadingVideosSubtitle:
            return "Подбираем лучшие видео для вас"
        case .videosWillAppearHere:
            return "Видео появятся здесь"
        case .videosWillAppearSubtitle:
            return "Начните чат, чтобы получить персонализированные видео"
        case .newQuoteButton:
            return "Новая цитата"
        case .keyPoints:
            return "Ключевые моменты"
        case .practicalSteps:
            return "Практические шаги"
        case .preview:
            return "Предварительный просмотр"
        case .previewDescription:
            return "Это как будут выглядеть карточки"
        case .exampleCard:
            return "Пример карточки"
        case .exampleCardDescription:
            return "Это как будут выглядеть карточки"
        case .exampleButton:
            return "Пример кнопки"
        case .watchVideo:
            return "Смотреть"
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
        case .practicalArticle:
            return "Practical Article"
        case .theoreticalArticle:
            return "Theoretical Article"
        case .motivationalArticle:
            return "Motivational Article"
        case .accountManagement:
            return "Account Management"
        case .deleteAccount:
            return "Delete Account"
        case .deleteAccountAlert:
            return "Delete Account?"
        case .deleteAccountMessage:
            return "This action will delete all your data, including chat history and personalized settings. This action cannot be undone."
        case .delete:
            return "Delete"
        case .generatingContent:
            return "Generating content"
        case .generatingContentForTopic:
            return "Generating content..."
        case .analyzing:
            return "Analyzing..."
        case .loading:
            return "Loading..."
        case .noArticles:
            return "No articles to display."
        case .noVideos:
            return "No videos to display."
        case .articlesWillAppear:
            return "Articles will appear."
        case .videosWillAppear:
            return "Videos will appear."
        case .newQuote:
            return "New Quote"
        case .defaultQuote:
            return "Quote of the Day"
        case .defaultQuoteAuthor:
            return "Author"
        case .welcomeMessage:
            return "Welcome to QuickHelp! Start chatting to help me understand your interests and provide personalized content."
        case .threeConversationModes:
            return "Three conversation modes"
        case .personalizedTopics:
            return "Personalized topics"
        case .helpfulArticles:
            return "Helpful articles"
        case .currentTopic:
            return "Current topic:"
        case .close:
            return "Close"
        case .article:
            return "Article"
        case .forTopic:
            return "for topic"
        case .sourceTopics:
            return "Source Topics"
        case .settings:
            return "Settings"
        case .appearance:
            return "Appearance"
        case .selectTheme:
            return "Select Theme"
        case .account:
            return "Account"
        case .deleteAccountWarning:
            return "This action will delete all your data and chat history. This action cannot be undone."
        case .deleteAccountConfirmation:
            return "Are you sure you want to delete your account? This action cannot be undone."
        case .currentTopicLabel:
            return "Current Topic"
        case .quoteOfTheDaySubtitle:
            return "Inspiration for your day"
        case .articlesSectionTitle:
            return "Articles"
        case .articlesSectionSubtitle:
            return "Helpful self-help materials"
        case .videosSectionTitle:
            return "Videos"
        case .videosSectionSubtitle:
            return "Motivational and educational videos"
        case .whatYouGet:
            return "What you'll get:"
        case .loadingArticles:
            return "Loading articles..."
        case .loadingArticlesSubtitle:
            return "Finding the best materials for you"
        case .articlesWillAppearHere:
            return "Articles will appear here"
        case .articlesWillAppearSubtitle:
            return "Start chatting to get personalized materials"
        case .loadingVideos:
            return "Loading videos..."
        case .loadingVideosSubtitle:
            return "Finding the best videos for you"
        case .videosWillAppearHere:
            return "Videos will appear here"
        case .videosWillAppearSubtitle:
            return "Start chatting to get personalized videos"
        case .newQuoteButton:
            return "New Quote"
        case .keyPoints:
            return "Key Points"
        case .practicalSteps:
            return "Practical Steps"
        case .preview:
            return "Preview"
        case .previewDescription:
            return "This is how cards will look"
        case .exampleCard:
            return "Example Card"
        case .exampleCardDescription:
            return "This is how cards will look"
        case .exampleButton:
            return "Example Button"
        case .watchVideo:
            return "Watch"
        }
    }
} 