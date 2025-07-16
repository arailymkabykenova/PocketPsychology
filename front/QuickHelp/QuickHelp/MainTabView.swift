import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0
    @StateObject private var chatService = ChatService()
    @ObservedObject private var localizationManager = LocalizationManager.shared
    @State private var showingSettings = false
    
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
        .accentColor(.blue)
        .sheet(isPresented: $showingSettings) {
            SettingsView(chatService: chatService)
        }
    }
}

#Preview {
    MainTabView()
} 