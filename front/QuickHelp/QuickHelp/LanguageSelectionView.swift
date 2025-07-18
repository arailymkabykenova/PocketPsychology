import SwiftUI

struct LanguageSelectionView: View {
    @State private var selectedLanguage: Language = .russian
    @State private var isAnimating = false
    @Binding var currentStep: AppStartupStep
    
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
            
            VStack(spacing: 40) {
                // Header
                VStack(spacing: 16) {
                    Text(selectedLanguage == .russian ? "Выберите язык" : "Choose Language")
                        .font(.sfProRoundedHeavy(size: 32))
                        .foregroundColor(.primary)
                }
                .opacity(isAnimating ? 1 : 0)
                .offset(y: isAnimating ? 0 : -20)
                
                // Language options
                VStack(spacing: 20) {
                    LanguageOptionCard(
                        language: .russian,
                        isSelected: selectedLanguage == .russian,
                        onTap: {
                            selectedLanguage = .russian
                        }
                    )
                    
                    LanguageOptionCard(
                        language: .english,
                        isSelected: selectedLanguage == .english,
                        onTap: {
                            selectedLanguage = .english
                        }
                    )
                }
                .opacity(isAnimating ? 1 : 0)
                .offset(y: isAnimating ? 0 : 30)
                
                Spacer()
                
                // Continue button
                Button(action: {
                    // Set language and proceed to onboarding
                    LocalizationManager.shared.setLanguage(selectedLanguage)
                    withAnimation(.easeInOut(duration: 0.6)) {
                        currentStep = .onboarding
                    }
                }) {
                    continueButtonContent
                }
                .opacity(isAnimating ? 1 : 0)
                .scaleEffect(isAnimating ? 1 : 0.8)
            }
            .padding(.horizontal, 24)
            .padding(.top, 60)
            .padding(.bottom, 40)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.8).delay(0.2)) {
                isAnimating = true
            }
        }
    }
    
    private var continueButtonContent: some View {
        Text(selectedLanguage == .russian ? "Продолжить" : "Continue")
            .font(.sfProRoundedSemibold(size: 18))
            .foregroundColor(.white)
            .padding(.horizontal, 32)
            .padding(.vertical, 16)
            .background(continueButtonBackground)
            .shadow(color: Color.themeButton.opacity(0.2), radius: 8, x: 0, y: 4)
    }
    
    private var continueButtonBackground: some View {
        Capsule()
            .fill(.ultraThinMaterial)
            .overlay(continueButtonStroke)
    }
    
    private var continueButtonStroke: some View {
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
    }
}

struct LanguageOptionCard: View {
    let language: Language
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 20) {
                // Flag
                Text(language.flag)
                    .font(.system(size: 40))
                
                // Language info
                VStack(alignment: .leading, spacing: 4) {
                    Text(language.displayName)
                        .font(.sfProRoundedHeavy(size: 24))
                        .foregroundColor(isSelected ? .white : .primary)
                    
                    Text(language == .russian ? "Русский" : "English")
                        .font(.sfProRoundedSemibold(size: 18))
                        .foregroundColor(isSelected ? .white.opacity(0.8) : .secondary)
                }
                
                Spacer()
                
                // Selection indicator
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title)
                        .foregroundColor(.white)
                }
            }
            .padding(24)
            .background(cardBackground)
            .shadow(color: isSelected ? Color.themeButton.opacity(0.3) : Color.black.opacity(0.1), radius: 15, x: 0, y: 8)
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isSelected ? 1.02 : 1.0)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isSelected)
    }
    
    private var cardBackground: some View {
        Group {
            if isSelected {
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.themeButton)
            } else {
                RoundedRectangle(cornerRadius: 20)
                    .fill(.ultraThinMaterial)
            }
        }
        .overlay(cardStroke)
    }
    
    private var cardStroke: some View {
        RoundedRectangle(cornerRadius: 20)
            .stroke(
                isSelected ? Color.themeButton : Color.white.opacity(0.2),
                lineWidth: isSelected ? 0 : 1
            )
    }
}

#Preview {
    LanguageSelectionView(currentStep: .constant(.languageSelection))
} 