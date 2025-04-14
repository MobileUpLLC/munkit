import munkit
import Foundation

actor DndClassesRepository {
    let replica: any PhysicalReplica<ClassesListModel>

    init() async {
        self.replica = await ReplicaClient.shared.createReplica(
            name: "DndReplica",
            storage: nil,
            fetcher: { try await MobileService.shared.networkService.executeRequest(target: .classes) }
        )
    }

    func clearData() async {
        await replica.clear()
    }

    func invalidateData() async {
        await replica.invalidate()
    }

    func setData(data: ClassesListModel) async {
        await replica.setData(data: data)
    }

    func mutateData(transform: @escaping (ClassesListModel) -> ClassesListModel) async {
        Task {
            await replica.mutataData(transform: transform)
        }
    }
}
