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

let observerActiveStream: AsyncStreamBundle = AsyncStream<Bool>.makeStream()
let observer = await dndClassesReplica.observe(observerActive: observerActiveStream.stream)

try await Task.sleep(for: .seconds(10))
