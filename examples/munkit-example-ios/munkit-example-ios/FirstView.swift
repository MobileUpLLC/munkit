//
//  FirstView.swift
//  munkit-example-ios
//
//  Created by Ilia Chub on 29.04.2025.
//

import SwiftUI
import munkit
import munkit_example_core

struct FirstView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Spacer()
                NavigationLink {
                    DNDClassesListView()
                } label: {
                    Text("View All D&D Classes 1")
                        .font(.headline)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.black)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .padding(.horizontal)
                }
                NavigationLink {
                    DNDClassesListView()
                        .environment(DNDClassesRepository(networkService: NetworkService()))
                } label: {
                    Text("View All D&D Classes 2")
                        .font(.headline)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.black)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .padding(.horizontal)
                }
                Spacer()
            }
            .navigationTitle("D&D Companion")
            .background(Color(.systemGroupedBackground))
        }
    }
}

#Preview {
    FirstView()
        .environment(NetworkService())
}
