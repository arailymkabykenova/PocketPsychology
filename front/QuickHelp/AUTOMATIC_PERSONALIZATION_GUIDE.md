# Автоматическая персонализация в QuickHelp iOS

## 🎯 Что добавлено

### ✅ **Автоматическое извлечение тем:**
- Извлечение тем из бесед пользователя
- Отображение текущей темы в интерфейсе
- Мониторинг задач генерации контента

### ✅ **Персонализированные рекомендации:**
- API для получения рекомендаций пользователя
- Отдельный экран с персонализированным контентом
- Статьи, цитаты и видео по теме бесед

### ✅ **Улучшенный UX:**
- Индикаторы генерации контента
- Приветственное сообщение для новых пользователей
- Кнопка персонализированных рекомендаций

## 🔄 Как работает автоматическая персонализация

### **1. Извлечение тем из чата:**
```swift
// При отправке сообщения
let request = ChatRequest(message: message, mode: mode, user_id: currentUserId)

// Сервер возвращает task_id для мониторинга
let chatResponse = try JSONDecoder().decode(ChatResponse.self, from: data)
if let topicTaskId = chatResponse.topic_task_id {
    Task {
        await monitorContentGeneration(topicTaskId: topicTaskId)
    }
}
```

### **2. Мониторинг генерации контента:**
```swift
private func monitorContentGeneration(topicTaskId: String) async {
    // Poll task status every 2 seconds for up to 30 seconds
    for _ in 0..<15 {
        let taskStatus = try JSONDecoder().decode(TaskStatus.self, from: data)
        
        if taskStatus.status == "completed" {
            // Update current topic
            self.updateCurrentTopic(topic)
            self.isGeneratingContent = false
        }
    }
}
```

### **3. Получение персонализированных рекомендаций:**
```swift
func fetchUserRecommendations() async -> UserRecommendations? {
    let url = URL(string: "\(baseURL)/user/\(currentUserId)/recommendations")!
    let recommendations = try JSONDecoder().decode(UserRecommendations.self, from: data)
    return recommendations
}
```

## 📱 Новые UI компоненты

### **WelcomeCard:**
- Приветственное сообщение для новых пользователей
- Загружается из `/content/initial` endpoint
- Отображается только при первом запуске

### **CurrentTopicCard:**
- Показывает текущую тему пользователя
- Обновляется автоматически после анализа бесед
- Визуальный индикатор с иконкой лампочки

### **PersonalizedRecommendationsButton:**
- Кнопка для доступа к персонализированному контенту
- Градиентный дизайн с иконкой пользователя
- Индикатор загрузки во время генерации

### **PersonalizedContentView:**
- Полноэкранный режим с рекомендациями
- Разделы для статей, цитат и видео
- Заголовок с темой и временной меткой

## 🔧 Технические улучшения

### **Новые модели данных:**
```swift
struct ChatRequest: Codable {
    let message: String
    let mode: ChatMode
    let user_id: String  // Добавлен user_id
}

struct ChatResponse: Codable {
    let response: String
    let mode: ChatMode
    let topic: String?           // Извлеченная тема
    let topic_task_id: String?   // ID задачи извлечения
    let recommendations_task_id: String? // ID задачи рекомендаций
}

struct UserRecommendations: Codable {
    let topic: String?
    let articles: [Article]?
    let quotes: [Quote]?
    let videos: [Video]?
    let timestamp: String?
}

struct InitialContent: Codable {
    let daily_quote: Quote?
    let random_articles: [Article]
    let random_videos: [Video]
    let welcome_message: String
}
```

### **Управление пользователями:**
```swift
class ChatService: ObservableObject {
    @Published var currentUserId: String
    @Published var currentTopic: String?
    @Published var isGeneratingContent = false
    
    // Генерация уникального ID пользователя
    init() {
        if let savedUserId = userDefaults.string(forKey: userIdKey) {
            self.currentUserId = savedUserId
        } else {
            self.currentUserId = UUID().uuidString
            userDefaults.set(self.currentUserId, forKey: userIdKey)
        }
    }
}
```

### **Кэширование данных:**
```swift
// Кэширование начального контента
private func cacheInitialContent(_ content: InitialContent) {
    let data = try JSONEncoder().encode(content)
    userDefaults.set(data, forKey: initialContentKey)
}

// Кэширование темы пользователя
func updateCurrentTopic(_ topic: String?) {
    self.currentTopic = topic
    userDefaults.set(topic, forKey: currentTopicKey)
}
```

## 🎨 Пользовательский опыт

### **Автоматическое поведение:**
1. **Новый пользователь:** Видит приветственное сообщение и общий контент
2. **Первое сообщение:** Запускается извлечение темы и генерация контента
3. **Последующие сообщения:** Тема обновляется, рекомендации персонализируются
4. **Доступ к рекомендациям:** Кнопка появляется после извлечения первой темы

### **Индикаторы состояния:**
- **"Анализ..."** - во время извлечения темы
- **Тема в чате** - показывает текущую тему
- **Прогресс-бар** - во время генерации контента
- **Уведомления** - о готовности рекомендаций

### **Персонализированный контент:**
- **Статьи:** По теме бесед с превью и временем чтения
- **Цитаты:** Мотивирующие цитаты по теме
- **Видео:** YouTube видео с превью и длительностью
- **Временная метка:** Когда были обновлены рекомендации

## 📊 API Endpoints

### **Новые endpoints:**
```swift
// Начальный контент для новых пользователей
GET /content/initial

// Персонализированные рекомендации
GET /user/{user_id}/recommendations

// Текущая тема пользователя
GET /user/{user_id}/topic

// Статус задачи
GET /task/{task_id}/status
```

### **Обновленные endpoints:**
```swift
// Чат с поддержкой user_id и извлечением тем
POST /chat
{
    "message": "string",
    "mode": "support|analysis|practice",
    "user_id": "string"
}
```

## 🚀 Результат

### **До улучшений:**
- ❌ Нет персонализации
- ❌ Статический контент
- ❌ Нет связи между чатом и рекомендациями
- ❌ Нет извлечения тем

### **После улучшений:**
- ✅ Автоматическое извлечение тем из бесед
- ✅ Персонализированные рекомендации
- ✅ Индикаторы генерации контента
- ✅ Приветственное сообщение для новых пользователей
- ✅ Отдельный экран с персонализированным контентом
- ✅ Кэширование данных пользователя
- ✅ Мониторинг задач в реальном времени

## 🔄 Интеграция с бэкендом

### **Полная автоматизация:**
1. Пользователь отправляет сообщение
2. Бэкенд извлекает тему и запускает генерацию контента
3. Фронтенд мониторит статус задач
4. Контент автоматически обновляется
5. Рекомендации становятся доступными

### **Офлайн поддержка:**
- Кэширование начального контента
- Сохранение темы пользователя
- Fallback контент при ошибках
- Graceful degradation

### **Производительность:**
- Асинхронная генерация контента
- Кэширование для быстрой загрузки
- Polling с таймаутом для мониторинга
- Оптимизированные запросы к API 