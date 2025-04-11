import MUNKit

final class DndClassesRepository: Sendable {
    let replica: any PhysicalReplica<ClassesListModel>

    init() async {
        self.replica = await ReplicaClient.shared.createReplica(
            name: "DndReplica",
            storage: nil,
            fetcher: { try await MobileService.shared.networkService.request(target: .classes) }
        )
    }

    func clearData() async {
        await replica.clear()
    }

    func invalidateData() async {
        await replica.invalidate()
    }
}
