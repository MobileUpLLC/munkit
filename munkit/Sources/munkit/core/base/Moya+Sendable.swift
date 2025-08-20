//
//  Moya+Sendable.swift
//  MUNKit
//
//  Created by Ilia Chub on 11.04.2025.
//

@preconcurrency import Moya

extension Response: @unchecked @retroactive Sendable {}
extension MoyaProvider: @retroactive @unchecked Sendable {}
