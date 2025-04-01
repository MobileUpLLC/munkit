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

final class DndClassesRepository: Fetcher {
    typealias T = ClassesListModel

    func fetch() async throws -> T {
        return try await MobileService.shared.request(target: .classes)
    }
}
