//
//  munkit_example_iosApp.swift
//  munkit-example-ios
//
//  Created by Ilia Chub on 29.04.2025.
//

import SwiftUI
import munkit
import munkit_example_core

@main
struct munkit_example_iosApp: App {
    let navigationModel = NavigationModel()
    let dndClassesRepository: DNDClassesRepository

    init() {
        let networkService = NetworkService()
        MUNLogger.setupLogger(MUDKitLoggerAdapter())
        self.dndClassesRepository = DNDClassesRepository(networkService: networkService)
    }

    var body: some Scene {
        WindowGroup {
            @Bindable var navigationModel = navigationModel
            NavigationStack(path: $navigationModel.path) {
                FirstView()
                    .navigationDestination(for: Destination.self, destination: destination)
            }
            .environment(dndClassesRepository)
            .environment(navigationModel)
        }
    }

    @ViewBuilder private func destination(for path: Destination) -> some View {
        switch path {
        case .dndClasses(let destination):
            switch destination {
            case .dndClassesList:
                DNDClassesListView()
            }
        }
    }
}
