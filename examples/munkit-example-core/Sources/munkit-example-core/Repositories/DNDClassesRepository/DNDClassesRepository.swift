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
            settings: .init(staleTime: 10),
            storage: nil,
            fetcher: { try await networkService.executeRequest(target: .classes) }
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
        await replica.setData(data)
    }

    public func mutateData(transform: @escaping (DNDClassesListModel) -> DNDClassesListModel) async {
        Task {
            await replica.mutateData(transform: transform)
        }
    }
}
