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
            storage: nil,
            fetcher: { try await MobileService.shared.networkService.executeRequest(target: .classes) }
        )
    }

    public func getClassesList() async throws -> DNDClassesListModel {
        return try await networkService.executeRequest(target: .classes)
    }


    public func clearData() async {
        await replica.clear()
    }

    public func invalidateData() async {
        await replica.invalidate()
    }

    public func setData(data: DNDClassesListModel) async {
        await replica.setData(data: data)
    }

    public func mutateData(transform: @escaping (DNDClassesListModel) -> DNDClassesListModel) async {
        Task {
            await replica.mutataData(transform: transform)
        }
    }
}
