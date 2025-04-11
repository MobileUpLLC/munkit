import Foundation
import MUNKit
import Moya

actor MobileService {
    static let shared = MobileService()

    let networkService: MUNKNetworkService<MobileApi>

    private init() {
        let tokenProvider = TokenProvider()
        let configuration = URLSessionConfiguration.default
        configuration.headers = .default
        configuration.urlCache = nil

        let apiProvider = MoyaProvider<MobileApi>(
            session: Session(configuration: configuration, startRequestsImmediately: true),
            plugins: [MUNKLoggerPlugin.instance]
        )

        self.networkService = MUNKNetworkService(apiProvider: apiProvider, tokenRefreshProvider: tokenProvider)
    }
}
