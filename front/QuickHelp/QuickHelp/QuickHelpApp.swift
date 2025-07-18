import SwiftUI

@main
struct QuickHelpApp: App {
    @State private var currentStep: AppStartupStep = .launchScreen
    @AppStorage("onboarding_completed") private var hasCompletedOnboarding = false
    @AppStorage("selected_language") private var selectedLanguage: String = ""
    
    init() {
        // Initialize fonts silently
    }
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                // Main app (always present but hidden during startup)
                MainTabView()
                    .withColorTheme()
                    .opacity(currentStep == .mainApp ? 1 : 0)
                
                // Startup flow
                if currentStep != .mainApp {
                    switch currentStep {
                    case .launchScreen:
                        LaunchScreenView()
                            .transition(.opacity)
                            .zIndex(1)
                    case .languageSelection:
                        LanguageSelectionView(currentStep: $currentStep)
                            .transition(.opacity)
                            .zIndex(1)
                    case .onboarding:
                        OnboardingView(currentStep: $currentStep)
                            .transition(.opacity)
                            .zIndex(1)
                    case .mainApp:
                        EmptyView()
                    }
                }
            }
            .onAppear {
                startAppFlow()
            }
        }
    }
    
    private func startAppFlow() {
        // Show launch screen for 3 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            withAnimation(.easeInOut(duration: 0.8)) {
                // Check if user has actually selected a language (not just default)
                let hasSelectedLanguage = LocalizationManager.shared.hasUserSelectedLanguage()
                
                if hasCompletedOnboarding && hasSelectedLanguage {
                    // Skip to main app if both onboarding and language selection were completed
                    currentStep = .mainApp
                } else if !hasSelectedLanguage {
                    // Show language selection first if language not selected
                    currentStep = .languageSelection
                } else {
                    // Show onboarding if language selected but onboarding not completed
                    currentStep = .onboarding
                }
            }
        }
    }
} 