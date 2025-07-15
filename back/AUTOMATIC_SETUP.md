# 🤖 Автоматическая настройка Chatbot System

## 🎯 Цель системы

Система полностью автоматизирована и работает следующим образом:

### Для новых пользователей:
1. **При первом входе** - показываем:
   - Цитату дня
   - Рандомные статьи на психологические темы
   - Рандомные видео с YouTube на психологические темы

2. **Во время беседы** - автоматически:
   - Извлекаем тему из сообщения пользователя
   - Генерируем персонализированные статьи и цитаты
   - Подбираем релевантные видео с YouTube
   - Обновляем рекомендации в реальном времени

## 🚀 Быстрый запуск

### 1. Убедитесь, что Redis запущен:
```bash
# macOS
brew services start redis

# Linux
sudo systemctl start redis

# Проверка
redis-cli ping
```

### 2. Запустите всю систему одной командой:
```bash
python start_system.py
```

Этот скрипт автоматически запустит:
- ✅ Celery Worker (фоновые задачи)
- ✅ Celery Beat (планировщик задач)
- ✅ Flower (мониторинг задач)
- ✅ FastAPI Server (основной API)

## 📋 Что происходит автоматически

### При запуске системы:
- **Через 1 минуту**: Генерация начального контента (цитаты, статьи)
- **Каждые 15 минут**: Обновление популярных тем
- **Каждые 30 минут**: Генерация ежедневного контента
- **Каждый час**: Генерация контента для всех активных тем

### При каждом сообщении пользователя:
- Извлечение темы из сообщения
- Автоматическая генерация статей и цитат для этой темы
- Обновление персонализированных рекомендаций
- Поиск релевантных видео на YouTube

## 🌐 Доступные endpoints

### Для фронтенда:
- `GET /content/initial` - Начальный контент для новых пользователей
- `POST /chat` - Основной чат с автоматическим извлечением тем
- `GET /user/{user_id}/recommendations` - Персонализированные рекомендации

### Мониторинг:
- `http://localhost:8000/docs` - API документация
- `http://localhost:5555` - Flower (мониторинг Celery задач)

## 🔧 Настройка расписания

Расписание автоматических задач в `celery_app.py`:

```python
celery_app.conf.beat_schedule = {
    "initialize-startup-content": {
        "task": "tasks.initialize_startup_content",
        "schedule": 60.0,  # Через 1 минуту после запуска
    },
    "generate-daily-content": {
        "task": "tasks.generate_daily_content",
        "schedule": 1800.0,  # Каждые 30 минут
    },
    "generate-content-for-all-topics": {
        "task": "tasks.generate_content_for_all_topics",
        "schedule": 3600.0,  # Каждый час
    },
    "update-popular-topics": {
        "task": "tasks.update_popular_topics",
        "schedule": 900.0,  # Каждые 15 минут
    },
    "cleanup-old-content": {
        "task": "tasks.cleanup_old_content",
        "schedule": 86400.0,  # Каждый день
    },
}
```

## 📱 Интеграция с фронтендом

### 1. При первом входе пользователя:
```swift
// Получить начальный контент
let initialContent = await apiClient.getInitialContent()
// Показать: цитата дня + рандомные статьи + рандомные видео
```

### 2. При отправке сообщения:
```swift
// Отправить сообщение в чат
let response = await apiClient.sendMessage(message, mode: mode, userId: userId)
// response содержит topic_task_id и recommendations_task_id
```

### 3. Получить персонализированные рекомендации:
```swift
// Получить рекомендации для пользователя
let recommendations = await apiClient.getUserRecommendations(userId: userId)
// Содержит: статьи, цитаты, видео по теме пользователя
```

## 🎯 Результат

Система полностью автоматизирована:
- ✅ Нет необходимости в ручном запуске генерации контента
- ✅ Контент генерируется автоматически на основе тем пользователей
- ✅ Рекомендации обновляются в реальном времени
- ✅ Система масштабируется автоматически
- ✅ Все процессы мониторятся через Flower

## 🛠️ Устранение неполадок

### Если контент не генерируется:
1. Проверьте логи Celery Worker: `celery -A celery_app worker --loglevel=info`
2. Проверьте логи Celery Beat: `celery -A celery_app beat --loglevel=info`
3. Проверьте мониторинг: `http://localhost:5555`

### Если Redis недоступен:
```bash
# Перезапустите Redis
brew services restart redis  # macOS
sudo systemctl restart redis  # Linux
```

### Если API ключи не работают:
1. Проверьте файл `.env`
2. Убедитесь, что все переменные окружения установлены
3. Перезапустите систему: `python start_system.py` 