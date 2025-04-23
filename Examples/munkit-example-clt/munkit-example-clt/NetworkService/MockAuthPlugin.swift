//
//  MockAuthPlugin.swift
//  munkit-example-clt
//
//  Created by Ilia Chub on 11.04.2025.
//

import munkit
import Moya
import Foundation

struct MockAuthPlugin: PluginType {
    init() {}

    func process(
        _ result: Result<Moya.Response, MoyaError>,
        target: TargetType
    ) -> Result<Moya.Response, MoyaError> {
        guard
            let target = target as? MUNAPITarget,
            case .success(let success) = result,
            let request = success.request,
            target.isAccessTokenRequired
        else {
            return result
        }

        guard
            let authHeader = request.value(forHTTPHeaderField: "Authorization"),
            authHeader.replacingOccurrences(of: "Bearer ", with: "") == "00"
        else {
            return .failure(.statusCode(.init(statusCode: 401, data: Data())))
        }

        return result
    }
}
