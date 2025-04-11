//
//  TokenProvider.swift
//  munkit-example-clt
//
//  Created by Ilia Chub on 11.04.2025.
//

import MUNKit
import Moya
import Foundation

final class TokenProvider: MUNKTokenProvider, @unchecked Sendable {
    var accessToken: String? {
        get { accessTokenQueue.sync { _accessToken } }
        set { accessTokenQueue.sync { _accessToken = newValue } }
    }

    private var _accessToken: String?
    private let accessTokenQueue: DispatchQueue

    init() {
        self._accessToken = "00"
        self.accessTokenQueue = DispatchQueue(
            label: "com.mobileup.munkit-example-clt.access-token-queue",
            qos: .userInitiated
        )
    }

    func refreshToken() async throws -> String {
        guard let previousToken = accessToken else {
            throw MoyaError.statusCode(.init(statusCode: 400, data: Data()))
        }

        try await _Concurrency.Task.sleep(for: .seconds(2))
        let newToken = previousToken + "0"
        accessToken = newToken

        return newToken
    }
}
