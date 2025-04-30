//
//  FirstView.swift
//  munkit-example-ios
//
//  Created by Ilia Chub on 30.04.2025.
//

import SwiftUI

struct FirstView: View {
    var body: some View {
        ZStack {
            Color.white
                .ignoresSafeArea()
            VStack {
                LinkButton(title: "D&D Classes List 1", value: .dndClasses(.dndClassesList))
                LinkButton(title: "D&D Classes List 2", value: .dndClasses(.dndClassesList))
            }
        }
        .navigationTitle("munkit Example iOS")

    }
}

#Preview {
    FirstView()
}
