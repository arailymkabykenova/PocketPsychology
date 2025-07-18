import SwiftUI

struct LaunchScreenView: View {
    @State private var waveOffset1: CGFloat = 0
    @State private var waveOffset2: CGFloat = 0
    @State private var waveOffset3: CGFloat = 0
    @State private var textOpacity: Double = 0
    @State private var textScale: CGFloat = 0.8
    @State private var isAnimating = false
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.themeBackground,
                    Color.themeBackground.opacity(0.8)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            // Animated waves
            ZStack {
                // Wave 1 - slow and wide
                WaveShape(frequency: 0.8, amplitude: 60, phase: waveOffset1)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.white.opacity(0.3),
                                Color.white.opacity(0.1)
                            ]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .overlay(
                        WaveShape(frequency: 0.8, amplitude: 60, phase: waveOffset1)
                            .stroke(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color.white.opacity(0.4),
                                        Color.white.opacity(0.2)
                                    ]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                ),
                                lineWidth: 1
                            )
                    )
                    .offset(y: 200)
                
                // Wave 2 - medium speed and size
                WaveShape(frequency: 1.2, amplitude: 40, phase: waveOffset2)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.white.opacity(0.25),
                                Color.white.opacity(0.08)
                            ]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .overlay(
                        WaveShape(frequency: 1.2, amplitude: 40, phase: waveOffset2)
                            .stroke(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color.white.opacity(0.35),
                                        Color.white.opacity(0.15)
                                    ]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                ),
                                lineWidth: 0.8
                            )
                    )
                    .offset(y: 250)
                
                // Wave 3 - fast and small
                WaveShape(frequency: 1.6, amplitude: 30, phase: waveOffset3)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.white.opacity(0.2),
                                Color.white.opacity(0.06)
                            ]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .overlay(
                        WaveShape(frequency: 1.6, amplitude: 30, phase: waveOffset3)
                            .stroke(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color.white.opacity(0.3),
                                        Color.white.opacity(0.12)
                                    ]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                ),
                                lineWidth: 0.6
                            )
                    )
                    .offset(y: 300)
            }
            
            // Main content
            VStack(spacing: 20) {
                // App icon with liquid glass effect
                ZStack {
                    Circle()
                        .fill(.ultraThinMaterial)
                        .overlay(
                            Circle()
                                .stroke(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            Color.white.opacity(0.4),
                                            Color.white.opacity(0.2)
                                        ]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 2
                                )
                        )
                        .frame(width: 120, height: 120)
                        .shadow(color: Color.black.opacity(0.1), radius: 20, x: 0, y: 10)
                    
                    Image(systemName: "heart.fill")
                        .font(.system(size: 50))
                        .foregroundColor(Color.themeButton)
                }
                
                // Title
                VStack(spacing: 8) {
                    Text("Quick Help")
                        .font(.sfProRoundedHeavy(size: 42))
                        .foregroundColor(.primary)
                    
                    Text("your peace of mind")
                        .font(.sfProRoundedSemibold(size: 18))
                        .foregroundColor(.secondary)
                        .tracking(2)
                }
                .opacity(textOpacity)
                .scaleEffect(textScale)
            }
        }
        .onAppear {
            startAnimations()
        }
    }
    
    private func startAnimations() {
        // Start wave animations
        withAnimation(.linear(duration: 8).repeatForever(autoreverses: false)) {
            waveOffset1 = .pi * 2
        }
        
        withAnimation(.linear(duration: 6).repeatForever(autoreverses: false)) {
            waveOffset2 = .pi * 2
        }
        
        withAnimation(.linear(duration: 4).repeatForever(autoreverses: false)) {
            waveOffset3 = .pi * 2
        }
        
        // Start text animations
        withAnimation(.easeOut(duration: 1.2).delay(0.3)) {
            textOpacity = 1
            textScale = 1.0
        }
    }
}

// Custom wave shape
struct WaveShape: Shape {
    let frequency: Double
    let amplitude: Double
    let phase: Double
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height
        let midHeight = height / 2
        
        path.move(to: CGPoint(x: 0, y: midHeight))
        
        for x in stride(from: 0, through: width, by: 1) {
            let relativeX = x / width
            let sine = sin(relativeX * frequency * .pi * 2 + phase)
            let y = midHeight + sine * amplitude
            path.addLine(to: CGPoint(x: x, y: y))
        }
        
        path.addLine(to: CGPoint(x: width, y: height))
        path.addLine(to: CGPoint(x: 0, y: height))
        path.closeSubpath()
        
        return path
    }
}

#Preview {
    LaunchScreenView()
} 