//
//  DNDClassListRowView.swift
//  munkit-example-ios
//
//  Created by Ilia Chub on 29.04.2025.
//

import SwiftUI
import munkit_example_core

struct DNDClassListRowView: View {
    let dndClass: DNDClassModel

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(dndClass.name)
                    .font(.headline)
                    .foregroundStyle(.primary)
            }
            Spacer()
        }
        .padding()
        .contentShape(Rectangle())
    }
}
