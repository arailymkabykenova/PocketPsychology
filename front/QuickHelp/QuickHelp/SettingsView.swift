import SwiftUI

struct SettingsView: View {
    @ObservedObject var chatService: ChatService
    @ObservedObject private var themeManager = ThemeManager.shared
    @ObservedObject private var localizationManager = LocalizationManager.shared
    @State private var showingDeleteAlert = false
    @State private var showingThemeSelector = false
    @State private var isDeleting = false
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            List {
                // Theme Section
                Section {
                    Button(action: {
                        showingThemeSelector = true
                    }) {
                        HStack {
                            Image(systemName: "paintbrush")
                                .font(.system(size: 16))
                                .foregroundColor(Color.customAccent)
                                .frame(width: 24)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(localizationManager.localizedString(.selectTheme))
                                    .font(.body)
                                    .fontWeight(.medium)
                                    .foregroundColor(Color.customPrimaryText)
                                
                                Text(themeManager.currentTheme.displayName)
                                    .font(.caption)
                                    .foregroundColor(Color.customSecondaryText)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(Color.customSecondaryText)
                        }
                        .padding(.vertical, 4)
                    }
                    .buttonStyle(PlainButtonStyle())
                } header: {
                    Text(localizationManager.localizedString(.appearance))
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(Color.customPrimaryText)
                }
                
                // Account Section
                Section {
                    Button(action: {
                        showingDeleteAlert = true
                    }) {
                        HStack {
                            Image(systemName: "trash")
                                .font(.system(size: 16))
                                .foregroundColor(.red)
                                .frame(width: 24)
                            
                            Text(localizationManager.localizedString(.deleteAccount))
                                .font(.body)
                                .fontWeight(.medium)
                                .foregroundColor(.red)
                            
                            Spacer()
                        }
                        .padding(.vertical, 4)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .disabled(isDeleting)
                } header: {
                    Text(localizationManager.localizedString(.account))
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(Color.customPrimaryText)
                } footer: {
                    Text(localizationManager.localizedString(.deleteAccountWarning))
                        .font(.caption)
                        .foregroundColor(Color.customSecondaryText)
                }
            }
            .navigationTitle(localizationManager.localizedString(.settings))
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(localizationManager.localizedString(.done)) {
                        dismiss()
                    }
                    .fontWeight(.medium)
                }
            }
        }
        .sheet(isPresented: $showingThemeSelector) {
            ThemeSelectorView(selectedTheme: $themeManager.currentTheme)
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
        .alert(localizationManager.localizedString(.deleteAccountAlert), isPresented: $showingDeleteAlert) {
            Button(localizationManager.localizedString(.cancel), role: .cancel) { }
            Button(localizationManager.localizedString(.delete), role: .destructive) {
                Task {
                    await deleteAccount()
                }
            }
        } message: {
            Text(localizationManager.localizedString(.deleteAccountConfirmation))
        }
    }
    
    private func deleteAccount() async {
        isDeleting = true
        
        do {
            let userId = chatService.userId
            let url = URL(string: "https://pinkponys.org/user/\(userId)/delete")!
            
            var request = URLRequest(url: url)
            request.httpMethod = "DELETE"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode == 200 {
                    // Successfully deleted account
                    DispatchQueue.main.async {
                        // Clear local data
                        chatService.clearAllData()
                        
                        // Dismiss settings and show success message
                        dismiss()
                        
                        // You might want to show a success alert here
                        print("Account deleted successfully")
                    }
                } else {
                    print("Failed to delete account: HTTP \(httpResponse.statusCode)")
                }
            }
        } catch {
            print("Error deleting account: \(error)")
        }
        
        isDeleting = false
    }
}

#Preview {
    SettingsView(chatService: ChatService())
} 