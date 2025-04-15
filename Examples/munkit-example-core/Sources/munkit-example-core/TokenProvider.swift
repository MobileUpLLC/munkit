//
//  TokenProvider.swift
//  munkit-example-clt
//
//  Created by Ilia Chub on 11.04.2025.
//

import munkit
import Moya
import Foundation

public final class TokenProvider: MUNAccessTokenProvider, @unchecked Sendable {
    public var accessToken: String? {
        get { accessTokenQueue.sync { _accessToken } }
        set { accessTokenQueue.sync { _accessToken = newValue } }
    }

    private var _accessToken: String?
    private let accessTokenQueue: DispatchQueue

    // TODO: изначальное значение _accessToken
    public init() {
        self._accessToken = "0"
        self.accessTokenQueue = DispatchQueue(
            label: "com.mobileup.munkit-example-clt.access-token-queue",
            qos: .userInitiated
        )
    }

    public func refreshToken() async throws {
        print("✍️", #function)

        guard let previousToken = accessToken else {
            throw MoyaError.statusCode(.init(statusCode: 400, data: Data()))
        }

        try await _Concurrency.Task.sleep(for: .seconds(2))
        let newToken = previousToken + "0"
        accessToken = newToken
    }
}
