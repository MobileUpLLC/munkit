//
//  DNDMonsterProficiencyModel.swift
//  munkit-example-core
//
//  Created by Ilia Chub on 12.05.2025.
//

struct DNDMonsterProficiencyModel: Decodable {
    let value: Int
    let proficiency: DNDMonsterProficiencyDetailModel
}
