import Foundation

public typealias MoyaProvider = Moya.MoyaProvider

public protocol NetworkService {
    associatedtype Target: MobileApiTargetType
    var onTokenRefreshFailed: (() -> Void)? { get set }

    func request<T: Decodable & Sendable>(target: Target) async throws -> T
    func request(target: Target) async throws
}

public protocol TokenRefreshProvider: Sendable {
    @discardableResult
    func refreshToken() async throws -> String
}

open class BaseNetworkService<Target: MobileApiTargetType>: NetworkService {
    public var onTokenRefreshFailed: (() -> Void)? { didSet { onceExecutor = OnceExecutor() } }

    public let apiProvider: MoyaProvider<Target>
    public let tokenRefreshProvider: TokenRefreshProvider

    private var tokenRefresher: TokenRefresher { TokenRefresher(tokenRefreshProvider: tokenRefreshProvider) }
    private var onceExecutor: OnceExecutor?

    public init(apiProvider: MoyaProvider<Target>, tokenRefreshProvider: TokenRefreshProvider) {
        self.apiProvider = apiProvider
        self.tokenRefreshProvider = tokenRefreshProvider
    }

    public func request<T: Decodable & Sendable>(target: Target) async throws -> T {
        Log.refreshTokenFlow.debug(logEntry: .text("NetworkService. Request \(target) started"))

        do {
            return try await apiProvider.request(target: target)
        } catch {
            try _Concurrency.Task.checkCancellation()

            if target.isRefreshTokenRequest == false,
               let serverError = error as? ServerError,
               case .unauthorized = serverError {
                try await refreshToken()
                Log.refreshTokenFlow.debug(logEntry: .text("NetworkService. Request \(target) started"))
                return try await apiProvider.request(target: target)
            } else {
                let logText = "NetworkService. Request \(target) failed with error \(error)"
                Log.refreshTokenFlow.debug(logEntry: .text(logText))
                throw error
            }
        }
    }

    public func request(target: Target) async throws {
        Log.refreshTokenFlow.debug(logEntry: .text("NetworkService. Request \(target) started"))

        do {
            return try await apiProvider.request(target: target)
        } catch {
            try _Concurrency.Task.checkCancellation()

            if target.isRefreshTokenRequest == false,
               let serverError = error as? ServerError,
               case .unauthorized = serverError {
                try await refreshToken()
                Log.refreshTokenFlow.debug(logEntry: .text("NetworkService. Request \(target) started"))
                return try await apiProvider.request(target: target)
            } else {
                let logText = "NetworkService. Request \(target) failed with error \(error)"
                Log.refreshTokenFlow.debug(logEntry: .text(logText))
                throw error
            }
        }
    }

    private func refreshToken() async throws {
        do {
            try await tokenRefresher.refreshToken()
        } catch let error {
            try _Concurrency.Task.checkCancellation()

            if let serverError = error as? ServerError,
               case .unauthorized = serverError {
                await onceExecutor?.executeTokenRefreshFailed()
            }

            if let serverError = error as? ServerError,
               case .tokenExpired = serverError {
                await onceExecutor?.executeTokenRefreshFailed()
            }

            Log.refreshTokenFlow.debug(logEntry: .text("NetworkService. RefreshToken request failed. \(error)"))
            throw error
        }
    }
}

private extension BaseNetworkService {
    actor TokenRefresher {
        private let tokenRefreshProvider: TokenRefreshProvider
        private var refreshTokenTask: _Concurrency.Task<Void, Error>?

        init(tokenRefreshProvider: TokenRefreshProvider) {
            self.tokenRefreshProvider = tokenRefreshProvider
        }

        func refreshToken() async throws {
            Log.refreshTokenFlow.debug(logEntry: .text("NetworkService. RefreshToken method called"))

            if refreshTokenTask == nil {
                refreshTokenTask = _Concurrency.Task {
                    defer { refreshTokenTask = nil }

                    let attempts = 1
                    var lastError: Error?

                    for attempt in 1...attempts {
                        let logText = "NetworkService. RefreshToken request started with attempt number \(attempt)"
                        Log.refreshTokenFlow.debug(logEntry: .text(logText))

                        do {
                            _ = try await tokenRefreshProvider.refreshToken()
                            Log.refreshTokenFlow.debug(logEntry: .text("NetworkService. RefreshToken updated"))
                            lastError = nil
                            break
                        } catch {
                            lastError = error
                        }
                    }

                    if let lastError {
                        throw lastError
                    }
                }
            }

            try await refreshTokenTask!.value
        }
    }

    actor OnceExecutor {
        private var hasRun = false
        private var onTokenRefreshFailed: (() -> Void)?

        func executeTokenRefreshFailed() async {
            guard hasRun == false else {
                return
            }
            hasRun = true
            onTokenRefreshFailed?()
            Log.refreshTokenFlow.debug(logEntry: .text("NetworkService. Send onTokenRefreshFailed"))
        }
    }
}
