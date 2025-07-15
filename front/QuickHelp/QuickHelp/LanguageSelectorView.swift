import SwiftUI

struct LanguageSelectorView: View {
    @Binding var selectedLanguage: Language
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var localizationManager = LocalizationManager.shared
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 8) {
                    Text(localizationManager.localizedString(.chooseLanguage))
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text("Choose your preferred language")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top)
                
                // Language options
                VStack(spacing: 16) {
                    ForEach(Language.allCases, id: \.self) { language in
                        LanguageCardView(
                            language: language,
                            isSelected: selectedLanguage == language
                        ) {
                            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                                selectedLanguage = language
                                localizationManager.setLanguage(language)
                            }
                            dismiss()
                        }
                    }
                }
                
                Spacer()
            }
            .padding(.horizontal, 20)

            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(localizationManager.localizedString(.done)) {
                        dismiss()
                    }
                    .fontWeight(.medium)
                }
            }
        }
    }
}

struct LanguageCardView: View {
    let language: Language
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Flag
                Text(language.flag)
                    .font(.system(size: 32))
                    .frame(width: 48, height: 48)
                    .background(
                        Circle()
                            .fill(Color.blue.opacity(0.1))
                    )
                
                // Content
                VStack(alignment: .leading, spacing: 4) {
                    Text(language.displayName)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                }
                
                Spacer()
                
                // Selection indicator
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.blue)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? Color.blue.opacity(0.1) : Color(.systemGray6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isSelected ? 1.02 : 1.0)
        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: isSelected)
    }
}

#Preview {
    LanguageSelectorView(selectedLanguage: .constant(.russian))
} 