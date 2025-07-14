# AI Chatbot Project

Интеллектуальный чат-бот с тремя режимами общения, построенный на FastAPI и SwiftUI.

## Архитектура проекта

- **Backend**: FastAPI приложение с интеграцией Azure OpenAI
- **Frontend**: iOS приложение на SwiftUI
- **AI Provider**: Azure OpenAI API
- **Хранение**: Локальное хранение истории чата на клиенте

## Режимы общения

### 1. Поддержка (Эмпатичное слушание)
- Фокус на активном слушании и эмпатии
- Валидация чувств пользователя
- Без советов и решений

### 2. Анализ (Сократовский диалог)
- Открытые вопросы для саморефлексии
- Помощь в самостоятельном поиске ответов
- Сократовский метод мышления

### 3. Практика (КПТ техники)
- Конкретные упражнения и техники
- Дыхательные практики
- Когнитивное переосмысление

## Быстрый старт

### Backend (FastAPI)

1. **Перейдите в папку backend:**
```bash
cd back
```

2. **Создайте виртуальное окружение:**
```bash
python -m venv venv
source venv/bin/activate  # Windows: venv\Scripts\activate
```

3. **Установите зависимости:**
```bash
pip install -r requirements.txt
```

4. **Настройте переменные окружения:**
```bash
cp env.example .env
# Отредактируйте .env файл с вашими Azure OpenAI данными
```

5. **Запустите сервер:**
```bash
uvicorn main:app --reload --host 0.0.0.0 --port 8000
```

### Frontend (Swift)

1. **Откройте проект в Xcode:**
```bash
cd front
open ChatApp.xcodeproj  # или создайте новый проект
```

2. **Добавьте файлы в проект:**
- `ChatApp.swift`
- `ContentView.swift`
- `Models.swift`
- `ChatService.swift`

3. **Настройте Info.plist для локальных запросов:**
```xml
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsLocalNetworking</key>
    <true/>
</dict>
```

4. **Запустите приложение в симуляторе**

## API Endpoints

- `GET /` - Проверка состояния
- `GET /health` - Детальная проверка здоровья
- `POST /chat` - Основной endpoint для чата

## Структура проекта

```
chatbot/
├── back/                 # FastAPI backend
│   ├── main.py          # Основное приложение
│   ├── models.py        # Pydantic модели
│   ├── ai_service.py    # Azure OpenAI интеграция
│   ├── prompts.py       # Системные промпты
│   ├── requirements.txt # Python зависимости
│   └── env.example      # Шаблон переменных окружения
├── front/               # SwiftUI frontend
│   ├── ChatApp.swift    # Точка входа приложения
│   ├── ContentView.swift # Основной интерфейс
│   ├── Models.swift     # Модели данных
│   └── ChatService.swift # Сетевой сервис
└── README.md           # Документация проекта
```

## Требования

### Backend
- Python 3.8+
- FastAPI
- Azure OpenAI API ключ

### Frontend
- Xcode 14+
- iOS 16+
- Swift 5.7+

## Безопасность

- API ключи хранятся в переменных окружения
- Валидация всех пользовательских входов
- CORS настройки для frontend

## Разработка

### Добавление новых режимов
1. Обновите `ChatMode` enum в `models.py`
2. Добавьте системный промпт в `prompts.py`
3. Обновите `_get_system_prompt` в `ai_service.py`

### Тестирование
- Backend: `http://localhost:8000/docs` для интерактивной документации
- Frontend: Запуск в симуляторе iOS

## Лицензия

MIT License 