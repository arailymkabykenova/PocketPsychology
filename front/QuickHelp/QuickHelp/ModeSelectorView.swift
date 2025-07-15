import SwiftUI

struct ModeSelectorView: View {
    @Binding var selectedMode: ChatMode
    let selectedLanguage: Language
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var localizationManager = LocalizationManager.shared
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 8) {
                    Text(localizationManager.localizedString(.selectMode))
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text(localizationManager.localizedString(.selectModeSubtitle))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 16)
                
                // Mode options
                VStack(spacing: 16) {
                    ForEach(ChatMode.allCases, id: \.self) { mode in
                        ModeOptionCard(
                            mode: mode,
                            isSelected: selectedMode == mode,
                            language: selectedLanguage
                        ) {
                            selectedMode = mode
                            dismiss()
                        }
                    }
                }
                .padding(.horizontal, 16)
                
                Spacer()
            }

            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(localizationManager.localizedString(.done)) {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct ModeOptionCard: View {
    let mode: ChatMode
    let isSelected: Bool
    let language: Language
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Icon
                Image(systemName: mode.icon)
                    .font(.title2)
                    .foregroundColor(isSelected ? .white : mode.color)
                    .frame(width: 40, height: 40)
                    .background(
                        Circle()
                            .fill(isSelected ? mode.color : mode.color.opacity(0.1))
                    )
                
                // Content
                VStack(alignment: .leading, spacing: 4) {
                    Text(mode.displayName(for: language))
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(isSelected ? .white : .primary)
                    
                    Text(mode.description(for: language))
                        .font(.subheadline)
                        .foregroundColor(isSelected ? .white.opacity(0.8) : .secondary)
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
                
                // Selection indicator
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.white)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? mode.color : Color(.systemBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(isSelected ? mode.color : Color.gray.opacity(0.2), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    ModeSelectorView(selectedMode: .constant(.support), selectedLanguage: .russian)
}
