//
//  DNDClassOverviewModel.swift
//  munkit-example-core
//
//  Created by Natalia Luzyanina on 17.04.2025.
//

import Foundation

public struct DNDClassOverviewModel: Decodable, Sendable {
    public let name: String
    public let hitDie: Int
    public let savingThrows: [SavingThrow]
    public let proficiencies: [Proficiency]
    public let spellcasting: Spellcasting?

    enum CodingKeys: String, CodingKey {
        case name
        case hitDie = "hit_die"
        case savingThrows = "saving_throws"
        case proficiencies
        case spellcasting
    }

    public init(
        name: String,
        hitDie: Int,
        savingThrows: [SavingThrow],
        proficiencies: [Proficiency],
        spellcasting: Spellcasting?
    ) {
        self.name = name
        self.hitDie = hitDie
        self.savingThrows = savingThrows
        self.proficiencies = proficiencies
        self.spellcasting = spellcasting
    }

    public struct SavingThrow: Decodable, Sendable {
        public let name: String
    }

    public struct Proficiency: Decodable, Sendable {
        public let name: String
    }

    public struct Spellcasting: Decodable, Sendable {
        public let info: [Info]

        public struct Info: Decodable, Sendable {
            public let desc: [String]
        }
    }
}
