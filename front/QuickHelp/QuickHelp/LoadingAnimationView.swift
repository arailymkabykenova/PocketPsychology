import SwiftUI

struct LoadingAnimationView: View {
    let topic: String
    @State private var animationPhase = 0
    @State private var dotOpacity: [Double] = [0.3, 0.3, 0.3]
    @ObservedObject private var localizationManager = LocalizationManager.shared
    
    private let timer = Timer.publish(every: 0.6, on: .main, in: .common).autoconnect()
    
    var body: some View {
        VStack(spacing: 24) {
            // Main loading card
            VStack(spacing: 20) {
                // Animated icon
                ZStack {
                    Circle()
                        .fill(Color.blue.opacity(0.1))
                        .frame(width: 80, height: 80)
                    
                    Image(systemName: "brain.head.profile")
                        .font(.system(size: 32))
                        .foregroundColor(.blue)
                        .scaleEffect(1.0 + 0.1 * sin(Double(animationPhase) * 0.5))
                        .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: animationPhase)
                }
                
                // Loading text
                VStack(spacing: 8) {
                    Text(localizationManager.localizedString(.generatingContent))
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Text(localizationManager.currentLanguage == .russian ? "для темы «\(topic)»" : "for topic «\(topic)»")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                
                // Animated dots
                HStack(spacing: 8) {
                    ForEach(0..<3, id: \.self) { index in
                        Circle()
                            .fill(Color.blue)
                            .frame(width: 8, height: 8)
                            .opacity(dotOpacity[index])
                            .scaleEffect(dotOpacity[index] == 1.0 ? 1.2 : 1.0)
                            .animation(.easeInOut(duration: 0.3), value: dotOpacity[index])
                    }
                }
                
                // Progress indicator
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                    .scaleEffect(0.8)
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.blue.opacity(0.2), lineWidth: 1)
            )
        }
        .onReceive(timer) { _ in
            withAnimation {
                // Rotate through dots
                for i in 0..<3 {
                    dotOpacity[i] = (animationPhase % 3 == i) ? 1.0 : 0.3
                }
                animationPhase += 1
            }
        }
        .onAppear {
            animationPhase = 0
            // Start with first dot active
            dotOpacity = [1.0, 0.3, 0.3]
        }
    }
}

// MARK: - Compact Loading View
struct CompactLoadingView: View {
    let topic: String
    @State private var animationPhase = 0
    @ObservedObject private var localizationManager = LocalizationManager.shared
    
    var body: some View {
        HStack(spacing: 12) {
            // Animated icon
            Image(systemName: "brain.head.profile")
                .font(.system(size: 20))
                .foregroundColor(.blue)
                .scaleEffect(1.0 + 0.1 * sin(Double(animationPhase) * 0.5))
                .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: animationPhase)
            
            // Loading text
            VStack(alignment: .leading, spacing: 2) {
                Text(localizationManager.localizedString(.generatingContent))
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Text(localizationManager.currentLanguage == .russian ? "для темы «\(topic)»" : "for topic «\(topic)»")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Progress indicator
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                .scaleEffect(0.7)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        )
        .onAppear {
            animationPhase = 0
        }
        .onReceive(Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()) { _ in
            animationPhase += 1
        }
    }
}

// MARK: - Content Loading Overlay
struct ContentLoadingOverlay: View {
    let topic: String
    let isLoading: Bool
    
    var body: some View {
        if isLoading {
            ZStack {
                // Semi-transparent background covering entire screen
                Color.black.opacity(0.4)
                    .ignoresSafeArea(.all, edges: .all)
                
                // Loading animation
                LoadingAnimationView(topic: topic)
            }
            .transition(.opacity.combined(with: .scale))
            .zIndex(1000) // Ensure it's above everything
        }
    }
}

// MARK: - Preview
struct LoadingAnimationView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            LoadingAnimationView(topic: "Стресс")
            CompactLoadingView(topic: "Апатия")
        }
        .padding()
        .background(Color(.systemGray6))
    }
} 