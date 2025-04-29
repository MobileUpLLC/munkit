//
//  Moya+Sendable.swift
//  MUNKit
//
//  Created by Ilia Chub on 11.04.2025.
//

@preconcurrency import Moya

extension MoyaError: Sendable {}
extension Response: @unchecked @retroactive Sendable {}
extension Result: Sendable where Success == Response, Failure == MoyaError {}
