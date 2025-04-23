//
//  MUNAccessTokenProvider.swift
//  MUNKit
//
//  Created by Natalia Luzyanina on 01.04.2025.
//

public protocol MUNAccessTokenProvider: Sendable {
    var accessToken: String? { get }
}
