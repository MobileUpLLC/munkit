import Foundation
import MUNKit
import Moya

final class MobileService: MUNKNetworkService<MobileApi> {
    nonisolated(unsafe) static let shared = MobileService()

    private init() {
        let tokenProvider = AuthRepository()

        let configuration = URLSessionConfiguration.default
        configuration.headers = .default
        configuration.urlCache = nil

        let apiProvider = MoyaProvider<MobileApi>(
            session: Session(configuration: configuration, startRequestsImmediately: true),
            plugins: [LoggerPlugin.instance]
        )

        super.init(apiProvider: apiProvider, tokenRefreshProvider: tokenProvider)
    }
}
