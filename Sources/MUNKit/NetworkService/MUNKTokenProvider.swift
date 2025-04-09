//
//  MUNKTokenProvider.swift
//  MUNKit
//
//  Created by Natalia Luzyanina on 01.04.2025.
//

public protocol MUNKTokenProvider: Sendable {
    var accessToken: String? { get }

    @discardableResult
    func refreshToken() async throws -> String
}
