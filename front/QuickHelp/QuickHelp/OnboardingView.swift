import SwiftUI

struct OnboardingView: View {
    @State private var currentPage = 0
    @State private var isAnimating = false
    @Binding var currentStep: AppStartupStep
    @ObservedObject private var localizationManager = LocalizationManager.shared
    
    private var pages: [OnboardingPage] {
        [
            OnboardingPage(
                title: localizationManager.currentLanguage == .russian ? "Добро пожаловать в QuickHelp" : "Welcome to QuickHelp",
                description: localizationManager.currentLanguage == .russian ? 
                    "Ваш ИИ-компаньон для эмоциональной поддержки и роста" :
                    "Your AI companion for emotional support and growth",
                icon: "heart.fill",
                color: .pink
            ),
            OnboardingPage(
                title: localizationManager.currentLanguage == .russian ? "Три режима общения" : "Three Conversation Modes",
                description: localizationManager.currentLanguage == .russian ?
                    "Поддержка, Анализ и Практика - выберите подходящий режим" :
                    "Support, Analysis, and Practice - choose what works best for you",
                icon: "message.circle.fill",
                color: .blue
            ),
            OnboardingPage(
                title: localizationManager.currentLanguage == .russian ? "Персонализированный контент" : "Personalized Content",
                description: localizationManager.currentLanguage == .russian ?
                    "Получайте статьи, видео и цитаты под ваши интересы" :
                    "Get articles, videos, and quotes tailored to your interests",
                icon: "sparkles",
                color: .orange
            ),
            OnboardingPage(
                title: localizationManager.currentLanguage == .russian ? "Ваша конфиденциальность важна" : "Your Privacy Matters",
                description: localizationManager.currentLanguage == .russian ?
                    "Все данные остаются на устройстве. Начните путь безопасно." :
                    "All your data stays on your device. Start your journey safely.",
                icon: "lock.shield.fill",
                color: .green
            )
        ]
    }
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.themeBackground,
                    Color.themeBackground.opacity(0.8)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Page content
                TabView(selection: $currentPage) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        OnboardingPageView(page: pages[index])
                            .tag(index)
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                .animation(.easeInOut(duration: 0.3), value: currentPage)
                
                // Bottom controls
                VStack(spacing: 20) {
                    // Page indicators
                    HStack(spacing: 8) {
                        ForEach(0..<pages.count, id: \.self) { index in
                            Circle()
                                .fill(currentPage == index ? Color.themeButton : Color.gray.opacity(0.3))
                                .frame(width: 8, height: 8)
                                .scaleEffect(currentPage == index ? 1.2 : 1.0)
                                .animation(.spring(response: 0.4, dampingFraction: 0.8), value: currentPage)
                        }
                    }
                    
                    // Action buttons
                    HStack(spacing: 16) {
                        // Skip button (only show on first page)
                        if currentPage == 0 {
                            Button(localizationManager.currentLanguage == .russian ? "Пропустить" : "Skip") {
                                completeOnboarding()
                            }
                            .font(.sfProRoundedSemibold(size: 16))
                            .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        // Next/Get Started button
                        Button(action: {
                            if currentPage < pages.count - 1 {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    currentPage += 1
                                }
                            } else {
                                completeOnboarding()
                            }
                        }) {
                            HStack(spacing: 8) {
                                Text(currentPage < pages.count - 1 ? 
                                    (localizationManager.currentLanguage == .russian ? "Далее" : "Next") :
                                    (localizationManager.currentLanguage == .russian ? "Начать" : "Get Started"))
                                    .font(.sfProRoundedSemibold(size: 18))
                                
                                if currentPage < pages.count - 1 {
                                    Image(systemName: "arrow.right")
                                        .font(.system(size: 16, weight: .medium))
                                }
                            }
                            .foregroundColor(.white.opacity(1.0))
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                            .background(
                                Capsule()
                                    .fill(.ultraThinMaterial)
                                    .overlay(
                                        Capsule()
                                            .stroke(
                                                LinearGradient(
                                                    gradient: Gradient(colors: [
                                                        Color.themeButton.opacity(0.6),
                                                        Color.themeAccent.opacity(0.4)
                                                    ]),
                                                    startPoint: .leading,
                                                    endPoint: .trailing
                                                ),
                                                lineWidth: 1
                                            )
                                    )
                            )
                            .shadow(color: Color.themeButton.opacity(0.2), radius: 8, x: 0, y: 4)
                        }
                    }
                    .padding(.horizontal, 24)
                }
                .padding(.bottom, 40)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.8).delay(0.2)) {
                isAnimating = true
            }
        }
    }
    
    private func completeOnboarding() {
        // Mark onboarding as completed
        UserDefaults.standard.set(true, forKey: "onboarding_completed")
        
        // Proceed to main app
        withAnimation(.easeInOut(duration: 0.6)) {
            currentStep = .mainApp
        }
    }
}

struct OnboardingPage {
    let title: String
    let description: String
    let icon: String
    let color: Color
}

struct OnboardingPageView: View {
    let page: OnboardingPage
    @ObservedObject private var localizationManager = LocalizationManager.shared
    
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            // Icon
            ZStack {
                Circle()
                    .fill(.ultraThinMaterial)
                    .overlay(
                        Circle()
                            .stroke(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        page.color.opacity(0.4),
                                        page.color.opacity(0.2)
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 2
                            )
                    )
                    .frame(width: 120, height: 120)
                    .shadow(color: page.color.opacity(0.2), radius: 20, x: 0, y: 10)
                
                Image(systemName: page.icon)
                    .font(.system(size: 50))
                    .foregroundColor(page.color)
            }
            
            // Content
            VStack(spacing: 16) {
                Text(page.title)
                    .font(.sfProRoundedHeavy(size: 24))
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                
                Text(page.description)
                    .font(.sfProRoundedSemibold(size: 15))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .lineLimit(nil)
            }
            .padding(.horizontal, 40)
            
            Spacer()
        }
        .padding(.top, 60)
    }
}

#Preview {
    OnboardingView(currentStep: .constant(.onboarding))
} 