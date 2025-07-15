# База данных и генерация контента

## 🗄️ **Новая система хранения данных**

### **SQLite база данных**
- **Файл**: `chatbot.db` (создается автоматически)
- **Преимущества**: Легкая, не требует сервера, один файл
- **Поддержка**: Встроена в Python

### **Структура базы данных**

#### **1. Таблица conversations**
```sql
CREATE TABLE conversations (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id TEXT NOT NULL,
    mode TEXT NOT NULL,
    role TEXT NOT NULL,
    content TEXT NOT NULL,
    timestamp DATETIME DEFAULT CURRENT_TIMESTAMP
);
```

#### **2. Таблица topics**
```sql
CREATE TABLE topics (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    topic TEXT NOT NULL,
    frequency INTEGER DEFAULT 1,
    last_mentioned DATETIME DEFAULT CURRENT_TIMESTAMP,
    mode TEXT NOT NULL
);
```

#### **3. Таблица generated_content**
```sql
CREATE TABLE generated_content (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    content_type TEXT NOT NULL,
    title TEXT NOT NULL,
    content TEXT NOT NULL,
    source_topics TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    is_active BOOLEAN DEFAULT 1
);
```

#### **4. Таблица user_sessions**
```sql
CREATE TABLE user_sessions (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id TEXT UNIQUE NOT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    last_activity DATETIME DEFAULT CURRENT_TIMESTAMP
);
```

## 🤖 **Генерация контента на основе чатов**

### **Как это работает:**

1. **Анализ чатов** → Извлечение популярных тем
2. **Генерация статей** → AI создает статьи на основе тем
3. **Генерация видео** → AI создает сценарии для видео
4. **Персонализация** → Контент адаптируется под пользователя

### **Процесс генерации:**

```python
# 1. Извлечение тем из сообщений
topics = ["стресс", "тревога", "медитация", "сон"]

# 2. Генерация контента
article = ai_service.generate_article("стресс")
video_script = ai_service.generate_video_script("медитация")

# 3. Сохранение в базу
db.save_generated_content("article", title, content, topics)
```

## 📊 **Новые API эндпоинты**

### **Контент**
- `GET /content/daily-quote` - Цитата дня
- `GET /content/articles` - Список статей
- `GET /content/videos` - Список видео
- `GET /content/personalized/{user_id}` - Персонализированный контент
- `POST /content/generate` - Генерация нового контента

### **Статистика**
- `GET /stats/topics` - Популярные темы

## 🚀 **Использование**

### **1. Запуск сервера**
```bash
cd back
python run.py
```

### **2. Генерация контента**
```bash
# Ручная генерация
python generate_content.py

# Автоматическая генерация (cron)
0 2 * * * cd /path/to/chatbot/back && python generate_content.py
```

### **3. Тестирование API**
```bash
# Получить цитату дня
curl http://localhost:8000/content/daily-quote

# Получить статьи
curl http://localhost:8000/content/articles

# Сгенерировать новый контент
curl -X POST "http://localhost:8000/content/generate?content_type=article"
```

## 📈 **Преимущества новой системы**

### **✅ Постоянное хранение**
- Данные сохраняются между перезапусками
- Резервное копирование - просто скопировать файл БД

### **✅ Аналитика**
- Отслеживание популярных тем
- Статистика по пользователям
- История активности

### **✅ Персонализация**
- Контент на основе предпочтений пользователя
- Рекомендации по режимам общения

### **✅ Автоматическая генерация**
- Статьи создаются на основе популярных тем
- Видео-сценарии генерируются автоматически
- Цитаты дня обновляются ежедневно

### **✅ Масштабируемость**
- Легко перейти на PostgreSQL/MySQL
- Поддержка множественных пользователей
- Индексирование для быстрого поиска

## 🔧 **Настройка**

### **Переменные окружения**
```bash
# Существующие
AZURE_OPENAI_ENDPOINT=your_endpoint
AZURE_OPENAI_API_KEY=your_key
AZURE_OPENAI_DEPLOYMENT_NAME=your_deployment

# Новые (опционально)
DATABASE_PATH=chatbot.db  # Путь к файлу БД
CONTENT_GENERATION_INTERVAL=24  # Часы между генерациями
```

### **Планировщик задач (cron)**
```bash
# Генерация контента каждый день в 2:00
0 2 * * * cd /path/to/chatbot/back && python generate_content.py

# Очистка логов каждую неделю
0 3 * * 0 find /path/to/chatbot/back -name "*.log" -mtime +7 -delete
```

## 📝 **Логирование**

- **Файл**: `content_generation.log`
- **Уровень**: INFO
- **Формат**: Время, уровень, сообщение
- **Ротация**: Ручная или через cron

## 🔄 **Миграция с старой системы**

Старая система (в памяти) остается для обратной совместимости:
- Новые сообщения сохраняются в БД
- Старые методы продолжают работать
- Постепенный переход без потери данных 