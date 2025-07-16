# Исправление проблемы с клавиатурой

## 🎯 Проблема
Клавиатура поднимается для чата, но после отправки сообщения не опускается, и пользователь не может ее скрыть.

## ✅ Решение

### **1. Добавлен FocusState в MessageInputView**
```swift
@FocusState private var isTextFieldFocused: Bool
```

### **2. Управление фокусом при отправке**
```swift
.onSubmit {
    if canSend {
        onSend()
        isTextFieldFocused = false  // Скрыть клавиатуру
    } else {
        isTextFieldFocused = false  // Скрыть клавиатуру даже если не можем отправить
    }
}
```

### **3. Кнопка "Готово" на клавиатуре**
```swift
.submitLabel(.done)
```

### **4. Tap gesture для скрытия клавиатуры**
```swift
.onTapGesture {
    KeyboardManager.dismissKeyboard()
}
```

### **5. Утилиты для управления клавиатурой**
Создан файл `KeyboardManager.swift` с полезными функциями:
- `KeyboardManager.dismissKeyboard()` - программно скрыть клавиатуру
- `dismissKeyboardOnTap()` - скрыть при тапе вне поля ввода
- `hideKeyboardOnDisappear()` - скрыть при исчезновении view

## 🔧 Что было исправлено

### **MessageInputView.swift:**
- ✅ Добавлен `@FocusState`
- ✅ Клавиатура скрывается после отправки сообщения
- ✅ Клавиатура скрывается при нажатии "Готово"
- ✅ Tap gesture для скрытия клавиатуры

### **ChatView.swift:**
- ✅ Tap gesture на ScrollView для скрытия клавиатуры
- ✅ Использование `KeyboardManager` для чистого кода

### **KeyboardManager.swift:**
- ✅ Утилиты для управления клавиатурой
- ✅ Extension для удобного использования
- ✅ Observer для отслеживания высоты клавиатуры

## 🚀 Результат

Теперь клавиатура:
- ✅ Скрывается после отправки сообщения
- ✅ Скрывается при нажатии "Готово"
- ✅ Скрывается при тапе вне поля ввода
- ✅ Скрывается при тапе на область сообщений
- ✅ Работает корректно на всех устройствах

## 💡 Дополнительные возможности

Если нужно добавить анимацию при появлении/скрытии клавиатуры:

```swift
@StateObject private var keyboardObserver = KeyboardHeightObserver()

// В view:
.animation(.easeInOut(duration: 0.3), value: keyboardObserver.keyboardHeight)
```

Это обеспечит плавную анимацию интерфейса при появлении и скрытии клавиатуры. 