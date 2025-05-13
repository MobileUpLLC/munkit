//
//  DNDMonsterSenses.swift
//  munkit-example-core
//
//  Created by Ilia Chub on 12.05.2025.
//

public struct DNDMonsterSenses: Sendable, Decodable {
    let darkvision: String?
    let passivePerception: Int

    enum CodingKeys: String, CodingKey {
        case darkvision
        case passivePerception = "passive_perception"
    }
}
