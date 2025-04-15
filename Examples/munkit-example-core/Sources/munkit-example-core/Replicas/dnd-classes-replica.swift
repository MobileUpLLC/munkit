//
//  dnd-classes-replica.swift
//  munkit-example-clt
//
//  Created by Ilia Chub on 14.04.2025.
//

import munkit

// TODO: Убрать

public func getDndClassesReplica() async -> any Replica<DNDClassesListModel> {
    let dndClassesRepository = await DNDClassesRepository(networkService: networkService)
    return await ReplicaClient.shared.createReplica(
        name: "DNDClassesReplica",
        storage: nil
    ) {
        try await dndClassesRepository.getClassesList()
    }
}
