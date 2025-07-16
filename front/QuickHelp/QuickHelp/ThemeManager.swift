import SwiftUI
import Foundation

class ThemeManager: ObservableObject {
    @Published var currentTheme: AppTheme = .system
    @Published var colorScheme: ColorScheme?
    
    static let shared = ThemeManager()
    
    private let userDefaults = UserDefaults.standard
    private let themeKey = "selected_theme"
    
    private init() {
        loadSavedTheme()
    }
    
    func setTheme(_ theme: AppTheme) {
        currentTheme = theme
        userDefaults.set(theme.rawValue, forKey: themeKey)
        updateColorScheme()
    }
    
    private func loadSavedTheme() {
        if let savedTheme = userDefaults.string(forKey: themeKey),
           let theme = AppTheme(rawValue: savedTheme) {
            currentTheme = theme
        }
        updateColorScheme()
    }
    
    private func updateColorScheme() {
        switch currentTheme {
        case .light:
            colorScheme = .light
        case .dark:
            colorScheme = .dark
        case .system:
            colorScheme = nil // Use system setting
        }
    }
}

enum AppTheme: String, CaseIterable {
    case light = "light"
    case dark = "dark"
    case system = "system"
    
    var displayName: String {
        switch self {
        case .light:
            return "Светлая"
        case .dark:
            return "Темная"
        case .system:
            return "Системная"
        }
    }
    
    var icon: String {
        switch self {
        case .light:
            return "sun.max.fill"
        case .dark:
            return "moon.fill"
        case .system:
            return "gear"
        }
    }
}

// MARK: - Color Extensions for helpers only (NO duplicates with Assets)
extension Color {
    // Дополнительные цвета, не совпадающие с Assets.xcassets
    static let customAccentSecondary = Color.customAccent.opacity(0.7)
    static let customSuccess = Color.green
    static let customWarning = Color.orange
    static let customError = Color.red
}

// Используйте Color.customBackground, Color.userMessageBackground и т.д. напрямую!

// MARK: - View Modifiers for Dark Theme
struct DarkThemeModifier: ViewModifier {
    @ObservedObject var themeManager = ThemeManager.shared
    
    func body(content: Content) -> some View {
        content
            .preferredColorScheme(themeManager.colorScheme)
    }
}

extension View {
    func withDarkTheme() -> some View {
        self.modifier(DarkThemeModifier())
    }
} 