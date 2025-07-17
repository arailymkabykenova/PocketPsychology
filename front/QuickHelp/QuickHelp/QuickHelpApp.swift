import SwiftUI

@main
struct QuickHelpApp: App {
    var body: some Scene {
        WindowGroup {
            MainTabView()
                .withColorTheme()
        }
    }
} 