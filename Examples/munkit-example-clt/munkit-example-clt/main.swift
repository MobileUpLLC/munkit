//
//  main.swift
//  munkit-example-clt
//
//  Created by Ilia Chub on 11.04.2025.
//

import MUNKit
import Moya
import Foundation

private let tokenProvider = TokenProvider()

private let provider = MoyaProvider<DNDAPITarget>(
    plugins: [
        MUNKAccessTokenPlugin(accessTokenProvider: tokenProvider),
        MockAuthPlugin()
    ]
)

private let networkService = MUNKNetworkService(apiProvider: provider, tokenRefreshProvider: tokenProvider)

await networkService.setTokenRefreshFailedAction { print("🧨 Token refresh failed handler called") }

let dndClassesRepository = await DNDClassesRepository(networkService: networkService)

func performRequest(id: Int) async {
    print(#function, "started for \(id)")
    do {
        let _ = try await dndClassesRepository.getClassesList()
        print("🍀", "completed for \(id)")
    } catch {
        print("🚨", "failed for \(id): \(error)")
    }
}

await withTaskGroup(of: Void.self) { group in
    for id in 1...5 {
        group.addTask {
            _ = await performRequest(id: id)
        }
    }
    await group.waitForAll()
}
