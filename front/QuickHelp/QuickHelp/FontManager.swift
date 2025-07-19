import SwiftUI

enum FontWeight {
    case heavy
    case semibold
}

struct FontManager {
    // Only the fonts we actually use
    static let sfProRoundedHeavy = "SF-Pro-Rounded-Heavy"
    static let sfProRoundedSemibold = "SF-Pro-Rounded-Semibold"
    
    // Alternative names that might be inside the font files
    static let sfProRoundedHeavyAlt = "SFProRounded-Heavy"
    
    // Cache for font availability to avoid repeated checks
    static var heavyFontName: String?
    static var semiboldFontName: String?
    
    static func initializeFonts() {
        // Pre-check font availability once
        heavyFontName = findAvailableFontName(for: .heavy)
        semiboldFontName = findAvailableFontName(for: .semibold)
    }
    
    private static func findAvailableFontName(for weight: FontWeight) -> String {
        let fontNames: [String]
        
        switch weight {
        case .heavy:
            fontNames = [
                sfProRoundedHeavy,
                sfProRoundedHeavyAlt,
                "SF Pro Rounded Heavy",
                "SFProRounded-Heavy"
            ]
        case .semibold:
            fontNames = [
                sfProRoundedSemibold,
                "SF Pro Rounded Semibold",
                "SFProRounded-Semibold"
            ]
        }
        
        for fontName in fontNames {
            if UIFont.fontNames(forFamilyName: "SF Pro Rounded").contains(fontName) || 
               UIFont.familyNames.contains(fontName) {
                return fontName
            }
        }
        
        return ""
    }
}

extension Font {
    static func sfProRounded(_ weight: FontWeight, size: CGFloat) -> Font {
        let fontName: String
        
        switch weight {
        case .heavy:
            fontName = FontManager.sfProRoundedHeavy
        case .semibold:
            fontName = FontManager.sfProRoundedSemibold
        }
        
        return Font.custom(fontName, size: size)
    }
    
    static func sfProRoundedHeavy(size: CGFloat) -> Font {
        // Use cached font name if available
        if let fontName = FontManager.heavyFontName, !fontName.isEmpty {
            return Font.custom(fontName, size: size)
        }
        
        // Fallback to system font
        return Font.system(size: size, weight: .black, design: .rounded)
    }
    
    static func sfProRoundedSemibold(size: CGFloat) -> Font {
        // Use cached font name if available
        if let fontName = FontManager.semiboldFontName, !fontName.isEmpty {
            return Font.custom(fontName, size: size)
        }
        
        // Fallback to system font
        return Font.system(size: size, weight: .semibold, design: .rounded)
    }
}

// MARK: - Predefined Font Styles
extension Font {
    // Main title styles using SF Pro Rounded Heavy
    static let mainTitle = Font.sfProRoundedHeavy(size: 42)
    static let titleLarge = Font.sfProRoundedHeavy(size: 34)
    static let titleMedium = Font.sfProRoundedHeavy(size: 28)
    static let titleSmall = Font.sfProRoundedHeavy(size: 24)
    
    // Headline styles using SF Pro Rounded Heavy
    static let headlineLarge = Font.sfProRoundedHeavy(size: 22)
    static let headlineMedium = Font.sfProRoundedHeavy(size: 20)
    static let headlineSmall = Font.sfProRoundedHeavy(size: 18)
    
    // Subtitle styles using SF Pro Rounded Heavy
    static let subtitleLarge = Font.sfProRoundedHeavy(size: 16)
    static let subtitleMedium = Font.sfProRoundedHeavy(size: 15)
    static let subtitleSmall = Font.sfProRoundedHeavy(size: 14)
    
    // Body styles using SF Pro Rounded Semibold
    static let bodyLarge = Font.sfProRoundedSemibold(size: 17)
    static let bodyMedium = Font.sfProRoundedSemibold(size: 16)
    static let bodySmall = Font.sfProRoundedSemibold(size: 15)
    
    // Caption styles using SF Pro Rounded Semibold
    static let captionLarge = Font.sfProRoundedSemibold(size: 14)
    static let captionMedium = Font.sfProRoundedSemibold(size: 13)
    static let captionSmall = Font.sfProRoundedSemibold(size: 12)
} 