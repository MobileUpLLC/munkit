//
//  MUNKMobileApiTargetType.swift
//  NetworkService
//
//  Created by Natalia Luzyanina on 01.04.2025.
//

import Moya

public protocol MUNKMobileApiTargetType: TargetType, AccessTokenAuthorizable {
    var parameters: [String: Any] { get }
    var isAccessTokenRequired: Bool { get }
    var isRefreshTokenRequest: Bool { get }
}
