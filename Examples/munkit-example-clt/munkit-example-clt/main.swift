//
//  main.swift
//  munkit-example-clt
//
//  Created by Ilia Chub on 11.04.2025.
//

import munkit
import munkit_example_core
import Foundation

await setupNetworkService()
let dndClassesReplica = await getDndClassesReplica()

// TODO: Добавить создание репозитория и его использование

let observerActivityStream: AsyncStreamBundle = AsyncStream<Bool>.makeStream()
let observer = await dndClassesReplica.observe(activityStream: observerActivityStream.stream)

// observerActivityStream.continuation.yield(true)
// Task.sleep(for: .seconds(2))
// observerActivityStream.continuation.yield(false)

try await Task.sleep(for: .seconds(10))
