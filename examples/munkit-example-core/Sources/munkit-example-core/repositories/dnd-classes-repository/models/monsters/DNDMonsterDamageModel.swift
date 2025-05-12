//
//  DNDMonsterDamageModel.swift
//  munkit-example-core
//
//  Created by Ilia Chub on 12.05.2025.
//

struct DNDMonsterDamageModel: Decodable {
    let damageType: DNDMonsterDamageTypeModel
    let damageDice: String

    enum CodingKeys: String, CodingKey {
        case damageType = "damage_type"
        case damageDice = "damage_dice"
    }
}
