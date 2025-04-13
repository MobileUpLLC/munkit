//
//  AccessTokenPlugin.swift
//  MUNKit
//
//  Created by Natalia Luzyanina on 01.04.2025.
//

import Foundation
import Moya

public struct MUNAccessTokenPlugin: PluginType {
    private let accessTokenProvider: MUNAccessTokenProvider

    public init(accessTokenProvider: MUNAccessTokenProvider) {
        self.accessTokenProvider = accessTokenProvider
    }
    
    public func prepare(_ request: URLRequest, target: TargetType) -> URLRequest {
        guard let target = target as? MUNAPITarget else {
            return request
        }
        
        var request = request

        if target.isAccessTokenRequired, let accessToken = accessTokenProvider.accessToken {
            request.addValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        }

        return request
    }
}
