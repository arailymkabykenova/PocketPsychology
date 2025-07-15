# 📊 Хранение данных в Chatbot System

## Обзор системы хранения

Система использует **гибридный подход** к хранению данных для оптимальной производительности и экономии ресурсов.

## 🗄️ База данных SQLite (`chatbot.db`)

### Размер: ~332KB (текущий)

### Таблицы:

#### 1. **conversations** - История чата
```sql
CREATE TABLE conversations (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id TEXT NOT NULL,
    mode TEXT NOT NULL,
    role TEXT NOT NULL,  -- 'user' или 'assistant'
    content TEXT NOT NULL,
    timestamp DATETIME DEFAULT CURRENT_TIMESTAMP
)
```
- **Назначение**: Хранение всех сообщений пользователей и ответов AI
- **Очистка**: Автоматически через 30 дней (настраивается)

#### 2. **topics** - Извлеченные темы
```sql
CREATE TABLE topics (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    topic TEXT NOT NULL,
    frequency INTEGER DEFAULT 1,
    last_mentioned DATETIME DEFAULT CURRENT_TIMESTAMP,
    mode TEXT NOT NULL
)
```
- **Назначение**: Темы, извлеченные из сообщений пользователей
- **Использование**: Для персонализации контента

#### 3. **generated_content** - Сгенерированный контент
```sql
CREATE TABLE generated_content (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    content_type TEXT NOT NULL,  -- 'article', 'quote'
    title TEXT NOT NULL,
    content TEXT NOT NULL,
    source_topics TEXT,  -- JSON массив тем
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    is_active BOOLEAN DEFAULT 1
)
```
- **Назначение**: Статьи и цитаты, сгенерированные AI
- **Очистка**: Старые записи деактивируются

#### 4. **quotes** - Цитаты
```sql
CREATE TABLE quotes (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    text TEXT NOT NULL,
    author TEXT NOT NULL,
    topic TEXT NOT NULL,
    language TEXT DEFAULT 'ru',
    is_generated BOOLEAN DEFAULT 0,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    is_active BOOLEAN DEFAULT 1
)
```
- **Назначение**: Цитаты по умолчанию и сгенерированные
- **Языки**: Поддержка русского и английского

#### 5. **user_sessions** - Сессии пользователей
```sql
CREATE TABLE user_sessions (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id TEXT UNIQUE NOT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    last_activity DATETIME DEFAULT CURRENT_TIMESTAMP
)
```
- **Назначение**: Отслеживание активности пользователей

## 🚀 Redis кэш (в памяти)

### Размер: ~3.5MB (текущий)

### Кэшированные данные:

#### 1. **Темы пользователей** (5 минут)
```
user_topic:{user_id} -> "стресс"
```

#### 2. **Статьи** (24 часа)
```
article:{topic}:{language}:{date} -> JSON статья
```

#### 3. **Цитаты** (24 часа)
```
quote:{topic}:{language}:{date} -> JSON цитата
```

#### 4. **Рекомендации** (1 час)
```
recommendations:{user_id} -> JSON рекомендации
```

#### 5. **Начальный контент** (24 часа)
```
initial_content -> JSON начальный контент
```

## 📱 Локальное хранилище iOS (UserDefaults)

### Данные пользователя:

#### 1. **История чата**
```swift
"chat_history" -> [ChatMessage]
```

#### 2. **Настройки пользователя**
```swift
"user_id" -> String
"current_topic" -> String?
"chat_language" -> String
"mode_history" -> String
```

#### 3. **Кэшированный контент**
```swift
"daily_quote" -> Quote
"last_quote_date" -> String
"initial_content" -> InitialContent
```

## 🔄 Логика хранения данных

### 1. **Новые пользователи**
- **База данных**: Создается запись в `user_sessions`
- **Redis**: Пустой кэш
- **iOS**: Генерируется новый `user_id`

### 2. **Первое сообщение**
- **База данных**: Сохраняется сообщение в `conversations`
- **Redis**: Кэшируется извлеченная тема (5 минут)
- **iOS**: Сохраняется история чата

### 3. **Генерация контента**
- **База данных**: Сохраняется в `generated_content`
- **Redis**: Кэшируется на 24 часа
- **iOS**: Обновляется локальный кэш

### 4. **Смена темы**
- **База данных**: Обновляется `user_sessions.last_activity`
- **Redis**: Очищается старый кэш, создается новый
- **iOS**: Обновляется `current_topic`

## 🧹 Очистка данных

### Автоматическая очистка:

#### 1. **База данных** (ежедневно)
- Удаление старых сообщений (>30 дней)
- Деактивация неактуального контента
- Очистка неактивных сессий

#### 2. **Redis** (автоматически)
- TTL для всех кэшированных данных
- Автоматическое удаление по истечении времени

#### 3. **iOS** (при переустановке)
- Полная очистка при удалении приложения
- Ручная очистка через настройки

## 📈 Мониторинг использования

### Команды для проверки:

```bash
# Размер базы данных
ls -lh chatbot.db

# Использование Redis
redis-cli info memory

# Количество записей в таблицах
sqlite3 chatbot.db "SELECT COUNT(*) FROM conversations;"
sqlite3 chatbot.db "SELECT COUNT(*) FROM topics;"
sqlite3 chatbot.db "SELECT COUNT(*) FROM generated_content;"

# Ключи в Redis
redis-cli keys "*"
```

## 🔒 Безопасность данных

### 1. **Персональные данные**
- **Не хранятся**: Имена, email, телефоны
- **Хранятся**: Анонимные user_id, сообщения, темы

### 2. **Шифрование**
- **База данных**: Не шифруется (локальная)
- **Redis**: Не шифруется (локальная)
- **iOS**: Использует системное шифрование

### 3. **Резервное копирование**
- **База данных**: Ручное копирование файла
- **Redis**: Автоматические снапшоты
- **iOS**: iCloud backup (если включен)

## 💡 Рекомендации по оптимизации

### 1. **Для разработки**
- Используйте `start_simple.py` для экономии ресурсов
- Очищайте кэш Redis: `redis-cli flushall`
- Удаляйте старые логи: `rm *.log`

### 2. **Для продакшена**
- Настройте регулярное резервное копирование
- Мониторьте размер базы данных
- Настройте ротацию логов
- Используйте внешний Redis сервер

### 3. **Для масштабирования**
- Переход на PostgreSQL для больших объемов
- Использование Redis Cluster
- Добавление CDN для статического контента 