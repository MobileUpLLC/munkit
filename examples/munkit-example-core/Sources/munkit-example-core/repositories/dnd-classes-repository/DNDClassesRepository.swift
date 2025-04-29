//
//  DNDClassesRepository.swift
//  munkit-example-clt
//
//  Created by Ilia Chub on 11.04.2025.
//

import munkit

public actor DNDClassesRepository {
    private let networkService: MUNNetworkService<DNDAPITarget>

    public let replica: any PhysicalReplica<DNDClassesListModel>

    public init(networkService: MUNNetworkService<DNDAPITarget>) async {
        self.networkService = networkService
        self.replica = await ReplicaClient.shared.createReplica(
            name: "DndReplica",
            settings: .init(
                staleTime: 1,
                clearTime: 5,
                clearErrorTime: 1,
                cancelTime: 0.05,
                revalidateOnActiveObserverAdded: true
            ),
            storage: nil,
            fetcher: { try await networkService.executeRequest(target: .classes) }
        )
    }
}
