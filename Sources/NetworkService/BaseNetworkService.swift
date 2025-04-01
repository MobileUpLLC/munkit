import Moya

public protocol TokenRefreshProvider: Sendable {
    @discardableResult
    func refreshToken() async throws -> String
}

open class BaseNetworkService<Target: MobileApiTargetType> {
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
               let serverError = error as? MoyaError,
               serverError.errorCode == 403
            {
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
               let serverError = error as? MoyaError,
               serverError.errorCode == 403
            {
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

            if let serverError = error as? MoyaError, serverError.errorCode == 403 {
                await onceExecutor?.executeTokenRefreshFailed()
            }

            if let serverError = error as? MoyaError, serverError.errorCode == 409 {
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

            if let task = refreshTokenTask {
                return try await task.value
            }

            refreshTokenTask = _Concurrency.Task { [weak self] in
                guard let self else { throw CancellationError() }

                Log.refreshTokenFlow.debug(logEntry: .text("NetworkService. RefreshToken request started"))

                do {
                    _ = try await tokenRefreshProvider.refreshToken()
                    Log.refreshTokenFlow.debug(logEntry: .text("NetworkService. RefreshToken updated"))
                } catch {
                    Log.refreshTokenFlow.debug(logEntry: .text("NetworkService. RefreshToken failed: \(error)"))
                    throw error
                }
            }

            try await refreshTokenTask?.value
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
