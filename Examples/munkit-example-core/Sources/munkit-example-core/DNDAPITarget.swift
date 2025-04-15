//
//  DNDAPITarget.swift
//  munkit-example-clt
//
//  Created by Ilia Chub on 11.04.2025.
//

import munkit
import Moya
import Foundation

public enum DNDAPITarget {
    case classes
    case classOverview(String)
    case like(Bool)
}

extension DNDAPITarget: MUNAPITarget {
    public var parameters: [String : Any] { [:] }
    public var isAccessTokenRequired: Bool { true }
    public var isRefreshTokenRequest: Bool { false }
    public var baseURL: URL { URL(string: "https://www.dnd5eapi.co")! }
    public var path: String { getPath() }
    public var method: Moya.Method { .get }
    public var task: Moya.Task { .requestPlain }
    public var headers: [String : String]? { [:] }
    public var authorizationType: Moya.AuthorizationType? { .bearer }

    func getPath() -> String {
        switch self {
        case .classes:
            return "/api/2014/classes"
        case .classOverview(let index):
            return "/api/2014/classes/\(index)"
        case .like(_):
            return "/api/2014/like"
        }
    }
}

// extension DNDAPITarget: MUNMockableAPITarget {
//    public var isMockEnabled: Bool {
//        switch self {
//        case .classes, .classOverview:
//            false
//        case .like:
//            true
//        }
//    }
//    
//    public func getMockFileName() -> String? {
//        switch self {
//        case .classes, .classOverview, .like:
//            return nil
//        }
//    }
// }
