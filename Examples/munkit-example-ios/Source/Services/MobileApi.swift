import Foundation
import munkit
import Moya

enum MobileApi {
    case classes
    case classOverview(String)
}

extension MobileApi: MUNAPITarget {
    var parameters: [String : Any] { [:] }
    var isAccessTokenRequired: Bool { false }
    var isRefreshTokenRequest: Bool { false }
    var baseURL: URL { Environments.mobileApiUrl }
    var path: String { getPath() }
    var method: Moya.Method { getMethod() }
    var task: Moya.Task { .requestPlain }
    var headers: [String : String]? { [:] }
    var authorizationType: Moya.AuthorizationType? { .bearer }

    private func getPath() -> String {
        switch self {
        case .classes:
            return "/api/2014/classes"
        case .classOverview(let index):
            return "/api/2014/classes/\(index)"
        }
    }

    private func getMethod() -> Moya.Method {
        switch self {
        case .classes, .classOverview:
            return .get
        }
    }
}
