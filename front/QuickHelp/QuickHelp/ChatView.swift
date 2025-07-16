import SwiftUI

struct ChatView: View {
    @ObservedObject var chatService: ChatService
    @StateObject private var localizationManager = LocalizationManager.shared
    @State private var messages: [ChatMessage] = []
    @State private var inputText = ""
    @State private var selectedMode: ChatMode = .support
    @State private var selectedLanguage: Language = .russian
    @State private var showingModeSelector = false
    @State private var showingLanguageSelector = false
    @State private var showingError = false
    @State private var showingClearHistoryAlert = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Static header with white background
            VStack(spacing: 0) {
                // Navigation bar
                HStack {
                    Button(action: {
                        showingClearHistoryAlert = true
                    }) {
                        Image(systemName: "trash")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.red)
                    }
                    .frame(width: 44, height: 44)
                    
                    Spacer()
                    
                    Text(localizationManager.localizedString(.chat))
                        .font(.title2)
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                    
                    Spacer()
                    
                    Button(action: {
                        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                            showingLanguageSelector.toggle()
                        }
                    }) {
                        HStack(spacing: 4) {
                            Text(selectedLanguage.flag)
                                .font(.system(size: 16))
                            Image(systemName: "chevron.down")
                                .font(.system(size: 12, weight: .medium))
                        }
                        .foregroundColor(.blue)
                    }
                    .frame(width: 44, height: 44)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                
                // Connection status
                if !chatService.isConnected {
                    ConnectionStatusView(
                        isConnected: chatService.isConnected,
                        onRetry: {
                            Task {
                                await chatService.retryConnection()
                            }
                        }
                    )
                    .padding(.horizontal, 16)
                    .padding(.bottom, 8)
                }
            }
            .background(Color.customCardBackground)
            
            // Messages list
            ScrollView {
                LazyVStack(spacing: 4) {
                    // Welcome message
                    if messages.isEmpty {
                        welcomeMessage
                    }
                    
                    // Chat messages
                    ForEach(messages) { message in
                        MessageBubbleView(message: message)
                            .id(message.id)
                    }
                    
                    // Typing indicator
                    if chatService.isLoading {
                        HStack {
                            TypingIndicatorView()
                            Spacer()
                        }
                        .id("typing")
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
            }
            .onChange(of: messages.count) { _ in
                // Auto-scroll will be handled by the view itself
            }
            .background(Color.customBackground)
            .onChange(of: chatService.isLoading) { isLoading in
                // Auto-scroll will be handled by the view itself
            }
            // Add tap gesture to dismiss keyboard when tapping on scroll view
            .onTapGesture {
                // This will dismiss the keyboard when tapping on the scroll view
                KeyboardManager.dismissKeyboard()
            }
            
            // Mode selector button
            HStack {
                Button(action: {
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                        showingModeSelector.toggle()
                    }
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: selectedMode.icon)
                            .font(.system(size: 16, weight: .medium))
                        Text(selectedMode.displayName(for: selectedLanguage))
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(selectedMode.color)
                    )
                }
                
                Spacer()
                
                // Content generation indicator
                if chatService.isGeneratingContent {
                    contentGenerationIndicator
                }
                
                // Current topic indicator with refresh button
                if let currentTopic = chatService.currentTopic {
                    currentTopicIndicator(topic: currentTopic)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            
            // Message input
            MessageInputView(
                text: $inputText,
                isLoading: chatService.isLoading,
                onSend: sendMessage
            )
            .ignoresSafeArea(.keyboard, edges: .bottom)
        }
        .sheet(isPresented: $showingModeSelector) {
            ModeSelectorView(selectedMode: $selectedMode, selectedLanguage: selectedLanguage)
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showingLanguageSelector) {
            LanguageSelectorView(selectedLanguage: $selectedLanguage)
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
        .alert(localizationManager.localizedString(.error), isPresented: $showingError) {
            Button("OK") { }
        } message: {
            Text(chatService.errorMessage ?? localizationManager.localizedString(.unknownError))
        }
        .onChange(of: chatService.errorMessage) { errorMessage in
            showingError = errorMessage != nil
        }
        .onAppear {
            loadSavedData()
        }
        .onChange(of: messages) { _ in
            chatService.saveChatHistory(messages)
        }
        .onChange(of: selectedMode) { _ in
            chatService.saveSelectedMode(selectedMode)
        }
        .onChange(of: selectedLanguage) { newLanguage in
            localizationManager.setLanguage(newLanguage)
            chatService.updateCurrentLanguage(newLanguage)
        }
        .alert(localizationManager.localizedString(.clearHistoryAlert), isPresented: $showingClearHistoryAlert) {
            Button(localizationManager.localizedString(.cancel), role: .cancel) { }
            Button(localizationManager.localizedString(.clearHistory), role: .destructive) {
                clearHistory()
            }
        } message: {
            Text(localizationManager.localizedString(.clearHistoryMessage))
        }
        .background(Color.customBackground)
    }
    
    private var welcomeMessage: some View {
        VStack(spacing: 16) {
            Image(systemName: "message.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(.blue.opacity(0.6))
            
            VStack(spacing: 8) {
                Text(localizationManager.localizedString(.welcomeTitle))
                    .font(.title2)
                    .fontWeight(.semibold)
                    .multilineTextAlignment(.center)
                
                Text(localizationManager.localizedString(.welcomeSubtitle))
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
        }
        .padding(.top, 20)
        .padding(.bottom, 40)
        .opacity(messages.isEmpty ? 1 : 0)
        .animation(.easeInOut(duration: 0.3), value: messages.isEmpty)
    }
    
    private func sendMessage() {
        let trimmedText = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty else { return }
        
        let userMessage = ChatMessage(
            content: trimmedText,
            isUser: true,
            timestamp: Date(),
            mode: selectedMode
        )
        
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            messages.append(userMessage)
        }
        
        // Clear input text immediately
        inputText = ""
        
        Task {
            if let response = await chatService.sendMessage(trimmedText, mode: selectedMode) {
                let aiMessage = ChatMessage(
                    content: response,
                    isUser: false,
                    timestamp: Date(),
                    mode: selectedMode
                )
                
                await MainActor.run {
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                        messages.append(aiMessage)
                    }
                }
            }
        }
    }
    
    private func loadSavedData() {
        // Load saved messages
        let savedMessages = chatService.loadChatHistory()
        if !savedMessages.isEmpty {
            messages = savedMessages
        }
        
        // Load saved mode
        selectedMode = chatService.loadSelectedMode()
        
        // Load saved language
        selectedLanguage = localizationManager.currentLanguage
    }
    
    private func clearHistory() {
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            messages.removeAll()
        }
        chatService.clearChatHistory()
        
        // Clear server history as well
        Task {
            await chatService.clearServerHistory()
        }
    }
    

    
    // MARK: - Computed Properties
    
    private var contentGenerationIndicator: some View {
        HStack(spacing: 6) {
            ProgressView()
                .scaleEffect(0.6)
                .foregroundColor(.blue)
            
            Text(localizationManager.localizedString(.analyzing))
                .font(.caption)
                .foregroundColor(.blue)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(Color.blue.opacity(0.1))
        )
    }
    
    private func currentTopicIndicator(topic: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: "lightbulb.fill")
                .font(.caption)
                .foregroundColor(.yellow)
            
            Text(topic.capitalized)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.primary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(Color.yellow.opacity(0.1))
        )
    }
}

#Preview {
    ChatView(chatService: ChatService())
}

