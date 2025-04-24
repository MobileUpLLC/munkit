# MobileUp Network Kit

munkit — это Swift-библиотека, которая упрощает работу с сетью, предоставляя гибкий и расширяемый способ обработки API-запросов. Она основана на [Moya](https://github.com/Moya/Moya) и добавляет такие функции, как управление токенами доступа и поддержка мок-данных.

## Требования

- iOS 16.0 или новее
- macOS 15.0 или новее

## Установка

Чтобы использовать munkit в вашем Swift-проекте, добавьте его как зависимость в файл `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/MobileUpLLC/munkit.git", from: "1.0.0")
]
```

Затем добавьте его в вашу цель:

```swift
targets: [
    .target(
        name: "YourTarget",
        dependencies: ["munkit"]
    )
]
```

Или добавьте библиотеку через интерфейс Swift Package Manager в Xcode.

## Использование

### Определение API-целей

Ваши API-цели должны соответствовать протоколу `MUNAPITarget`, который расширяет `TargetType` и `AccessTokenAuthorizable` из Moya. Пример с вложенными перечислениями для `v1` и `v2`:

```swift
enum MyAPI: MUNAPITarget {
    enum V1: MUNAPITarget {
        case getData(endpoint: String)
        case postData(endpoint: String)
        ...
    }

    enum V2: MUNAPITarget {
        case fetchItems(endpoint: String)
        case updateItem(endpoint: String)
        ...
    }

    case v1(V1)
    case v2(V2)

    var baseURL: URL {
        switch self {
        case .v1(let target): return target.baseURL
        case .v2(let target): return target.baseURL
        }
    }

    var path: String {...}
    var method: Moya.Method {...}
    var task: Moya.Task {...}
    var headers: [String: String]? {...}
    var parameters: [String: Any] {...}
    var isAccessTokenRequired: Bool {...}
    var isRefreshTokenRequest: Bool {...}
    var isMockEnabled: Bool {...}
    var mockFileName: String? {...}
    var authorizationType: Moya.AuthorizationType? {...}
}
```

### Инициализация сетевого сервиса

Создайте экземпляр `MUNNetworkService` с вашим типом цели:

```swift
let networkService = MUNNetworkService<MyAPI>(
    session: /* опционально ваша сессия */,
    plugins: /* опционально дополнительные плагины */
)
```

### Настройка управления токенами доступа (опционально)

Для управления токенами доступа реализованы два протокола: `MUNAccessTokenProvider` и `MUNAccessTokenRefresher`. Они могут быть реализованы как разными классами или структурами, так и одним классом:

- **`MUNAccessTokenProvider`**: Предоставляет текущий токен доступа.
- **`MUNAccessTokenRefresher`**: Отвечает за обновление токена при необходимости.

Настройте их в `MUNNetworkService` после инициализации:

```swift
let tokenProvider: MUNAccessTokenProvider = TokenProvider()
let tokenRefresher: MUNAccessTokenRefresher = TokenRefresher()

await networkService.setAuthorizationObjects(
    provider: tokenProvider,
    refresher: tokenRefresher,
    tokenRefreshFailureHandler: { /* обработка ошибки обновления */ }
)
```

### Выполнение запросов

Используйте метод `executeRequest` для выполнения API-вызовов:

```swift
do {
    let response = try await networkService.executeRequest(target: .v1(.getData(endpoint: "data")))
    // Обработка ответа
} catch {
    // Обработка ошибки
}
```

### Поддержка мок-данных

Чтобы включить мок-данные для цели, установите `isMockEnabled` в `true` и укажите `mockFileName`. Мок-данные должны быть представлены в виде JSON-файла в вашем бандле.

Для пагинированных API используйте протокол `MUNMockablePaginationAPITarget` и укажите `pageIndexParameterName` и `pageSizeParameterName`.

## Особенности

- **Гибкие API-цели**: Определяйте ваши конечные точки API с поддержкой требований к токенам доступа и мок-данных.
- **Управление токенами доступа**: Автоматическая обработка обновления токенов (опционально).
- **Мок-данные**: Легкое переключение между реальными и мок-данными для тестирования.
- **Расширяемость**: Используйте плагины Moya для настройки поведения.

## Как внести вклад

Приветствуются любые вклады! Пожалуйста, создайте задачу или отправьте pull request на GitHub.
