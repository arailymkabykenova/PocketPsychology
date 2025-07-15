# Redis и Celery Setup Guide

## Обзор

Этот проект использует Redis для кэширования и Celery для асинхронных задач. Это позволяет:

- **Кэшировать** контент (цитаты, статьи, видео) для быстрого доступа
- **Асинхронно** извлекать темы из сообщений пользователей
- **Автоматически** генерировать контент в фоновом режиме
- **Планировать** регулярные задачи (ежедневные цитаты, обновление тем)

## Установка Redis

### macOS (с Homebrew)
```bash
brew install redis
brew services start redis
```

### Ubuntu/Debian
```bash
sudo apt update
sudo apt install redis-server
sudo systemctl start redis-server
sudo systemctl enable redis-server
```

### Windows
1. Скачайте Redis для Windows с https://github.com/microsoftarchive/redis/releases
2. Установите и запустите Redis сервер

### Docker
```bash
docker run -d -p 6379:6379 --name redis redis:alpine
```

## Установка зависимостей

```bash
pip install -r requirements.txt
```

## Настройка переменных окружения

Создайте файл `.env` на основе `env.example`:

```bash
cp env.example .env
```

Добавьте в `.env`:
```env
REDIS_URL=redis://localhost:6379/0
```

## Запуск системы

### 1. Запуск Redis
```bash
# Если Redis не запущен как сервис
redis-server
```

### 2. Запуск Celery Worker
```bash
# В отдельном терминале
python start_celery.py
```

### 3. Запуск Celery Beat (планировщик)
```bash
# В отдельном терминале
python start_celery_beat.py
```

### 4. Запуск FastAPI сервера
```bash
# В отдельном терминале
python main.py
```

## Мониторинг с Flower

Flower - это веб-интерфейс для мониторинга Celery задач.

### Запуск Flower
```bash
celery -A celery_app flower --port=5555
```

Откройте http://localhost:5555 для просмотра:
- Активных задач
- Статистики выполнения
- Логов ошибок

## Архитектура задач

### Основные задачи Celery:

1. **extract_topic_from_message** - извлекает тему из сообщения пользователя
2. **generate_content_for_topic** - генерирует контент для конкретной темы
3. **update_user_recommendations** - обновляет персональные рекомендации
4. **generate_daily_content** - генерирует ежедневный контент
5. **update_popular_topics** - обновляет популярные темы
6. **cleanup_old_content** - очищает старый кэш

### Планировщик задач:

- **Каждый час**: генерация ежедневного контента
- **Каждые 30 минут**: обновление популярных тем
- **Каждый день**: очистка старого контента

## Кэширование в Redis

### Ключи кэша:

- `user_topic:{user_id}` - текущая тема пользователя (1 час)
- `recommendations:{user_id}` - рекомендации пользователя (30 минут)
- `article:{topic}:{date}` - статьи по теме (24 часа)
- `quote:{topic}:{date}` - цитаты по теме (24 часа)
- `daily_content:{date}` - ежедневный контент (24 часа)

## API Endpoints

### Новые эндпоинты:

- `GET /task/{task_id}/status` - статус задачи Celery
- `GET /user/{user_id}/topic` - текущая тема пользователя
- `GET /user/{user_id}/recommendations` - рекомендации пользователя

### Обновленные эндпоинты:

- `POST /chat` - теперь возвращает тему и ID задач
- `GET /content/articles` - поддерживает фильтрацию по теме
- `GET /content/videos` - поддерживает поиск по теме

## Автоматизация

### После каждого сообщения в чате:

1. AI генерирует ответ
2. Celery извлекает тему из сообщения
3. Celery обновляет рекомендации пользователя
4. Frontend получает тему и может загрузить релевантный контент

### Пример использования:

```python
# Отправка сообщения
response = await chat_service.send_message("Я чувствую стресс на работе")

# Получение темы
topic = response.get("topic")  # "стресс"

# Загрузка видео по теме
videos = await content_service.fetchVideos(topic=topic)
```

## Troubleshooting

### Redis не подключается:
```bash
# Проверьте статус Redis
redis-cli ping
# Должен ответить PONG
```

### Celery задачи не выполняются:
```bash
# Проверьте логи worker'а
python start_celery.py --loglevel=debug

# Проверьте статус задач через Flower
```

### Проблемы с импортом:
```bash
# Убедитесь, что все файлы в PYTHONPATH
export PYTHONPATH="${PYTHONPATH}:$(pwd)"
```

## Production Deployment

### Docker Compose (рекомендуется):

```yaml
version: '3.8'
services:
  redis:
    image: redis:alpine
    ports:
      - "6379:6379"
  
  web:
    build: .
    ports:
      - "8000:8000"
    depends_on:
      - redis
    environment:
      - REDIS_URL=redis://redis:6379/0
  
  worker:
    build: .
    command: python start_celery.py
    depends_on:
      - redis
    environment:
      - REDIS_URL=redis://redis:6379/0
  
  beat:
    build: .
    command: python start_celery_beat.py
    depends_on:
      - redis
    environment:
      - REDIS_URL=redis://redis:6379/0
  
  flower:
    build: .
    command: celery -A celery_app flower --port=5555
    ports:
      - "5555:5555"
    depends_on:
      - redis
    environment:
      - REDIS_URL=redis://redis:6379/0
```

### Системные требования:

- **Redis**: 512MB RAM
- **Celery Worker**: 1 CPU, 1GB RAM на процесс
- **Celery Beat**: 256MB RAM
- **FastAPI**: 1 CPU, 512MB RAM 