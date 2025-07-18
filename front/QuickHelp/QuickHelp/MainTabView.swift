import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0
    @StateObject private var chatService = ChatService()
    @ObservedObject private var localizationManager = LocalizationManager.shared
    @State private var showingSettings = false
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // Content views
            Group {
                if selectedTab == 0 {
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
                } else if selectedTab == 1 {
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
                }
            }
            .animation(.easeInOut(duration: 0.3), value: selectedTab)
            
            // Custom TabBar
            CustomTabBar(selectedTab: $selectedTab)
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView(chatService: chatService)
        }
    }
}

#Preview {
    MainTabView()
} 