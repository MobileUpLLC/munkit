import Foundation
import munkit
import munkit_example_core

final class ClassOverviewViewModel: ObservableObject {
    @Published private(set) var viewItem: ClassOverviewView.ViewItem?

    private let repository: DNDClassOverviewRepository
    private let replica: any Replica<DNDClassOverviewModel>
    private var observerTask: Task<Void, Never>?
    private let observerStateStream: AsyncStreamBundle<Bool>

    private let dndClassId: String

    init(
        id: String,
        replica: any Replica<DNDClassOverviewModel>,
        repository: DNDClassOverviewRepository
    ) {
        self.dndClassId = id
        self.replica = replica
        self.repository = repository
        self.observerStateStream = AsyncStream<Bool>.makeStream()
    }

    @MainActor
    func startObserving() {
        print("\(self): startObserving")

        observerTask = Task { [weak self] in
            guard let self else {
                return
            }

            let observer = await replica.observe(activityStream: observerStateStream.stream)

            self.observerStateStream.continuation.yield(true)

            for await state in await observer.stateStream {
                let model = state.data?.valueWithOptimisticUpdates

                print("🐉 DNDClassOverviewViewModel: \(String(describing: model))")
                guard let model else {
                    return
                }
                self.viewItem = .init(
                    name: model.name,
                    hitDie: "1d\(model.hitDie)",
                    savingThrows: model.savingThrows.map { $0.name },
                    proficiencies: model.proficiencies.map { $0.name },
                    description: model.spellcasting.map { $0.info.flatMap { $0.desc }.joined(separator: "\n") }
                )
            }
            await observer.stopObserving()
        }
    }
    
    func deinitObserver() {
        observerStateStream.continuation.yield(false)
        observerTask?.cancel()
        observerTask = nil
    }
    
    deinit {
        print("deinit ClassOverviewViewModel")
    }
}
