//
//  File.swift
//  Example
//
//  Created by Natalia Luzyanina on 30.03.2025.
//

import Foundation
import NetworkService
import Moya

final class DndRepository {
    private let mobileService = MobileService.shared

    func getDndClasses() async throws -> ClassesListModel {
        return try await mobileService.request(target: .classes)
    }

    func getClassOverview(index: String) async throws -> ClassOverviewModel {
        return try await mobileService.request(target: .classOverview(index))
    }
}
