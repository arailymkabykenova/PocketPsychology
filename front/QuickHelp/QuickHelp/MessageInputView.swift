import SwiftUI

struct MessageInputView: View {
    @Binding var text: String
    let isLoading: Bool
    let onSend: () -> Void
    @ObservedObject private var localizationManager = LocalizationManager.shared
    
    @State private var isExpanded = false
    @FocusState private var isTextFieldFocused: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            Divider()
            
            HStack(spacing: 12) {
                // Text input
                TextField(localizationManager.localizedString(.enterMessage), text: $text, axis: .vertical)
                    .textFieldStyle(PlainTextFieldStyle())
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color(.systemGray6))
                    )
                    .lineLimit(1...4)
                    .disabled(isLoading)
                    .focused($isTextFieldFocused)
                    .submitLabel(.done)
                    .onChange(of: text) { newValue in
                        withAnimation(.easeInOut(duration: 0.2)) {
                            isExpanded = newValue.count > 0
                        }
                    }
                    .onSubmit {
                        if canSend {
                            onSend()
                            // Hide keyboard after sending
                            isTextFieldFocused = false
                        } else {
                            // If can't send, just hide keyboard
                            isTextFieldFocused = false
                        }
                    }
                
                // Send button
                Button(action: {
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                        onSend()
                        // Hide keyboard after sending
                        isTextFieldFocused = false
                    }
                }) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 32))
                        .foregroundColor(canSend ? .blue : .gray)
                        .scaleEffect(canSend ? 1.0 : 0.8)
                }
                .disabled(!canSend || isLoading)
                .animation(.spring(response: 0.6, dampingFraction: 0.8), value: canSend)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .background(Color(.systemBackground))
        .safeAreaInset(edge: .bottom) {
            Color.clear.frame(height: 0)
        }
        // Add tap gesture to dismiss keyboard when tapping outside
        .onTapGesture {
            KeyboardManager.dismissKeyboard()
        }
    }
    
    private var canSend: Bool {
        !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isLoading
    }
}

#Preview {
    VStack {
        Spacer()
        MessageInputView(
            text: .constant(""),
            isLoading: false,
            onSend: {}
        )
    }
    .background(Color(.systemGray6))
} 