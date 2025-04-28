# MobileUp Network Kit

munkit is a Swift library designed to streamline network operations by providing a flexible and extensible approach to handling API requests. Built on top of [Moya](https://github.com/Moya/Moya), it introduces features such as access token management and mock data support.

## Requirements

- iOS 16.0+
- macOS 15.0+
- Swift 6.1+

## Installation

To integrate munkit into your Swift project, add it as a dependency in your `Package.swift` file:

```swift
dependencies: [
    .package(url: "https://github.com/MobileUpLLC/munkit.git", from: "1.0.0")
]
```

Then, include it in your target:

```swift
targets: [
    .target(
        name: "YourTarget",
        dependencies: ["munkit"]
    )
]
```

Alternatively, add the library using the Swift Package Manager interface in Xcode.

## Usage

### Defining API Targets

Your API targets must conform to the `MUNAPITarget` protocol, which extends Moya’s `TargetType` and `AccessTokenAuthorizable`. Below is an example using nested enumerations for `v1` and `v2` APIs:

```swift
enum MyAPI: MUNAPITarget {
    enum V1: MUNAPITarget {
        case getData(endpoint: String)
        case postData(endpoint: String)
        // Additional cases...

        var baseURL: URL { /* Implementation */ }
        var path: String { /* Implementation */ }
        var method: Moya.Method { /* Implementation */ }
        var task: Moya.Task { /* Implementation */ }
        var headers: [String: String]? { /* Implementation */ }
        var parameters: [String: Any] { /* Implementation */ }
        var isAccessTokenRequired: Bool { /* Implementation */ }
        var isRefreshTokenRequest: Bool { /* Implementation */ }
        var isMockEnabled: Bool { /* Implementation */ }
        var mockFileName: String? { /* Implementation */ }
        var authorizationType: Moya.AuthorizationType? { /* Implementation */ }
    }

    enum V2: MUNAPITarget {
        case fetchItems(endpoint: String)
        case updateItem(endpoint: String)
        // Additional cases...

        var baseURL: URL { /* Implementation */ }
        var path: String { /* Implementation */ }
        var method: Moya.Method { /* Implementation */ }
        var task: Moya.Task { /* Implementation */ }
        var headers: [String: String]? { /* Implementation */ }
        var parameters: [String: Any] { /* Implementation */ }
        var isAccessTokenRequired: Bool { /* Implementation */ }
        var isRefreshTokenRequest: Bool { /* Implementation */ }
        var isMockEnabled: Bool { /* Implementation */ }
        var mockFileName: String? { /* Implementation */ }
        var authorizationType: Moya.AuthorizationType? { /* Implementation */ }
    }

    case v1(V1)
    case v2(V2)

    var baseURL: URL {
        switch self {
        case .v1(let target): return target.baseURL
        case .v2(let target): return target.baseURL
        }
    }

    var path: String { /* Implementation */ }
    var method: Moya.Method { /* Implementation */ }
    var task: Moya.Task { /* Implementation */ }
    var headers: [String: String]? { /* Implementation */ }
    var parameters: [String: Any] { /* Implementation */ }
    var isAccessTokenRequired: Bool { /* Implementation */ }
    var isRefreshTokenRequest: Bool { /* Implementation */ }
    var isMockEnabled: Bool { /* Implementation */ }
    var mockFileName: String? { /* Implementation */ }
    var authorizationType: Moya.AuthorizationType? { /* Implementation */ }
}
```

### Initializing the Network Service

Create an instance of `MUNNetworkService` with your target type:

```swift
let networkService = MUNNetworkService<MyAPI>(
    session: /* Optional custom session */,
    plugins: /* Optional additional plugins */
)
```

### Configuring Access Token Management (Optional)

Access token management is facilitated through two protocols: `MUNAccessTokenProvider` and `MUNAccessTokenRefresher`. These can be implemented by separate classes or structs, or by a single entity implementing both protocols:

- **`MUNAccessTokenProvider`**: Supplies the current access token.
- **`MUNAccessTokenRefresher`**: Handles token refresh when needed.

Configure these in `MUNNetworkService` after initialization:

```swift
let tokenProvider: MUNAccessTokenProvider = TokenProvider()
let tokenRefresher: MUNAccessTokenRefresher = TokenRefresher()

await networkService.setAuthorizationObjects(
    provider: tokenProvider,
    refresher: tokenRefresher,
    tokenRefreshFailureHandler: { /* Handle refresh failure */ }
)
```

### Executing Requests

Use the `executeRequest` method to perform API calls:

```swift
do {
    let response = try await networkService.executeRequest(target: .v1(.getData(endpoint: "data")))
    // Process the response
} catch {
    // Handle the error
}
```

### Mock Data Support

To enable mock data for a target, set `isMockEnabled` to `true` and specify a `mockFileName`. Mock data should be provided as a JSON file in your bundle.

For paginated APIs, use the `MUNMockablePaginationAPITarget` protocol and specify `pageIndexParameterName` and `pageSizeParameterName`.

## Features

- **Flexible API Targets**: Define API endpoints with support for access token requirements and mock data.
- **Access Token Management**: Optional automatic handling of token refresh.
- **Mock Data**: Seamlessly switch between real and mock data for testing.
- **Extensibility**: Leverage Moya plugins to customize behavior.

## Contributing

Contributions are welcome! Please create an issue or submit a pull request on GitHub.
