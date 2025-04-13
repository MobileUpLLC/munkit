//
//  main.swift
//  munkit-example-clt
//
//  Created by Ilia Chub on 11.04.2025.
//

import munkit
import munkit_example_core
import Moya
import Foundation

private let tokenProvider = TokenProvider()

private let provider = MoyaProvider<DNDAPITarget>(
    plugins: [
        MUNAccessTokenPlugin(accessTokenProvider: tokenProvider),
        MockAuthPlugin()
    ]
)

private let networkService = MUNNetworkService(apiProvider: provider, tokenRefreshProvider: tokenProvider)

await networkService.setTokenRefreshFailureHandler { print("🧨 Token refresh failed handler called") }

ReplicaClient.shared.createReplica(name: "DNDClassesReplica", storage: nil, fetcher: <#T##Fetcher<Sendable>##Fetcher<Sendable>##() async throws -> Sendable#>)





let dndClassesRepository = await DNDClassesRepository(networkService: networkService)

func performRequest(id: Int) async {
    print("👁️", #function, "\(id)")
    do {
        let _ = try await dndClassesRepository.getClassesList()
        print("🥳", #function, "\(id)")
    } catch {
        print("☠️", #function, "\(id)")
    }
}

await withTaskGroup(of: Void.self) { group in
    for id in 1...30 {
        group.addTask {
            _ = await performRequest(id: id)
        }
    }
    await group.waitForAll()
}
