#!/bin/bash

# Скрипт для деплоя chatbot на виртуальную машину
# Использование: ./deploy.sh

echo "🚀 Начинаем деплой chatbot..."

# Переходим в папку backend
cd back

# Проверяем, что мы в правильной директории
if [ ! -f "docker-compose.yml" ]; then
    echo "❌ Ошибка: docker-compose.yml не найден. Запустите скрипт из папки chatbot/"
    exit 1
fi

# Останавливаем контейнеры
echo "🛑 Останавливаем контейнеры..."
docker-compose down

# Удаляем старые образы (опционально)
echo "🧹 Очищаем старые образы..."
docker system prune -f

# Пересобираем и запускаем контейнеры
echo "🔨 Пересобираем контейнеры..."
docker-compose up --build -d

# Проверяем статус
echo "✅ Проверяем статус контейнеров..."
docker-compose ps

# Проверяем логи
echo "📋 Логи web контейнера:"
docker-compose logs web --tail=10

echo "🎉 Деплой завершен!"
echo "🌐 Backend доступен по адресу: https://pinkponys.org"
echo "📊 Мониторинг Celery: https://pinkponys.org:5555" 