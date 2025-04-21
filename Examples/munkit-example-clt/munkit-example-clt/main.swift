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

var completedTasks = 0
let taskCount = 30

await withTaskGroup { group in
    for id in 1...taskCount {
        group.addTask {
            print("👁️🔑", #function, "\(id)")
            do {
                let _ = try await dndClassesRepository.getClassesListWithAuth()
                print("🥳🔑", #function, "\(id)")
            } catch {
                print("☠️🔑", #function, "\(id)")
            }

            await MainActor.run { completedTasks += 1 }
        }

        group.addTask {
            print("👁️", #function, "\(id)")
            do {
                let _ = try await dndClassesRepository.getClassesListWithoutAuth()
                print("🥳", #function, "\(id)")
            } catch {
                print("☠️", #function, "\(id)")
            }

            await MainActor.run { completedTasks += 1 }
        }
    }
    await group.waitForAll()
}

if completedTasks != taskCount * 2 {
    print("🚨 completedTasks: \(completedTasks) != \(taskCount * 2)")
} else {
    print("✅ All tasks completed successfully!")
}
