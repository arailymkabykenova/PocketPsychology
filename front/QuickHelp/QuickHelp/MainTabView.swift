import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0
    @StateObject private var chatService = ChatService()
    @ObservedObject private var localizationManager = LocalizationManager.shared
    @State private var showingSettings = false
    
    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView(chatService: chatService, showingSettings: $showingSettings)
                .navigationTitle("QUICK HELP")
                .navigationBarTitleDisplayMode(.large)
                .toolbar {
                    ToolbarItem(placement: .principal) {
                        Text("QUICK HELP")
                            .font(.sfProRoundedHeavy(size: 28))
                            .foregroundColor(.primary)
                    }
                }
                .tabItem {
                    Image(systemName: "house.fill")
                    Text(localizationManager.localizedString(.home))
                }
                .tag(0)
            
            ChatView(chatService: chatService)
                .navigationTitle("CHAT")
                .navigationBarTitleDisplayMode(.large)
                .toolbar {
                    ToolbarItem(placement: .principal) {
                        Text("CHAT")
                            .font(.sfProRoundedHeavy(size: 28))
                            .foregroundColor(.primary)
                    }
                }
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