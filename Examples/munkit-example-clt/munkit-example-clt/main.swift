//
//  main.swift
//  munkit-example-clt
//
//  Created by Ilia Chub on 11.04.2025.
//

import munkit
import Foundation

private let accessTokenProviderAndRefresher = AccessTokenProviderAndRefresher()

private let networkService = MUNNetworkService<DNDAPITarget>(plugins: [MockAuthPlugin()])
await networkService.setAuthorizationObjects(
    provider: accessTokenProviderAndRefresher,
    refresher: accessTokenProviderAndRefresher,
    tokenRefreshFailureHandler: { print("🧨 Token refresh failed handler called") }
)

let dndClassesRepository = await DNDClassesRepository(networkService: networkService)
var task: Task<Void, Never>?

task = Task {
    do {
        let _ = try await dndClassesRepository.getClassesListWithAuth()
        print("🥳")
    } catch {
        print(error)
        print("☠️")
    }
}

Task {
    try? await Task.sleep(for: .seconds(3))
    task?.cancel()
}

try await Task.sleep(for: .seconds(100))
