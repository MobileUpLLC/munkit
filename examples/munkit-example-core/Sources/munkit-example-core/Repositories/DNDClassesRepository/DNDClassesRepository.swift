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
            storage: nil,
            fetcher: { try await networkService.executeRequest(target: .classes) }
        )
    }

    public func getClassesList() async throws -> DNDClassesListModel {
        return try await networkService.executeRequest(target: .classes)
    }

    public func setLike(index: String, liked: Bool) {
        toggleLikeTasks[index]?.cancel()

        toggleLikeTasks[index] = Task {
            try? await setLike(id: index, liked: liked)
        }
    }


    private func setLike(id: String, liked: Bool) async throws {
        let updateClassLiked = OptimisticUpdate<DNDClassesListModel> { classesList in
            var updatedClassesList = classesList
            updatedClassesList.results = classesList.results.map { model in
                if model.index == id {
                    var updatedModel = model
                    updatedModel.isLiked = liked
                    return updatedModel
                } else {
                    return model
                }
            }
            return updatedClassesList
        }
        
        try await replica.withOptimisticUpdate(update: updateClassLiked) {
            try await Task.sleep(for: .seconds(3))

            return try await self.networkService.executeRequest(target: .like(liked))
        }
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
