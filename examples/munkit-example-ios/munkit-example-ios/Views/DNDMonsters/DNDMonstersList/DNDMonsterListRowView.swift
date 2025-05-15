//
//  DNDMonsterListRowView.swift
//  munkit-example-ios
//
//  Created by Ilia Chub on 29.04.2025.
//

import SwiftUI
import munkit_example_core

struct DNDMonsterListRowView: View {
    @Environment(NavigationModel.self) private var navigationModel

    let monster: DNDMonsterShortModel

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(monster.name)
                    .font(.headline)
                    .foregroundStyle(.primary)
            }
            Spacer()
        }
        .padding()
        .contentShape(Rectangle())
        .onTapGesture {
            navigationModel.path.append(Destination.dndMonsters(.dndMonster(monster.index)))
        }
    }
}
