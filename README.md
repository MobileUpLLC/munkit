# MobileUp Network Kit

munkit is a Swift library designed to streamline network operations by providing a flexible and extensible approach to handling API requests. Built on top of [Moya](https://github.com/Moya/Moya), it introduces features such as access token management and mock data support.

## Requirements

- iOS 16.0+
- macOS 15.0+
- Swift 6.1+

## Features

- **Flexible API Targets**: Define API endpoints with support for access token requirements and mock data.
- **Access Token Management**: Optional automatic handling of token refresh.
- **Replica System**: Manage network data with caching, state observation, and automatic refresh for reactive and efficient data handling.
- **Mock Data**: Seamlessly switch between real and mock data for testing.
- **Extensibility**: Leverage Moya plugins to customize behavior.
- **Logging**: Inject custom loggers for network operations.

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

### Logging

The munkit library allows clients to inject a custom logger to handle logging for network operations. To enable logging, you need:

1. Implement the MUNLoggable protocol to define how messages are logged.

```swift
class CustomLoggerAdapter: MUNLoggable {
    func log(type: OSLogType, _ message: String) {
        ...
    }
}
```
2. Configure the MUNLogger with your custom logger implementation.
3. Initialize the NetworkService with the MUNLoggerPlugin.

```swift
    MUNLogger.setupLogger(CustomLoggerAdapter())
    let networkService = NetworkService(plugins: [MUNLoggerPlugin.instance])
```

## Replica

munkit provides a powerful `Replica` system. Replicas encapsulate data fetching, storage, and observation logic, making it easy to handle API responses in a reactive and efficient manner.

### Key Components

- **`SingleReplica`**: An actor-based protocol for managing a single data type, supporting fetching, refreshing, and state observation.
- **`ReplicaState`**: Tracks the loading state, data, errors, and observer status for a replica.
- **`ReplicaSettings`**: Configures replica behavior, including stale time, data/error clearing, and revalidation policies.
- **`ReplicaStorage`**: An optional protocol for persisting replica data to disk.
- **`ReplicaObserver`**: Monitors replica state changes and observer activity via async streams.

### Usage Example

Define a repository to manage a replica for API data:

```swift
import munkit

public actor DNDClassesRepository {
    private let networkService: NetworkService
    private var dndClassesListReplica: (any SingleReplica<DNDClassesListModel>)?

    public init(networkService: NetworkService) {
        self.networkService = networkService
    }

    public func getDNDClassesListReplica() async -> any SingleReplica<DNDClassesListModel> {
        if let replica = dndClassesListReplica { return replica }
        dndClassesListReplica = await ReplicasHolder.shared.getReplica(
            name: "DNDClassesListReplica",
            settings: .init(
                staleTime: 10,
                clearTime: 5,
                clearErrorTime: 1,
                cancelTime: 0.05,
                revalidateOnActiveObserverAdded: true
            ),
            storage: nil,
            fetcher: { [weak self] in
                guard let networkService = self?.networkService else { throw CancellationError() }
                return try await networkService.executeRequest(target: .classes)
            }
        )
        return dndClassesListReplica!
    }
}
```

In a SwiftUI view, observe the replica's state:

```swift
import SwiftUI
import munkit

struct DNDClassesListView: View {
    @Environment(DNDClassesRepository.self) private var dndClassesRepository
    @State private var replicaState: ReplicaState<DNDClassesListModel>?
    @State private var replicaSetupped = false
    private let activityStream = AsyncStream<Bool>.makeStream()

    var body: some View {
        ZStack {
            if let state = replicaState, let data = state.data?.value.results, !data.isEmpty {
                List(data, id: \.index) { dndClass in
                    Text(dndClass.name)
                }
                .refreshable { Task { await dndClassesRepository.getDNDClassesListReplica().revalidate() } }
            }
        }
        .onAppear {
            guard !replicaSetupped else { activityStream.continuation.yield(true); return }
            replicaSetupped = true
            Task {
                let observer = await dndClassesRepository.getDNDClassesListReplica().observe(
                    activityStream: activityStream.stream
                )
                activityStream.continuation.yield(true)
                for await state in await observer.stateStream {
                    replicaState = state
                }
            }
        }
    }
}
```

## Contributing

Contributions are welcome! Please create an issue or submit a pull request on GitHub.
