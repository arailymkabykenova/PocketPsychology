# Frontend API Guide

Простое руководство по использованию API для iOS приложения.

## 🎯 Основные Endpoints

### 1. Ежедневная цитата
```http
GET /content/daily-quote
```

**Ответ:**
```json
{
    "text": "Будь изменением, которое ты хочешь видеть в мире",
    "author": "Махатма Ганди",
    "topic": "мотивация",
    "date": "2024-01-15"
}
```

### 2. Статьи
```http
GET /content/articles?limit=10
```

**Ответ:**
```json
{
    "articles": [
        {
            "title": "Как справиться со стрессом",
            "content": "Содержание статьи...",
            "source_topics": ["стресс", "медитация"],
            "created_at": "2024-01-15T10:30:00"
        }
    ]
}
```

### 3. Видео с YouTube
```http
GET /content/videos?limit=10&topic=мотивация
```

**Ответ:**
```json
{
    "videos": [
        {
            "title": "Мотивационное видео",
            "description": "Описание видео",
            "video_id": "dQw4w9WgXcQ",
            "thumbnail": "https://img.youtube.com/vi/dQw4w9WgXcQ/maxresdefault.jpg",
            "duration": "PT10M30S",
            "formatted_duration": "10:30",
            "channel": "Channel Name",
            "published_at": "2024-01-01T00:00:00Z"
        }
    ]
}
```

### 4. Генерация контента
```http
POST /content/generate?content_type=quote&topic=уверенность
POST /content/generate?content_type=article
```

**Ответ для цитаты:**
```json
{
    "message": "Quote generated successfully",
    "content": {
        "text": "Верь в себя, и ты будешь непобедим",
        "author": "Неизвестный",
        "topic": "уверенность",
        "date": "2024-01-15",
        "is_generated": true
    }
}
```

**Ответ для статьи:**
```json
{
    "message": "Generated 2 articles",
    "content": [
        {
            "title": "Заголовок статьи",
            "content": "Содержание статьи...",
            "topic": "мотивация"
        }
    ]
}
```

## 📱 Примеры использования в Swift

### Получение ежедневной цитаты
```swift
func getDailyQuote() async -> Quote? {
    guard let url = URL(string: "\(baseURL)/content/daily-quote") else { return nil }
    
    do {
        let (data, _) = try await URLSession.shared.data(from: url)
        let quote = try JSONDecoder().decode(Quote.self, from: data)
        return quote
    } catch {
        print("Error: \(error)")
        return nil
    }
}
```

### Получение статей
```swift
func getArticles(limit: Int = 10) async -> [Article] {
    guard let url = URL(string: "\(baseURL)/content/articles?limit=\(limit)") else { return [] }
    
    do {
        let (data, _) = try await URLSession.shared.data(from: url)
        let response = try JSONDecoder().decode(ArticlesResponse.self, from: data)
        return response.articles
    } catch {
        print("Error: \(error)")
        return []
    }
}
```

### Получение видео
```swift
func getVideos(topic: String? = nil, limit: Int = 10) async -> [Video] {
    var urlString = "\(baseURL)/content/videos?limit=\(limit)"
    if let topic = topic {
        urlString += "&topic=\(topic.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? topic)"
    }
    
    guard let url = URL(string: urlString) else { return [] }
    
    do {
        let (data, _) = try await URLSession.shared.data(from: url)
        let response = try JSONDecoder().decode(VideosResponse.self, from: data)
        return response.videos
    } catch {
        print("Error: \(error)")
        return []
    }
}
```

### Генерация цитаты
```swift
func generateQuote(topic: String? = nil) async -> Quote? {
    var urlString = "\(baseURL)/content/generate?content_type=quote"
    if let topic = topic {
        urlString += "&topic=\(topic.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? topic)"
    }
    
    guard let url = URL(string: urlString) else { return nil }
    
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    
    do {
        let (data, _) = try await URLSession.shared.data(for: request)
        let response = try JSONDecoder().decode(GenerateResponse.self, from: data)
        return response.content as? Quote
    } catch {
        print("Error: \(error)")
        return nil
    }
}
```

## 🎨 Модели данных

### Quote
```swift
struct Quote: Codable {
    let text: String
    let author: String
    let topic: String
    let date: String
    let isGenerated: Bool?
    
    enum CodingKeys: String, CodingKey {
        case text, author, topic, date
        case isGenerated = "is_generated"
    }
}
```

### Article
```swift
struct Article: Codable {
    let title: String
    let content: String
    let sourceTopics: [String]
    let createdAt: String
    
    enum CodingKeys: String, CodingKey {
        case title, content
        case sourceTopics = "source_topics"
        case createdAt = "created_at"
    }
}
```

### Video
```swift
struct Video: Codable {
    let title: String
    let description: String
    let videoId: String
    let thumbnail: String
    let duration: String
    let formattedDuration: String
    let channel: String
    let publishedAt: String
    
    enum CodingKeys: String, CodingKey {
        case title, description, thumbnail, duration, channel
        case videoId = "video_id"
        case formattedDuration = "formatted_duration"
        case publishedAt = "published_at"
    }
}
```

### Response Models
```swift
struct ArticlesResponse: Codable {
    let articles: [Article]
}

struct VideosResponse: Codable {
    let videos: [Video]
}

struct GenerateResponse: Codable {
    let message: String
    let content: AnyCodable // Can be Quote or [Article]
}

struct AnyCodable: Codable {
    let value: Any
    
    init(_ value: Any) {
        self.value = value
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        if let string = try? container.decode(String.self) {
            value = string
        } else if let int = try? container.decode(Int.self) {
            value = int
        } else if let double = try? container.decode(Double.self) {
            value = double
        } else if let bool = try? container.decode(Bool.self) {
            value = bool
        } else if let array = try? container.decode([AnyCodable].self) {
            value = array.map { $0.value }
        } else if let dictionary = try? container.decode([String: AnyCodable].self) {
            value = dictionary.mapValues { $0.value }
        } else {
            value = NSNull()
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        
        switch value {
        case let string as String:
            try container.encode(string)
        case let int as Int:
            try container.encode(int)
        case let double as Double:
            try container.encode(double)
        case let bool as Bool:
            try container.encode(bool)
        case let array as [Any]:
            try container.encode(array.map { AnyCodable($0) })
        case let dictionary as [String: Any]:
            try container.encode(dictionary.mapValues { AnyCodable($0) })
        default:
            try container.encodeNil()
        }
    }
}
```

## 🚀 Рекомендации по использованию

### 1. Кэширование
- Сохраняйте ежедневную цитату локально
- Кэшируйте статьи и видео
- Обновляйте контент при запуске приложения

### 2. Обработка ошибок
- Всегда проверяйте статус ответа
- Используйте try-catch для обработки ошибок
- Показывайте пользователю понятные сообщения об ошибках

### 3. Загрузка контента
- Используйте индикаторы загрузки
- Загружайте контент асинхронно
- Предоставляйте fallback контент при ошибках

### 4. Видео
- Используйте `video_id` для воспроизведения через YouTube
- Показывайте `formatted_duration` для длительности
- Используйте `thumbnail` для превью

## 🔧 Настройка

### Base URL
```swift
let baseURL = "http://localhost:8000" // Для разработки
let baseURL = "https://your-server.com" // Для продакшена
```

### Headers
```swift
var request = URLRequest(url: url)
request.setValue("application/json", forHTTPHeaderField: "Content-Type")
```

### Timeout
```swift
let config = URLSessionConfiguration.default
config.timeoutIntervalForRequest = 30
config.timeoutIntervalForResource = 60
let session = URLSession(configuration: config)
``` 