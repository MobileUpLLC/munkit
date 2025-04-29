//
//  main.swift
//  munkit-example-clt
//
//  Created by Ilia Chub on 11.04.2025.
//

import munkit
import munkit_example_core
import Foundation

let tokenProvider = AccessTokenProviderAndRefresher()
let networkService = MUNNetworkService<DNDAPITarget>()
let repository = await DNDClassesRepository(networkService: networkService)

let observer1 = await Observer(name: "observer1", replica: repository.replica)

try await _Concurrency.Task.sleep(for: .seconds(20))
