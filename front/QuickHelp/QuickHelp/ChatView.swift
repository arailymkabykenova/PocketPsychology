import SwiftUI

struct ChatView: View {
    @StateObject private var chatService = ChatService()
    @State private var messages: [ChatMessage] = []
    @State private var inputText = ""
    @State private var selectedMode: ChatMode = .support
    @State private var showingModeSelector = false
    @State private var showingError = false
    @State private var showingClearHistoryAlert = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
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
                    .padding(.top, 8)
                }
                
                // Messages list
                ScrollView {
                    LazyVStack(spacing: 16) {
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
                    .padding(.vertical, 8)
                }
                .onChange(of: messages.count) { _ in
                    // Auto-scroll will be handled by the view itself
                }
                .onChange(of: chatService.isLoading) { isLoading in
                    // Auto-scroll will be handled by the view itself
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
                            Text(selectedMode.displayName)
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
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                
                // Message input
                MessageInputView(
                    text: $inputText,
                    isLoading: chatService.isLoading,
                    onSend: sendMessage
                )
            }
            .navigationTitle("QuickHelp")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        showingClearHistoryAlert = true
                    }) {
                        Image(systemName: "trash")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.red)
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                            showingModeSelector.toggle()
                        }
                    }) {
                        Image(systemName: "slider.horizontal.3")
                            .font(.system(size: 18, weight: .medium))
                    }
                }
            }
            .sheet(isPresented: $showingModeSelector) {
                ModeSelectorView(selectedMode: $selectedMode)
                    .presentationDetents([.medium])
                    .presentationDragIndicator(.visible)
            }
            .alert("Ошибка", isPresented: $showingError) {
                Button("OK") { }
            } message: {
                Text(chatService.errorMessage ?? "Неизвестная ошибка")
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
            .alert("Очистить историю", isPresented: $showingClearHistoryAlert) {
                Button("Отмена", role: .cancel) { }
                Button("Очистить", role: .destructive) {
                    clearHistory()
                }
            } message: {
                Text("Вы уверены, что хотите очистить всю историю чата? Это действие нельзя отменить.")
            }
        }
    }
    
    private var welcomeMessage: some View {
        VStack(spacing: 16) {
            Image(systemName: "message.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(.blue.opacity(0.6))
            
            VStack(spacing: 8) {
                Text("Добро пожаловать в QuickHelp!")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .multilineTextAlignment(.center)
                
                Text("Выберите режим общения и начните диалог. Я здесь, чтобы помочь вам.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
        }
        .padding(.vertical, 40)
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
    

}

