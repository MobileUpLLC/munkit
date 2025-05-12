//
//  DNDMonsterActionModel.swift
//  munkit-example-core
//
//  Created by Ilia Chub on 12.05.2025.
//

struct DNDMonsterActionModel: Decodable {
    let name: String
    let desc: String
    let multiattackType: String?
    let attackBonus: Int?
    let usage: DNDMonsterUsageModel?
    let damage: [DNDMonsterDamageModel]
    let actions: [DNDMonsterSubActionModel]

    enum CodingKeys: String, CodingKey {
        case name
        case desc
        case multiattackType = "multiattack_type"
        case attackBonus = "attack_bonus"
        case usage
        case damage
        case actions
    }
}
