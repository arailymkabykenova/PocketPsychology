import SwiftUI

struct MessageBubbleView: View {
    let message: ChatMessage
    @State private var isAppearing = false
    @ObservedObject private var localizationManager = LocalizationManager.shared
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            if message.isUser {
                Spacer(minLength: 60)
                messageContent
                    .background(
                        RoundedRectangle(cornerRadius: 18)
                            .fill(Color.userMessageBackground)
                    )
                    .foregroundColor(Color.userMessageText)
            } else {
                messageContent
                    .background(
                        RoundedRectangle(cornerRadius: 18)
                            .fill(Color.assistantMessageBackground)
                    )
                    .foregroundColor(Color.assistantMessageText)
                Spacer(minLength: 60)
            }
        }
        .opacity(isAppearing ? 1 : 0)
        .offset(y: isAppearing ? 0 : 20)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                isAppearing = true
            }
        }
    }
    
    private var messageContent: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Message text - use MarkdownRenderer for AI messages
            if message.isUser {
                Text(message.content)
                    .font(.body)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                    .lineLimit(nil) // Allow unlimited lines
            } else {
                SimpleMarkdownRenderer(message.content, textColor: Color.assistantMessageText)
                    .fixedSize(horizontal: false, vertical: true)
                    .lineLimit(nil) // Allow unlimited lines
            }
            
            // Message metadata
            HStack {
                if !message.isUser {
                    // Mode indicator for AI messages
                    HStack(spacing: 4) {
                        Image(systemName: message.mode.icon)
                            .font(.caption2)
                        Text(message.mode.displayName(for: localizationManager.currentLanguage))
                            .font(.caption2)
                            .fontWeight(.medium)
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(
                        Capsule()
                            .fill(Color(message.mode.color).opacity(0.2))
                    )
                    .foregroundColor(Color(message.mode.color))
                }
                
                Spacer()
                
                // Timestamp
                Text(formatTime(message.timestamp))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .padding(.bottom, 8)
        .frame(maxWidth: .infinity, alignment: .leading) // Use full available width
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

#Preview {
    VStack(spacing: 16) {
        MessageBubbleView(message: ChatMessage(
            content: "Привет! Как дела?",
            isUser: true,
            timestamp: Date(),
            mode: .support
        ))
        
        MessageBubbleView(message: ChatMessage(
            content: "Привет! Я здесь, чтобы выслушать тебя. Как ты себя чувствуешь сегодня?",
            isUser: false,
            timestamp: Date(),
            mode: .support
        ))
        
        MessageBubbleView(message: ChatMessage(
            content: "Что заставляет вас чувствовать это?",
            isUser: false,
            timestamp: Date(),
            mode: .analysis
        ))
    }
    .padding()
} 