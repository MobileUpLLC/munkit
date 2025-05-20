//
//  MUNAccessTokenRefresher.swift
//  MUNKit
//
//  Created by Ilia Chub on 23.04.2025.
//

public protocol MUNAccessTokenRefresher: Sendable {
    func refresh() async throws
}
