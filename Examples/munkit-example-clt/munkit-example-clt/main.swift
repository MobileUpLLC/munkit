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
    stubClosure: MoyaProvider.delayedStub(TimeInterval.random(in: 0...3)),
    plugins: [
        MUNKAccessTokenPlugin(accessTokenProvider: tokenProvider),
        MUNKLoggerPlugin.instance,
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
    for id in 1...1 {
        group.addTask {
            _ = await performRequest(id: id)
        }
    }
    await group.waitForAll()
}
