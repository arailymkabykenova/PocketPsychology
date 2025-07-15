import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0
    @ObservedObject private var localizationManager = LocalizationManager.shared
    
    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem {
                    Image(systemName: "house.fill")
                    Text(localizationManager.localizedString(.home))
                }
                .tag(0)
            
            ChatView()
                .tabItem {
                    Image(systemName: "message.fill")
                    Text(localizationManager.localizedString(.chat))
                }
                .tag(1)
        }
        .accentColor(.blue)
    }
}

#Preview {
    MainTabView()
} 