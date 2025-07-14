# Настройка Info.plist в Xcode

## Проблема с сетевыми запросами

Для подключения к локальному backend серверу нужно добавить настройки в Info.plist.

### Шаги:

1. **Откройте проект в Xcode**
2. **Найдите Info.plist** в навигаторе проекта
3. **Добавьте следующие ключи:**

```xml
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsLocalNetworking</key>
    <true/>
    <key>NSAllowsArbitraryLoads</key>
    <true/>
</dict>
```

### Альтернативный способ (через Xcode UI):

1. **Кликните правой кнопкой** на Info.plist
2. **Выберите "Open As" → "Source Code"**
3. **Добавьте код выше** перед закрывающим `</dict>`

### Что это делает:

- `NSAllowsLocalNetworking` - разрешает подключения к localhost
- `NSAllowsArbitraryLoads` - разрешает HTTP запросы (для разработки)

### После настройки:

1. **Очистите проект** (Product → Clean Build Folder)
2. **Перезапустите** приложение в симуляторе

## Проверка подключения

После настройки Info.plist приложение должно:
- Показать зеленый индикатор подключения
- Успешно отправлять сообщения на backend
- Получать ответы от AI

## Если проблемы остаются:

1. Убедитесь, что backend запущен на `localhost:8000`
2. Проверьте, что Info.plist сохранен
3. Перезапустите Xcode 