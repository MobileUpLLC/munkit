//
//  DNDMonsterDetailDataView.swift
//  munkit-example-ios
//
//  Created by Ilia Chub on 15.05.2025.
//

import SwiftUI
import munkit_example_core

struct DNDMonsterDetailDataView: View {
    let monster: DNDMonsterModel

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground)
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 16) {
                    // Header Section
                    VStack(spacing: 8) {
                        AsyncImage(url: URL(string: "https://www.dnd5eapi.co"+monster.image)) {
                            $0
                                .resizable()
                                .clipShape(.circle)
                        } placeholder: {
                            ProgressView()
                        }
                            .frame(width: 200, height: 200)
                        Text(monster.name)
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .multilineTextAlignment(.center)
                        Text("\(monster.size) \(monster.type), \(monster.alignment)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top)

                    // Stats Section
                    GroupBox {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Stats")
                                .font(.headline)
                            HStack(spacing: 16) {
                                StatView(title: "STR", value: "\(monster.strength)")
                                StatView(title: "DEX", value: "\(monster.dexterity)")
                                StatView(title: "CON", value: "\(monster.constitution)")
                                StatView(title: "INT", value: "\(monster.intelligence)")
                                StatView(title: "WIS", value: "\(monster.wisdom)")
                                StatView(title: "CHA", value: "\(monster.charisma)")
                            }
                        }
                    }
                    .backgroundStyle(.background)

                    // Combat Section
                    GroupBox {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Combat")
                                .font(.headline)
                            DetailRow(title: "Armor Class", value: monster.armorClass.map { "\($0.value) (\($0.type))" }.joined(separator: ", "))
                            DetailRow(title: "Hit Points", value: "\(monster.hitPoints) (\(monster.hitDice))")
                            DetailRow(title: "Speed", value: [
                                monster.speed.walk.map { "Walk \($0)" },
                                monster.speed.swim.map { "Swim \($0)" }
                            ].compactMap { $0 }.joined(separator: ", "))
                            DetailRow(title: "Challenge Rating", value: "\(monster.challengeRating) (\(monster.xp) XP)")
                        }
                    }
                    .backgroundStyle(.background)

                    // Defenses Section
                    GroupBox {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Defenses")
                                .font(.headline)
                            DetailRow(title: "Damage Vulnerabilities", value: monster.damageVulnerabilities.joined(separator: ", "))
                            DetailRow(title: "Damage Resistances", value: monster.damageResistances.joined(separator: ", "))
                            DetailRow(title: "Damage Immunities", value: monster.damageImmunities.joined(separator: ", "))
                            DetailRow(title: "Condition Immunities", value: monster.conditionImmunities.joined(separator: ", "))
                        }
                    }
                    .backgroundStyle(.background)

                    // Senses and Languages
                    GroupBox {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Senses & Languages")
                                .font(.headline)
                            DetailRow(title: "Senses", value: [
                                monster.senses.darkvision.map { "Darkvision \($0)" },
                                "Passive Perception \(monster.senses.passivePerception)"
                            ].compactMap { $0 }.joined(separator: ", "))
                            DetailRow(title: "Languages", value: monster.languages.isEmpty ? "None" : monster.languages)
                        }
                    }
                    .backgroundStyle(.background)

                    // Abilities Section
                    if !monster.specialAbilities.isEmpty {
                        GroupBox {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Special Abilities")
                                    .font(.headline)
                                ForEach(monster.specialAbilities, id: \.name) { ability in
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(ability.name)
                                            .font(.subheadline)
                                            .fontWeight(.semibold)
                                        Text(ability.desc)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                        if !ability.damage.isEmpty {
                                            Text("Damage: \(ability.damage.map { "\($0.damageDice) \($0.damageType.name)" }.joined(separator: ", "))")
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                    }
                                }
                            }
                        }
                        .backgroundStyle(.background)
                    }

                    // Actions Section
                    if !monster.actions.isEmpty {
                        GroupBox {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Actions")
                                    .font(.headline)
                                ForEach(monster.actions, id: \.name) { action in
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(action.name)
                                            .font(.subheadline)
                                            .fontWeight(.semibold)
                                        Text(action.desc)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                        if !action.damage.isEmpty {
                                            Text("Damage: \(action.damage.map { "\($0.damageDice) \($0.damageType.name)" }.joined(separator: ", "))")
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                        if let usage = action.usage {
                                            Text("Usage: \(usage.type) \(String(describing: usage.times)) times")
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                    }
                                }
                            }
                        }
                        .backgroundStyle(.background)
                    }

                    // Legendary Actions Section
                    if !monster.legendaryActions.isEmpty {
                        GroupBox {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Legendary Actions")
                                    .font(.headline)
                                ForEach(monster.legendaryActions, id: \.name) { action in
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(action.name)
                                            .font(.subheadline)
                                            .fontWeight(.semibold)
                                        Text(action.desc)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                        if !action.damage.isEmpty {
                                            Text("Damage: \(action.damage.map { "\($0.damageDice) \($0.damageType.name)" }.joined(separator: ", "))")
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                    }
                                }
                            }
                        }
                        .backgroundStyle(.background)
                    }
                }
                .padding()
            }
        }
        .navigationTitle(monster.name)
        .navigationBarTitleDisplayMode(.inline)
    }
}

// Reusable Stat View
struct StatView: View {
    let title: String
    let value: String

    var body: some View {
        VStack {
            Text(title)
                .font(.caption)
                .fontWeight(.bold)
            Text(value)
                .font(.subheadline)
        }
        .frame(maxWidth: .infinity)
    }
}

// Reusable Detail Row
struct DetailRow: View {
    let title: String
    let value: String

    var body: some View {
        if !value.isEmpty {
            HStack(alignment: .top) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .frame(width: 150, alignment: .leading)
                Text(value)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.leading)
                Spacer()
            }
        }
    }
}
