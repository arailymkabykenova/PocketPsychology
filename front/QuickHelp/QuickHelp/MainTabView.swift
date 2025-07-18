import SwiftUI

struct MainTabView: View {
    @StateObject private var chatService = ChatService()
    @ObservedObject private var localizationManager = LocalizationManager.shared
    @State private var showingSettings = false
    @State private var selectedTab = 1 // Start with chat tab (index 1)
    
    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView(chatService: chatService, showingSettings: $showingSettings)
                .tabItem {
                    Image(systemName: "house.fill")
                    Text(localizationManager.localizedString(.home))
                }
                .tag(0)
            
            ChatView(chatService: chatService)
                .tabItem {
                    Image(systemName: "message.fill")
                    Text(localizationManager.localizedString(.chat))
                }
                .tag(1)
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView(chatService: chatService)
        }
    }
}

#Preview {
    MainTabView()
} 