import SwiftUI

struct ConnectionStatusView: View {
    let isConnected: Bool
    let onRetry: () -> Void
    @ObservedObject private var localizationManager = LocalizationManager.shared
    
    var body: some View {
        HStack(spacing: 12) {
            // Status indicator
            Circle()
                .fill(isConnected ? Color.green : Color.red)
                .frame(width: 8, height: 8)
                .scaleEffect(isConnected ? 1.0 : 1.2)
                .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: isConnected)
            
            // Status text
            Text(isConnected ? localizationManager.localizedString(.connectedToServer) : localizationManager.localizedString(.notConnectedToServer))
                .font(.caption)
                .foregroundColor(isConnected ? .green : .red)
            
            Spacer()
            
            // Retry button
            if !isConnected {
                Button(action: onRetry) {
                    Image(systemName: "arrow.clockwise")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.systemGray6))
        )
        .padding(.horizontal, 16)
    }
}

#Preview {
    VStack(spacing: 16) {
        ConnectionStatusView(isConnected: true, onRetry: {})
        ConnectionStatusView(isConnected: false, onRetry: {})
    }
    .padding()
} 