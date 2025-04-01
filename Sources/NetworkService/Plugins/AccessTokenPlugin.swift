import Foundation
import Moya

public protocol MUNKTokenProvider: Sendable {
    var accessToken: String? { get }

    @discardableResult
    func refreshToken() async throws -> String
}

struct AccessTokenPlugin: PluginType {
    private let accessTokenProvider: MUNKTokenProvider

    init(accessTokenProvider: MUNKTokenProvider) {
        self.accessTokenProvider = accessTokenProvider
    }
    
    func prepare(_ request: URLRequest, target: TargetType) -> URLRequest {
        guard let mobileApiTarget = target as? MobileApiTargetType else {
            return request
        }
        
        return prepare(request, target: mobileApiTarget)
    }

    private func prepare(_ request: URLRequest, target: MobileApiTargetType) -> URLRequest {
        var request = request
        
        if target.isAccessTokenRequired, let accessToken = accessTokenProvider.accessToken {
            request.addValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        }
        
        return request
    }
}
