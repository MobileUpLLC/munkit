//
//  MUNKMobileApiTargetType.swift
//  MUNKit
//
//  Created by Natalia Luzyanina on 01.04.2025.
//

import Moya
import Foundation

public protocol MUNKMobileApiTargetType: TargetType, AccessTokenAuthorizable, Sendable {
    var parameters: [String: Any] { get }
    var isAccessTokenRequired: Bool { get }
    var isRefreshTokenRequest: Bool { get }
}
