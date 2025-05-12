//
//  DNDMonsterSpecialAbilityModel.swift
//  munkit-example-core
//
//  Created by Ilia Chub on 12.05.2025.
//

struct DNDMonsterSpecialAbilityModel: Decodable {
    let name: String
    let desc: String
    let damage: [DNDMonsterDamageModel]
}
