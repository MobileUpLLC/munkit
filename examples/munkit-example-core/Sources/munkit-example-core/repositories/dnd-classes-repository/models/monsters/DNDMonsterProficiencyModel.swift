//
//  DNDMonsterProficiencyModel.swift
//  munkit-example-core
//
//  Created by Ilia Chub on 12.05.2025.
//

public struct DNDMonsterProficiencyModel: Sendable, Decodable {
    let value: Int
    let proficiency: DNDMonsterProficiencyDetailModel
}
