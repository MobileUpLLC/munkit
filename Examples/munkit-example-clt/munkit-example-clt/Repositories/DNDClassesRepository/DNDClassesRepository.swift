//
//  DNDClassesRepository.swift
//  munkit-example-clt
//
//  Created by Ilia Chub on 11.04.2025.
//

import munkit

actor DNDClassesRepository {
    private let networkService: MUNNetworkService<DNDAPITarget>

    init(networkService: MUNNetworkService<DNDAPITarget>) async {
        self.networkService = networkService
    }

    func getClassesListWithAuth() async throws -> DNDClassesListModel {
        return try await networkService.executeRequest(target: .classesWithAuth)
    }

    func getClassesListWithoutAuth() async throws -> DNDClassesListModel {
        return try await networkService.executeRequest(target: .classesWithoutAuth)
    }
}
