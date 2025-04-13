//
//  MUNTokenProvider.swift
//  MUNKit
//
//  Created by Natalia Luzyanina on 01.04.2025.
//

public protocol MUNTokenProvider: Sendable {
    var accessToken: String? { get }

    func refreshToken() async throws
}
