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
        MUNAccessTokenPlugin(accessTokenProvider: tokenProvider),
        MockAuthPlugin()
    ]
)

private let networkService = MUNNetworkService(apiProvider: provider, tokenRefreshProvider: tokenProvider)

await networkService.setTokenRefreshFailureHandler { print("🧨 Token refresh failed handler called") }

let dndClassesRepository = await DNDClassesRepository(networkService: networkService)

await withTaskGroup(of: Void.self) { group in
    for id in 1...100 {
        group.addTask {
            print("👁️", #function, "\(id)")
            do {
                let _ = try await dndClassesRepository.getClassesList()
                print("🥳", #function, "\(id)")
            } catch {
                print("☠️", #function, "\(id)")
            }
        }
    }
    await group.waitForAll()
}
