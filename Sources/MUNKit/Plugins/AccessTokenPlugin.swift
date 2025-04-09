//
//  AccessTokenPlugin.swift
//  MUNKit
//
//  Created by Natalia Luzyanina on 01.04.2025.
//

import Foundation
import Moya

struct AccessTokenPlugin: PluginType {
    private let accessTokenProvider: MUNKTokenProvider

    init(accessTokenProvider: MUNKTokenProvider) {
        self.accessTokenProvider = accessTokenProvider
    }
    
    func prepare(_ request: URLRequest, target: TargetType) -> URLRequest {
        guard let mobileApiTarget = target as? MUNKMobileApiTargetType else {
            return request
        }
        
        return prepare(request, target: mobileApiTarget)
    }

    private func prepare(_ request: URLRequest, target: MUNKMobileApiTargetType) -> URLRequest {
        var request = request
        
        if target.isAccessTokenRequired, let accessToken = accessTokenProvider.accessToken {
            request.addValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        }
        
        return request
    }
}
