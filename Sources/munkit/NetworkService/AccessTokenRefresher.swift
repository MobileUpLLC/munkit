//
//  MUNAccessTokenRefresher.swift
//  MUNKit
//
//  Created by Ilia Chub on 23.04.2025.
//

import Foundation

public protocol MUNAccessTokenRefresher: Sendable {
    func refresh() async throws
}
