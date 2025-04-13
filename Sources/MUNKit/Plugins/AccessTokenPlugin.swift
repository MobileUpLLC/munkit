//
//  MUNAccessTokenPlugin.swift
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
        guard let mobileApiTarget = target as? MUNMobileApiTargetType else {
            return request
        }
        
        return prepare(request, target: mobileApiTarget)
    }

    private func prepare(_ request: URLRequest, target: MUNMobileApiTargetType) -> URLRequest {
        var request = request
        
        if target.isAccessTokenRequired, let accessToken = accessTokenProvider.accessToken {
            request.addValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        }
        
        return request
    }
}
