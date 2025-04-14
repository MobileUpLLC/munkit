//
//  DNDClassOverviewRepository.swift
//  exampleApp
//
//  Created by Natalia Luzyanina on 09.04.2025.
//

public actor DNDClassOverviewRepository {
    public init() {}

    public func getClassOverview(index: String) async throws -> DNDClassOverviewModel {
        return try await MobileService.shared.networkService.executeRequest(target: .classOverview(index))
    }
}
