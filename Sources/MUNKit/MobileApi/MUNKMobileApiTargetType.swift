//
//  MUNKMobileApiTargetType.swift
//  MUNKit
//
//  Created by Natalia Luzyanina on 01.04.2025.
//

import Moya
import Foundation

public protocol MUNKMobileApiTargetType: TargetType, AccessTokenAuthorizable, Sendable {
    var id: UUID { get }
    var parameters: [String: Any] { get }
    var isAccessTokenRequired: Bool { get }
    var isRefreshTokenRequest: Bool { get }
}

extension MUNKMobileApiTargetType {
    var logDescription: String { "[\(self) \(id)]" }
}
