import SwiftUI

struct ThemeSelectorView: View {
    @Binding var selectedTheme: AppTheme
    @ObservedObject private var themeManager = ThemeManager.shared
    @ObservedObject private var localizationManager = LocalizationManager.shared
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("Выберите тему")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Button("Готово") {
                        dismiss()
                    }
                    .foregroundColor(.blue)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(Color.customCardBackground)
                
                // Theme options
                VStack(spacing: 0) {
                    ForEach(AppTheme.allCases, id: \.self) { theme in
                        ThemeOptionRow(
                            theme: theme,
                            isSelected: selectedTheme == theme
                        ) {
                            selectedTheme = theme
                            themeManager.setTheme(theme)
                        }
                        
                        if theme != AppTheme.allCases.last {
                            Divider()
                                .background(Color.customDivider)
                        }
                    }
                }
                .background(Color.customCardBackground)
                .cornerRadius(12)
                .padding(.horizontal, 20)
                .padding(.top, 20)
                
                Spacer()
            }
            .background(Color.customBackground)
            .navigationBarHidden(true)
        }
    }
}

struct ThemeOptionRow: View {
    let theme: AppTheme
    let isSelected: Bool
    let onTap: () -> Void
    @ObservedObject private var localizationManager = LocalizationManager.shared
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Theme icon
                Image(systemName: theme.icon)
                    .font(.system(size: 20))
                    .foregroundColor(isSelected ? Color.customAccent : Color.customSecondaryText)
                    .frame(width: 24)
                
                // Theme name
                Text(theme.displayName)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(Color.customPrimaryText)
                
                Spacer()
                
                // Selection indicator
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(Color.customAccent)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? Color.customAccent.opacity(0.1) : Color.clear)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Preview
struct ThemeSelectorView_Previews: PreviewProvider {
    static var previews: some View {
        ThemeSelectorView(selectedTheme: .constant(.system))
    }
} 