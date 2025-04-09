//
//  DndClassOverviewRepository.swift
//  exampleApp
//
//  Created by Natalia Luzyanina on 09.04.2025.
//

import Foundation

final class DndClassOverviewRepository {
    private let mobileService = MobileService.shared

    func getClassOverview(index: String) async throws -> ClassOverviewModel {
        return try await mobileService.request(target: .classOverview(index))
    }
}
