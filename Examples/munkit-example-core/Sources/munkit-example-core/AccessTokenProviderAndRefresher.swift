//
//  AccessTokenProviderAndRefresher.swift
//  munkit-example-clt
//
//  Created by Ilia Chub on 11.04.2025.
//

import munkit
import Moya
import Foundation

<<<<<<<< HEAD:Examples/munkit-example-core/Sources/munkit-example-core/TokenProvider.swift
public final class TokenProvider: MUNAccessTokenProvider, @unchecked Sendable {
    public var accessToken: String? {
========
final class AccessTokenProviderAndRefresher: MUNAccessTokenProvider, MUNAccessTokenRefresher, @unchecked Sendable {
    var accessToken: String? {
>>>>>>>> main:Examples/munkit-example-core/Sources/munkit-example-core/AccessTokenProviderAndRefresher.swift
        get { accessTokenQueue.sync { _accessToken } }
        set { accessTokenQueue.sync { _accessToken = newValue } }
    }

    private var _accessToken: String?
    private let accessTokenQueue: DispatchQueue

    public init(accessToken: String? = nil) {
        self._accessToken = accessToken
        self.accessTokenQueue = DispatchQueue(
            label: "com.mobileup.munkit-example-clt.access-token-queue",
            qos: .userInitiated
        )
    }

<<<<<<<< HEAD:Examples/munkit-example-core/Sources/munkit-example-core/TokenProvider.swift
    public func refreshToken() async throws {
        print("✍️", #function)
========
    func refresh() async throws {
        print("✍️", #function, "start")
>>>>>>>> main:Examples/munkit-example-core/Sources/munkit-example-core/AccessTokenProviderAndRefresher.swift

        guard let previousToken = accessToken else {
            throw MoyaError.statusCode(.init(statusCode: 400, data: Data()))
        }

        print("✍️", #function, "before sleep")
        try await _Concurrency.Task.sleep(for: .seconds(2))
        print("✍️", #function, "after sleep")
        let newToken = previousToken + "0"
        accessToken = newToken
    }
}
