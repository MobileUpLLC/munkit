//
//  DNDClassesRepository.swift
//  munkit-example-clt
//
//  Created by Ilia Chub on 11.04.2025.
//

import MUNKit

actor DNDClassesRepository: Sendable {
    private let networkService: MUNKNetworkService<DNDAPITarget>

    init(networkService: MUNKNetworkService<DNDAPITarget>) async {
        self.networkService = networkService
    }

    func getClassesList() async throws -> DNDClassesListModel {
        return try await networkService.request(target: .classes)
    }
}
