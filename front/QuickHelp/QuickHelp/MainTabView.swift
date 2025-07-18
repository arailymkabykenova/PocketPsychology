import SwiftUI

struct MainTabView: View {
    @StateObject private var chatService = ChatService()
    @ObservedObject private var localizationManager = LocalizationManager.shared
    @State private var showingSettings = false
    @State private var selectedTab = 0
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // Content views
            Group {
                if selectedTab == 0 {
                    HomeView(chatService: chatService, showingSettings: $showingSettings)
                } else if selectedTab == 1 {
                    ChatView(chatService: chatService)
                }
            }
            .animation(.easeInOut(duration: 0.3), value: selectedTab)
            
            // Custom TabBar that looks like native iOS TabView
            CustomTabBar(selectedTab: $selectedTab)
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView(chatService: chatService)
        }
    }
}

struct CustomTabBar: View {
    @Binding var selectedTab: Int
    @ObservedObject private var localizationManager = LocalizationManager.shared
    
    private let tabs = [
        TabItem(icon: "house.fill", title: "home", tag: 0),
        TabItem(icon: "message.fill", title: "chat", tag: 1)
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            HStack(spacing: 0) {
                ForEach(tabs, id: \.tag) { tab in
                    CustomTabButton(
                        tab: tab,
                        isSelected: selectedTab == tab.tag
                    ) {
                        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                            selectedTab = tab.tag
                        }
                    }
                }
            }
            .background(
                Rectangle()
                    .fill(.ultraThinMaterial)
                    .overlay(
                        Rectangle()
                            .frame(height: 0.5)
                            .foregroundColor(Color.gray.opacity(0.3)),
                        alignment: .top
                    )
            )
            .ignoresSafeArea(.container, edges: .bottom)
        }
    }
}

struct CustomTabButton: View {
    let tab: TabItem
    let isSelected: Bool
    let action: () -> Void
    
    @ObservedObject private var localizationManager = LocalizationManager.shared
    
    private var title: String {
        switch tab.title {
        case "home":
            return localizationManager.localizedString(.home)
        case "chat":
            return localizationManager.localizedString(.chat)
        default:
            return ""
        }
    }
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: tab.icon)
                    .font(.system(size: isSelected ? 24 : 20, weight: .medium))
                    .foregroundColor(isSelected ? .blue : .gray)
                    .scaleEffect(isSelected ? 1.1 : 1.0)
                    .animation(.spring(response: 0.6, dampingFraction: 0.8), value: isSelected)
                
                Text(title)
                    .font(.sfProRoundedSemibold(size: isSelected ? 12 : 10))
                    .foregroundColor(isSelected ? .blue : .gray)
                    .scaleEffect(isSelected ? 1.0 : 0.9)
                    .animation(.spring(response: 0.6, dampingFraction: 0.8), value: isSelected)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct TabItem {
    let icon: String
    let title: String
    let tag: Int
}

// MARK: - Preview
struct MainTabView_Previews: PreviewProvider {
    static var previews: some View {
        MainTabView()
    }
}

#Preview {
    MainTabView()
} 