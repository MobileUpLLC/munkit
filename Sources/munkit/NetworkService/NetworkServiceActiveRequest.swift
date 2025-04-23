//
//  NetworkServiceActiveRequest.swift
//  MUNKit
//
//  Created by Ilia Chub on 21.04.2025.
//

import Foundation

struct NetworkServiceActiveRequest: Hashable {
    let id: UUID
    let isAccessTokenRequired: Bool

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
