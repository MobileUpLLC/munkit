//
//  APITarget.swift
//  MUNKit
//
//  Created by Natalia Luzyanina on 01.04.2025.
//

import Moya

public protocol MUNAPITarget: TargetType, AccessTokenAuthorizable, Sendable {
    var parameters: [String: Any] { get }
    var isAccessTokenRequired: Bool { get }
    var isRefreshTokenRequest: Bool { get }
}
