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
    
    // Debug function to check available fonts
    static func printAvailableFonts() {
        print("🔍 Checking available fonts...")
        for family in UIFont.familyNames.sorted() {
            let names = UIFont.fontNames(forFamilyName: family)
            print("📁 Family: \(family)")
            print("   Fonts: \(names)")
            
            // Check specifically for SF Pro Rounded
            if family.contains("SF Pro") || family.contains("Rounded") {
                print("🎯 Found SF Pro Rounded family: \(family)")
                print("   Available fonts: \(names)")
            }
        }
        
        // Check if our specific fonts are available
        let allFontNames = UIFont.familyNames.flatMap { UIFont.fontNames(forFamilyName: $0) }
        print("🔎 Looking for our specific fonts:")
        
        let heavyFontNames = [sfProRoundedHeavy, sfProRoundedHeavyAlt, "SF Pro Rounded Heavy", "SFProRounded-Heavy"]
        let semiboldFontNames = [sfProRoundedSemibold, "SF Pro Rounded Semibold", "SFProRounded-Semibold"]
        
        print("   Heavy fonts:")
        for name in heavyFontNames {
            print("     \(name): \(allFontNames.contains(name) ? "✅ Found" : "❌ Not found")")
        }
        
        print("   Semibold fonts:")
        for name in semiboldFontNames {
            print("     \(name): \(allFontNames.contains(name) ? "✅ Found" : "❌ Not found")")
        }
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
        // Try different possible font names
        let fontNames = [
            FontManager.sfProRoundedHeavy,
            FontManager.sfProRoundedHeavyAlt,
            "SF Pro Rounded Heavy",
            "SFProRounded-Heavy"
        ]
        
        for fontName in fontNames {
            if UIFont.fontNames(forFamilyName: "SF Pro Rounded").contains(fontName) || 
               UIFont.familyNames.contains(fontName) {
                print("✅ Using custom font: \(fontName)")
                return Font.custom(fontName, size: size)
            }
        }
        
        print("⚠️ Custom font not found, using system font")
        return Font.system(size: size, weight: .black, design: .rounded)
    }
    

    

    
    static func sfProRoundedSemibold(size: CGFloat) -> Font {
        // Try different possible font names
        let fontNames = [
            FontManager.sfProRoundedSemibold,
            "SF Pro Rounded Semibold",
            "SFProRounded-Semibold"
        ]
        
        for fontName in fontNames {
            if UIFont.fontNames(forFamilyName: "SF Pro Rounded").contains(fontName) || 
               UIFont.familyNames.contains(fontName) {
                print("✅ Using custom font: \(fontName)")
                return Font.custom(fontName, size: size)
            }
        }
        
        print("⚠️ Custom font not found, using system font")
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