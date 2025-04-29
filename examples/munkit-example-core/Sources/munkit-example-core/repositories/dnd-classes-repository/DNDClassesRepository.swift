//
//  DNDClassesRepository.swift
//  munkit-example-clt
//
//  Created by Ilia Chub on 11.04.2025.
//

import munkit

public actor DNDClassesRepository {
    private let networkService: MUNNetworkService<DNDAPITarget>
    private var toggleLikeTasks: [String: Task<Void, Never>] = [:]

    public let replica: any PhysicalReplica<DNDClassesListModel>

    public init(networkService: MUNNetworkService<DNDAPITarget>) async {
        self.networkService = networkService
        self.replica = await ReplicaClient.shared.createReplica(
            name: "DndReplica",
            settings: .init(
                staleTime: 100,
                clearTime: 5,
                clearErrorTime: 1,
                cancelTime: 0.05
            ),
            storage: nil,
            fetcher: { try await networkService.executeRequest(target: .classes) }
        )
    }

    public func getClassesList() async throws -> DNDClassesListModel {
        return try await networkService.executeRequest(target: .classes)
    }
}
