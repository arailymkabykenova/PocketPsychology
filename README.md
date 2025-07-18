# 🤖 AI Chatbot - Психологическая поддержка

Интеллектуальный чат-бот для психологической поддержки с тремя режимами общения и автоматической генерацией контента.

## 🚀 **Новые возможности (v2.0)**

### ✨ **Умная генерация контента**
- **Стабильная генерация**: Контент генерируется только при смене темы
- **Кэширование**: Похожие контексты используют существующий контент
- **Семантический анализ**: AI определяет схожесть тем для оптимизации

### 🎨 **Улучшенный UI/UX**
- **Кастомный TabBar**: Анимированные иконки и текст
- **Автоскролл чата**: Автоматическая прокрутка к новым сообщениям
- **Локализация тем**: Цвета и тексты на русском/английском
- **Современные шрифты**: SF Pro Rounded Heavy/Semibold

### 🔧 **Технические улучшения**
- **Асинхронная обработка**: Быстрые ответы с фоновой генерацией
- **Умное кэширование**: Redis для быстрого доступа к контенту
- **Стабильная работа**: Меньше API вызовов, больше эффективности

## 🏗️ **Архитектура**

### **Backend (FastAPI)**
- **AI Service**: Azure OpenAI интеграция
- **Topic Extraction**: Умное извлечение тем из сообщений
- **Content Generation**: Автоматическая генерация статей и видео
- **Caching**: Redis для кэширования контента
- **Celery**: Асинхронная обработка задач

### **Frontend (Swift iOS)**
- **SwiftUI**: Современный интерфейс
- **Custom TabBar**: Анимированная навигация
- **Localization**: Поддержка русского и английского
- **Theme System**: Темная/светлая темы
- **Chat Interface**: Интуитивный чат с автоскроллом

## 🎯 **Режимы общения**

### 1. **Support Mode** (Эмпатическое слушание)
- Фокус на активном слушании и эмоциональной поддержке
- Ответы: "Я слышу тебя", "Это должно быть очень тяжело"
- **Без советов**: Только поддержка, без решений

### 2. **Analysis Mode** (Сократический диалог)
- Помощь в самоанализе через вопросы
- Ответы: "Что ты чувствовал в тот момент?", "Какие мысли привели к этому чувству?"
- **Подход**: Сократический метод для критического мышления

### 3. **Practice Mode** (КПТ микро-советы)
- Практические техники и конкретные советы
- Ответы: "Давайте попробуем это упражнение...", "Как еще можно посмотреть на эту ситуацию?"
- **Фокус**: Дыхательные техники, когнитивное переосмысление

## 🚀 **Быстрый старт**

### **Backend Setup**
```bash
cd back
python -m venv venv
source venv/bin/activate  # Linux/Mac
# или venv\Scripts\activate  # Windows
pip install -r requirements.txt
```

### **Environment Variables**
```bash
# Azure OpenAI
AZURE_OPENAI_ENDPOINT=your_endpoint
AZURE_OPENAI_API_KEY=your_api_key
AZURE_OPENAI_DEPLOYMENT_NAME=your_deployment

# Redis
REDIS_URL=redis://localhost:6379

# YouTube (опционально)
YOUTUBE_API_KEY=your_youtube_api_key
```

### **Запуск Backend**
```bash
# Запуск Redis
redis-server

# Запуск Celery Worker (в отдельном терминале)
celery -A tasks worker --loglevel=info

# Запуск FastAPI
python main.py
```

### **Frontend Setup**
```bash
cd front/QuickHelp
# Открыть QuickHelp.xcodeproj в Xcode
# Выбрать симулятор iPhone
# Нажать Run (⌘+R)
```

## 🧪 **Тестирование**

### **Backend Tests**
```bash
cd back
python test_backend.py      # API эндпоинты
python test_functions.py    # Функции извлечения тем
```

### **Frontend Tests**
- Открыть проект в Xcode
- Product → Test (⌘+U)

## 📊 **Как работает умная генерация**

### **Раньше (нестабильно)**
- Каждое сообщение → новая тема → новый контент
- Много дублирующегося контента
- Постоянная генерация

### **Теперь (стабильно)**
1. **Похожие контексты** → та же тема → **существующий контент**
2. **Разные контексты** → новая тема → **новый контент**
3. **Кэширование** → **быстрые ответы**

### **Примеры**
- "У меня стресс на работе" → тема "стресс"
- "Работа напряженная" → та же тема "стресс" → **нет новой генерации**
- "Хочу мотивацию" → новая тема "мотивация" → **новая генерация**

## 🔧 **API Endpoints**

### **Chat**
```http
POST /chat
{
  "message": "У меня стресс",
  "mode": "support",
  "user_id": "user123",
  "language": "ru"
}
```

### **Content**
```http
GET /content/articles?limit=10&language=ru
GET /content/daily-quote?language=ru
GET /content/videos?limit=5&language=ru
```

### **User Management**
```http
GET /user/{user_id}/topic
GET /user/{user_id}/recommendations
POST /user/{user_id}/topic/refresh
```

## 🎨 **UI Features**

### **Custom TabBar**
- Анимированные иконки и текст
- SF Pro Rounded шрифты
- Плавные переходы

### **Chat Interface**
- Автоматическая прокрутка
- Поддержка Markdown
- Индикатор печати
- Управление клавиатурой

### **Theme System**
- Темная/светлая темы
- Локализованные названия
- Предварительный просмотр

## 📱 **Скриншоты**

[Здесь будут скриншоты приложения]

## 🤝 **Contributing**

1. Fork репозиторий
2. Создайте feature branch (`git checkout -b feature/amazing-feature`)
3. Commit изменения (`git commit -m 'Add amazing feature'`)
4. Push в branch (`git push origin feature/amazing-feature`)
5. Откройте Pull Request

## 📄 **License**

Этот проект лицензирован под MIT License - см. файл [LICENSE](LICENSE) для деталей.

## 🙏 **Благодарности**

- Azure OpenAI за AI возможности
- SwiftUI за современный UI
- Redis за быстрое кэширование
- FastAPI за быстрый backend

---

**Готово к деплою! 🚀** 