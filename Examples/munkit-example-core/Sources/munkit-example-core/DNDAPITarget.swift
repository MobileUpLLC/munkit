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
}

extension DNDAPITarget: MUNAPITarget {
    public var parameters: [String : Any] { [:] }
    public var isAccessTokenRequired: Bool { true }
    public var isRefreshTokenRequest: Bool { false }
    public var baseURL: URL { URL(string: "https://www.dnd5eapi.co")! }
    public var path: String { "/api/2014/classes" }
    public var method: Moya.Method { .get }
    public var task: Moya.Task { .requestPlain }
    public var headers: [String : String]? { [:] }
    public var authorizationType: Moya.AuthorizationType? { .bearer }
}
