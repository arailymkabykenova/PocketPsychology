import SwiftUI
import Foundation

class ThemeManager: ObservableObject {
    @Published var currentColorTheme: ColorTheme = .darkBlue
    @Published var colorScheme: ColorScheme?
    
    static let shared = ThemeManager()
    
    private let userDefaults = UserDefaults.standard
    private let themeKey = "selected_color_theme"
    
    private init() {
        loadSavedTheme()
    }
    
    func setColorTheme(_ theme: ColorTheme) {
        currentColorTheme = theme
        userDefaults.set(theme.rawValue, forKey: themeKey)
        updateColorScheme()
    }
    
    private func loadSavedTheme() {
        if let savedTheme = userDefaults.string(forKey: themeKey),
           let theme = ColorTheme(rawValue: savedTheme) {
            currentColorTheme = theme
        }
        updateColorScheme()
    }
    
    private func updateColorScheme() {
        // Всегда используем светлую тему для пастельных цветов
        colorScheme = .light
    }
}

enum ColorTheme: String, CaseIterable {
    case yellow = "yellow"
    case darkBlue = "darkBlue"
    case black = "black"
    case white = "white"
    case pink = "pink"
    case green = "green"
    case purple = "purple"
    
    var displayName: String {
        let localizationManager = LocalizationManager.shared
        switch self {
        case .yellow:
            return localizationManager.currentLanguage == .russian ? "Желтый" : "Yellow"
        case .darkBlue:
            return localizationManager.currentLanguage == .russian ? "Синий" : "Blue"
        case .black:
            return localizationManager.currentLanguage == .russian ? "Черный" : "Black"
        case .white:
            return localizationManager.currentLanguage == .russian ? "Белый" : "White"
        case .pink:
            return localizationManager.currentLanguage == .russian ? "Розовый" : "Pink"
        case .green:
            return localizationManager.currentLanguage == .russian ? "Зеленый" : "Green"
        case .purple:
            return localizationManager.currentLanguage == .russian ? "Фиолетовый" : "Purple"
        }
    }
    
    // Основной цвет палитры (для кнопок, акцентов)
    var primaryColor: Color {
        switch self {
        case .yellow:
            return Color(red: 0.98, green: 0.85, blue: 0.4) // Яркий желтый
        case .darkBlue:
            return Color(red: 0.2, green: 0.4, blue: 0.8) // Темно-синий
        case .black:
            return Color(red: 0.2, green: 0.2, blue: 0.2) // Темно-серый
        case .white:
            return Color(red: 0.6, green: 0.6, blue: 0.6) // Серый
        case .pink:
            return Color(red: 0.9, green: 0.4, blue: 0.6) // Яркий розовый
        case .green:
            return Color(red: 0.3, green: 0.7, blue: 0.4) // Яркий зеленый
        case .purple:
            return Color(red: 0.6, green: 0.3, blue: 0.8) // Яркий фиолетовый
        }
    }
    
    // Вторичный цвет (для градиентов, дополнительных элементов)
    var secondaryColor: Color {
        switch self {
        case .yellow:
            return Color(red: 1.0, green: 0.9, blue: 0.6) // Светло-желтый
        case .darkBlue:
            return Color(red: 0.4, green: 0.6, blue: 0.9) // Светло-синий
        case .black:
            return Color(red: 0.4, green: 0.4, blue: 0.4) // Серый
        case .white:
            return Color(red: 0.8, green: 0.8, blue: 0.8) // Светло-серый
        case .pink:
            return Color(red: 1.0, green: 0.6, blue: 0.8) // Светло-розовый
        case .green:
            return Color(red: 0.6, green: 0.9, blue: 0.6) // Светло-зеленый
        case .purple:
            return Color(red: 0.8, green: 0.6, blue: 1.0) // Светло-фиолетовый
        }
    }
    
    // Третичный цвет (для фонов, подложек)
    var tertiaryColor: Color {
        switch self {
        case .yellow:
            return Color(red: 1.0, green: 0.95, blue: 0.8) // Очень светло-желтый
        case .darkBlue:
            return Color(red: 0.9, green: 0.95, blue: 1.0) // Очень светло-синий
        case .black:
            return Color(red: 0.95, green: 0.95, blue: 0.95) // Почти белый
        case .white:
            return Color.white
        case .pink:
            return Color(red: 1.0, green: 0.9, blue: 0.95) // Очень светло-розовый
        case .green:
            return Color(red: 0.9, green: 1.0, blue: 0.9) // Очень светло-зеленый
        case .purple:
            return Color(red: 0.95, green: 0.9, blue: 1.0) // Очень светло-фиолетовый
        }
    }
    
    // Цвет акцента (для важных элементов, кнопок)
    var accentColor: Color {
        switch self {
        case .yellow:
            return Color(red: 0.9, green: 0.7, blue: 0.2) // Темно-желтый
        case .darkBlue:
            return Color(red: 0.1, green: 0.3, blue: 0.7) // Очень темно-синий
        case .black:
            return Color(red: 0.1, green: 0.1, blue: 0.1) // Почти черный
        case .white:
            return Color(red: 0.4, green: 0.4, blue: 0.4) // Темно-серый
        case .pink:
            return Color(red: 0.8, green: 0.3, blue: 0.5) // Темно-розовый
        case .green:
            return Color(red: 0.2, green: 0.6, blue: 0.3) // Темно-зеленый
        case .purple:
            return Color(red: 0.5, green: 0.2, blue: 0.7) // Темно-фиолетовый
        }
    }
    
    // Фон приложения
    var backgroundColor: Color {
        switch self {
        case .yellow:
            return Color(red: 1.0, green: 0.98, blue: 0.95) // Очень светло-желтый
        case .darkBlue:
            return Color(red: 0.95, green: 0.98, blue: 1.0) // Очень светло-синий
        case .black:
            return Color(red: 0.98, green: 0.98, blue: 0.98) // Почти белый
        case .white:
            return Color.white
        case .pink:
            return Color(red: 1.0, green: 0.95, blue: 0.98) // Очень светло-розовый
        case .green:
            return Color(red: 0.95, green: 1.0, blue: 0.95) // Очень светло-зеленый
        case .purple:
            return Color(red: 0.98, green: 0.95, blue: 1.0) // Очень светло-фиолетовый
        }
    }
    
    // Фон карточек
    var cardBackgroundColor: Color {
        switch self {
        case .yellow:
            return Color.white
        case .darkBlue:
            return Color.white
        case .black:
            return Color.white
        case .white:
            return Color.white
        case .pink:
            return Color.white
        case .green:
            return Color.white
        case .purple:
            return Color.white
        }
    }
    
    // Цвет границ
    var borderColor: Color {
        switch self {
        case .yellow:
            return Color(red: 0.9, green: 0.85, blue: 0.6) // Желтоватый
        case .darkBlue:
            return Color(red: 0.8, green: 0.9, blue: 1.0) // Голубоватый
        case .black:
            return Color(red: 0.9, green: 0.9, blue: 0.9) // Серый
        case .white:
            return Color(red: 0.9, green: 0.9, blue: 0.9) // Серый
        case .pink:
            return Color(red: 0.95, green: 0.8, blue: 0.9) // Розоватый
        case .green:
            return Color(red: 0.85, green: 0.95, blue: 0.85) // Зеленоватый
        case .purple:
            return Color(red: 0.9, green: 0.8, blue: 0.95) // Фиолетоватый
        }
    }
    
    // Цвет текста
    var textColor: Color {
        switch self {
        case .yellow:
            return Color(red: 0.2, green: 0.2, blue: 0.2) // Темный
        case .darkBlue:
            return Color(red: 0.1, green: 0.1, blue: 0.2) // Темно-синий
        case .black:
            return Color.black
        case .white:
            return Color(red: 0.3, green: 0.3, blue: 0.3) // Темно-серый
        case .pink:
            return Color(red: 0.2, green: 0.1, blue: 0.15) // Темно-розовый
        case .green:
            return Color(red: 0.1, green: 0.2, blue: 0.1) // Темно-зеленый
        case .purple:
            return Color(red: 0.15, green: 0.1, blue: 0.2) // Темно-фиолетовый
        }
    }
    
    // Цвет кнопок
    var buttonColor: Color {
        switch self {
        case .yellow:
            return Color(red: 0.98, green: 0.85, blue: 0.4) // Яркий желтый
        case .darkBlue:
            return Color(red: 0.2, green: 0.4, blue: 0.8) // Темно-синий
        case .black:
            return Color(red: 0.2, green: 0.2, blue: 0.2) // Темно-серый
        case .white:
            return Color(red: 0.6, green: 0.6, blue: 0.6) // Серый
        case .pink:
            return Color(red: 0.9, green: 0.4, blue: 0.6) // Яркий розовый
        case .green:
            return Color(red: 0.3, green: 0.7, blue: 0.4) // Яркий зеленый
        case .purple:
            return Color(red: 0.6, green: 0.3, blue: 0.8) // Яркий фиолетовый
        }
    }
    
    // Цвет иконок
    var iconColor: Color {
        switch self {
        case .yellow:
            return Color(red: 0.9, green: 0.7, blue: 0.2) // Темно-желтый
        case .darkBlue:
            return Color(red: 0.1, green: 0.3, blue: 0.7) // Очень темно-синий
        case .black:
            return Color(red: 0.1, green: 0.1, blue: 0.1) // Почти черный
        case .white:
            return Color(red: 0.4, green: 0.4, blue: 0.4) // Темно-серый
        case .pink:
            return Color(red: 0.8, green: 0.3, blue: 0.5) // Темно-розовый
        case .green:
            return Color(red: 0.2, green: 0.6, blue: 0.3) // Темно-зеленый
        case .purple:
            return Color(red: 0.5, green: 0.2, blue: 0.7) // Темно-фиолетовый
        }
    }
}

// MARK: - Color Extensions
extension Color {
    static var themeBackground: Color {
        ThemeManager.shared.currentColorTheme.backgroundColor
    }
    
    static var themeCardBackground: Color {
        ThemeManager.shared.currentColorTheme.cardBackgroundColor
    }
    
    static var themeBorder: Color {
        ThemeManager.shared.currentColorTheme.borderColor
    }
    
    static var themeAccent: Color {
        ThemeManager.shared.currentColorTheme.accentColor
    }
    
    static var themePrimary: Color {
        ThemeManager.shared.currentColorTheme.primaryColor
    }
    
    static var themeSecondary: Color {
        ThemeManager.shared.currentColorTheme.secondaryColor
    }
    
    static var themeTertiary: Color {
        ThemeManager.shared.currentColorTheme.tertiaryColor
    }
    
    static var themeText: Color {
        ThemeManager.shared.currentColorTheme.textColor
    }
    
    static var themeButton: Color {
        ThemeManager.shared.currentColorTheme.buttonColor
    }
    
    static var themeIcon: Color {
        ThemeManager.shared.currentColorTheme.iconColor
    }
}

// MARK: - View Modifiers
struct ColorThemeModifier: ViewModifier {
    @ObservedObject var themeManager = ThemeManager.shared
    
    func body(content: Content) -> some View {
        content
            .preferredColorScheme(themeManager.colorScheme)
    }
}

extension View {
    func withColorTheme() -> some View {
        self.modifier(ColorThemeModifier())
    }
} 