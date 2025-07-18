import SwiftUI

struct CustomTabBar: View {
    @Binding var selectedTab: Int
    @State private var tabOffset: CGFloat = 0
    @State private var isScrolling = false
    @State private var scrollOffset: CGFloat = 0
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
                        isSelected: selectedTab == tab.tag,
                        scrollOffset: scrollOffset,
                        isScrolling: isScrolling
                    ) {
                        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                            selectedTab = tab.tag
                        }
                    }
                }
            }
            .background(
                GeometryReader { geometry in
                    Color.clear
                        .preference(key: TabBarPreferenceKey.self, value: geometry.size.width)
                }
            )
            .onPreferenceChange(TabBarPreferenceKey.self) { width in
                // Calculate offset based on scroll position
                let tabWidth = width / CGFloat(tabs.count)
                tabOffset = CGFloat(selectedTab) * tabWidth
            }
        }
        .background(Color.themeCardBackground)
        .overlay(
            // Top border
            Rectangle()
                .frame(height: 0.5)
                .foregroundColor(Color.gray.opacity(0.3)),
            alignment: .top
        )
        .ignoresSafeArea(.container, edges: .bottom)
        .onReceive(NotificationCenter.default.publisher(for: .scrollOffsetChanged)) { notification in
            if let offset = notification.object as? CGFloat {
                scrollOffset = offset
                isScrolling = abs(offset) > 10
            }
        }
    }
}

struct CustomTabButton: View {
    let tab: TabItem
    let isSelected: Bool
    let scrollOffset: CGFloat
    let isScrolling: Bool
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
    
    // Calculate font size based on scroll offset and selection state
    private var fontSize: CGFloat {
        let baseSize: CGFloat = isSelected ? 12 : 10
        let scrollEffect = max(0, min(1, abs(scrollOffset) / 50)) // More sensitive to scroll
        let sizeReduction = scrollEffect * 1.5 // Reduce size by up to 1.5 points when scrolling
        
        return baseSize - sizeReduction
    }
    
    // Calculate icon size based on scroll offset and selection state
    private var iconSize: CGFloat {
        let baseSize: CGFloat = isSelected ? 24 : 20
        let scrollEffect = max(0, min(1, abs(scrollOffset) / 50)) // More sensitive to scroll
        let sizeReduction = scrollEffect * 2 // Reduce size by up to 2 points when scrolling
        
        return baseSize - sizeReduction
    }
    
    // Calculate opacity based on scroll state
    private var textOpacity: Double {
        let scrollEffect = max(0, min(1, abs(scrollOffset) / 30))
        return 1.0 - (scrollEffect * 0.3) // Reduce opacity by up to 30% when scrolling
    }
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: tab.icon)
                    .font(.system(size: iconSize, weight: .medium))
                    .foregroundColor(isSelected ? .blue : .gray)
                    .scaleEffect(isSelected ? 1.1 : 1.0)
                    .animation(.spring(response: 0.6, dampingFraction: 0.8), value: isSelected)
                
                Text(title)
                    .font(.sfProRoundedHeavy(size: fontSize))
                    .foregroundColor(isSelected ? .blue : .gray)
                    .opacity(textOpacity)
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

struct TabBarPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

// MARK: - Notification Extension
extension Notification.Name {
    static let scrollOffsetChanged = Notification.Name("scrollOffsetChanged")
}

// MARK: - Preview
struct CustomTabBar_Previews: PreviewProvider {
    static var previews: some View {
        CustomTabBar(selectedTab: .constant(0))
    }
} 