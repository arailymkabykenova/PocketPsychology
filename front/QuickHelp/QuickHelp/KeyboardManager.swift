import SwiftUI
import UIKit

// MARK: - Keyboard Management Utilities
struct KeyboardManager {
    
    /// Dismiss keyboard programmatically
    static func dismissKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

// MARK: - View Extension for Keyboard Management
extension View {
    /// Add tap gesture to dismiss keyboard when tapping outside
    func dismissKeyboardOnTap() -> some View {
        self.onTapGesture {
            KeyboardManager.dismissKeyboard()
        }
    }
    
    /// Hide keyboard when view disappears
    func hideKeyboardOnDisappear() -> some View {
        self.onDisappear {
            KeyboardManager.dismissKeyboard()
        }
    }
}

// MARK: - Keyboard Height Observer (for future use)
class KeyboardHeightObserver: ObservableObject {
    @Published var keyboardHeight: CGFloat = 0
    
    init() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillShow),
            name: UIResponder.keyboardWillShowNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillHide),
            name: UIResponder.keyboardWillHideNotification,
            object: nil
        )
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc private func keyboardWillShow(notification: Notification) {
        if let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
            keyboardHeight = keyboardFrame.height
        }
    }
    
    @objc private func keyboardWillHide(notification: Notification) {
        keyboardHeight = 0
    }
} 