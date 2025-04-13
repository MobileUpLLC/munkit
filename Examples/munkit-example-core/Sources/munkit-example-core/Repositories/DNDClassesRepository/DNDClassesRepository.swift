//
//  DNDClassesRepository.swift
//  munkit-example-clt
//
//  Created by Ilia Chub on 11.04.2025.
//

import munkit

public actor DNDClassesRepository {
    private let networkService: MUNNetworkService<DNDAPITarget>

    public init(networkService: MUNNetworkService<DNDAPITarget>) async {
        self.networkService = networkService
    }

    public func getClassesList() async throws -> DNDClassesListModel {
        return try await networkService.executeRequest(target: .classes)
    }
}
