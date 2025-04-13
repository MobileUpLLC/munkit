//
//  DNDAPITarget.swift
//  munkit-example-clt
//
//  Created by Ilia Chub on 11.04.2025.
//

import MUNKit
import Moya
import Foundation

 enum DNDAPITarget {
     case classes
 }

 extension DNDAPITarget: MUNAPITarget {
     var parameters: [String : Any] { [:] }
     var isAccessTokenRequired: Bool { true }
     var isRefreshTokenRequest: Bool { false }
     var baseURL: URL { URL(string: "https://www.dnd5eapi.co")! }
     var path: String { "/api/2014/classes" }
     var method: Moya.Method { .get }
     var task: Moya.Task { .requestPlain }
     var headers: [String : String]? { [:] }
     var authorizationType: Moya.AuthorizationType? { .bearer }
 }
