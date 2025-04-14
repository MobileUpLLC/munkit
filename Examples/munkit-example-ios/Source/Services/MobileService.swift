import Foundation
import munkit
import Moya

actor MobileService {
    static let shared = MobileService()

    let networkService: MUNNetworkService<MobileApi>

    private init() {
        let tokenProvider = TokenProvider()
        let configuration = URLSessionConfiguration.default
        configuration.headers = .default
        configuration.urlCache = nil

        let apiProvider = MoyaProvider<MobileApi>(
            session: Session(configuration: configuration, startRequestsImmediately: true),
            plugins: [MUNLoggerPlugin.instance]
        )

        self.networkService = MUNNetworkService(apiProvider: apiProvider, tokenRefreshProvider: tokenProvider)
    }
}
