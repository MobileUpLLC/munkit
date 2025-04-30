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
                NavigationLink("D&D Classes List", value: Destination.dndClasses(.dndClassesList))
                    .foregroundStyle(.black)
                    .font(.system(size: 20, weight: .bold))
                    .padding()
                    .background {
                        Capsule()
                            .fill(.thinMaterial)
                            .stroke(.black, lineWidth: 1)
                    }
            }
        }
        .navigationTitle("munkit Example iOS")

    }
}

#Preview {
    FirstView()
}
