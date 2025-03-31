import Foundation

struct ClassOverviewModel: Decodable {
    let name: String
    let hitDie: Int
    let savingThrows: [SavingThrow]
    let proficiencies: [Proficiency]
    let spellcasting: Spellcasting?

    enum CodingKeys: String, CodingKey {
        case name
        case hitDie = "hit_die"
        case savingThrows = "saving_throws"
        case proficiencies
        case spellcasting
    }

    struct SavingThrow: Decodable {
        let name: String
    }

    struct Proficiency: Decodable {
        let name: String
    }

    struct Spellcasting: Decodable {
        let info: [Info]

        struct Info: Decodable {
            let desc: [String]
        }
    }
}
