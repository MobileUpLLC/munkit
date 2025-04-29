//
//  munkit_example_iosApp.swift
//  munkit-example-ios
//
//  Created by Ilia Chub on 29.04.2025.
//

import SwiftUI
import munkit
import munkit_example_core

extension NetworkService: @retroactive Observable {}
extension DNDClassesRepository: @retroactive Observable {}

@main
struct munkit_example_iosApp: App {
    let dndClassesRepository: DNDClassesRepository

    init() {
        let networkService = NetworkService()
        self.dndClassesRepository = DNDClassesRepository(networkService: networkService)
    }

    var body: some Scene {
        WindowGroup {
            FirstView()
                .environment(dndClassesRepository)
        }
    }
}
