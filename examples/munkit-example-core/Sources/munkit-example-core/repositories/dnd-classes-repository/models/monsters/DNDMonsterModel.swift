//
//  DNDMonsterModel.swift
//  munkit-example-core
//
//  Created by Ilia Chub on 12.05.2025.
//

import Foundation

public struct DNDMonsterModel: Sendable, Decodable {
    let index: String
    let name: String
    let size: String
    let type: String
    let alignment: String
    let armorClass: [DNDMonsterArmorClassModel]
    let hitPoints: Int
    let hitDice: String
    let hitPointsRoll: String
    let speed: DNDMonsterSpeedModel
    let strength: Int
    let dexterity: Int
    let constitution: Int
    let intelligence: Int
    let wisdom: Int
    let charisma: Int
    let proficiencies: [DNDMonsterProficiencyModel]
    let damageVulnerabilities: [String]
    let damageResistances: [String]
    let damageImmunities: [String]
    let conditionImmunities: [String]
    let senses: DNDMonsterSenses
    let languages: String
    let challengeRating: Float
    let proficiencyBonus: Int
    let xp: Int
    let specialAbilities: [DNDMonsterSpecialAbilityModel]
    let actions: [DNDMonsterActionModel]
    let legendaryActions: [DNDMonsterLegendaryActionModel]
    let image: String
    let url: String
    let updatedAt: String
    let forms: [String]
    let reactions: [String]

    enum CodingKeys: String, CodingKey {
        case index
        case name
        case size
        case type
        case alignment
        case armorClass = "armor_class"
        case hitPoints = "hit_points"
        case hitDice = "hit_dice"
        case hitPointsRoll = "hit_points_roll"
        case speed
        case strength
        case dexterity
        case constitution
        case intelligence
        case wisdom
        case charisma
        case proficiencies
        case damageVulnerabilities = "damage_vulnerabilities"
        case damageResistances = "damage_resistances"
        case damageImmunities = "damage_immunities"
        case conditionImmunities = "condition_immunities"
        case senses
        case languages
        case challengeRating = "challenge_rating"
        case proficiencyBonus = "proficiency_bonus"
        case xp
        case specialAbilities = "special_abilities"
        case actions
        case legendaryActions = "legendary_actions"
        case image
        case url
        case updatedAt = "updated_at"
        case forms
        case reactions
    }
}
