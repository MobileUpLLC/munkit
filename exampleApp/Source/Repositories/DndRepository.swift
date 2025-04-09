import Foundation
import MUNKit
// import Moya

final class DndRepository {
    private let mobileService = MobileService.shared

    func getDndClasses() async throws -> ClassesListModel {
        return try await mobileService.request(target: .classes)
    }

    func getClassOverview(index: String) async throws -> ClassOverviewModel {
        return try await mobileService.request(target: .classOverview(index))
    }
}

final class DndClassesRepository: Sendable {
    let replica: any PhysicalReplica<ClassesListModel>

    init() async {
        self.replica = await ReplicaClient.shared.createReplica(
            name: "DndReplica",
            storage: nil,
            fetcher: { try await MobileService.shared.request(target: .classes) }
        )
    }
}
