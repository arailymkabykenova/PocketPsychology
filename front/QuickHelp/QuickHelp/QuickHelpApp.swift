import SwiftUI

@main
struct QuickHelpApp: App {
    init() {
        // Initialize fonts
        FontManager.printAvailableFonts()
    }
    
    var body: some Scene {
        WindowGroup {
            MainTabView()
                .withColorTheme()
        }
    }
} 