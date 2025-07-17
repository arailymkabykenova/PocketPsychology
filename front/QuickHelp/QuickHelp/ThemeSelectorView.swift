import SwiftUI

struct ThemeSelectorView: View {
    @ObservedObject private var themeManager = ThemeManager.shared
    @ObservedObject private var localizationManager = LocalizationManager.shared
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                HStack {
                    Text(localizationManager.localizedString(.selectTheme))
                        .font(.sfProRoundedHeavy(size: 28))
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Button(localizationManager.localizedString(.done)) {
                        dismiss()
                    }
                    .foregroundColor(.themeButton)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(Color.themeCardBackground)
                
                // Color theme options
                VStack(spacing: 24) {
                    // Color circles in a row
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: 4), spacing: 20) {
                        ForEach(ColorTheme.allCases, id: \.self) { theme in
                            ColorThemeCircle(
                                theme: theme,
                                isSelected: themeManager.currentColorTheme == theme
                            ) {
                                themeManager.setColorTheme(theme)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    
                    // Theme name
                    Text(themeManager.currentColorTheme.displayName)
                        .font(.sfProRoundedSemibold(size: 24))
                        .foregroundColor(.primary)
                        .padding(.top, 8)
                    
                    // Preview card
                    VStack(spacing: 16) {
                        Text(localizationManager.localizedString(.preview))
                            .font(.sfProRoundedSemibold(size: 20))
                            .foregroundColor(.primary)
                        
                        PreviewCard()
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                }
                
                Spacer()
            }
            .background(Color.themeBackground)
            .navigationBarHidden(true)
        }
    }
}

struct ColorThemeCircle: View {
    let theme: ColorTheme
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            ZStack {
                // Main circle with theme color gradient
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                theme.primaryColor,
                                theme.secondaryColor
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 60, height: 60)
                    .shadow(color: theme.primaryColor.opacity(0.3), radius: 8, x: 0, y: 4)
                
                // Selection indicator
                if isSelected {
                    Circle()
                        .stroke(Color.white, lineWidth: 3)
                        .frame(width: 70, height: 70)
                    
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.white)
                        .shadow(color: Color.black.opacity(0.3), radius: 2, x: 0, y: 1)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isSelected ? 1.1 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}

struct PreviewCard: View {
    @ObservedObject private var themeManager = ThemeManager.shared
    @ObservedObject private var localizationManager = LocalizationManager.shared
    
    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    themeManager.currentColorTheme.primaryColor,
                                    themeManager.currentColorTheme.secondaryColor
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: "heart.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.white)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(localizationManager.localizedString(.exampleCard))
                        .font(.sfProRoundedSemibold(size: 20))
                        .foregroundColor(.primary)
                    
                    Text(localizationManager.localizedString(.exampleCardDescription))
                        .font(.sfProRoundedSemibold(size: 16))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            // Content
            Text("Здесь будет отображаться контент с выбранной цветовой схемой. Все элементы интерфейса будут использовать пастельные цвета выбранной темы.")
                .font(.sfProRoundedSemibold(size: 17))
                .foregroundColor(.primary)
                .lineSpacing(4)
            
            // Button
            Button(localizationManager.localizedString(.exampleButton)) {
                // Preview action
            }
            .font(.sfProRoundedSemibold(size: 16))
            .foregroundColor(.white)
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                themeManager.currentColorTheme.buttonColor,
                                themeManager.currentColorTheme.accentColor
                            ]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
            )
            .shadow(color: themeManager.currentColorTheme.buttonColor.opacity(0.3), radius: 5, x: 0, y: 2)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.themeCardBackground)
                .shadow(color: Color.black.opacity(0.08), radius: 15, x: 0, y: 8)
        )
    }
}

// MARK: - Preview
struct ThemeSelectorView_Previews: PreviewProvider {
    static var previews: some View {
        ThemeSelectorView()
    }
} 