import Foundation
import NetworkService

actor SendableDndClassModel: ReplicaObserverHost {
    // Реализуем свойство observerTask с доступом внутри актора
    let observerTask: Task<Void, Never>
    // Реализуем свойство observerActive с доступом внутри актора
    let observerActive: AsyncStream<Bool>
    
    init(observerTask: Task<Void, Never>, observerActive: AsyncStream<Bool>) {
        self.observerTask = observerTask
        self.observerActive = observerActive
    }

    // Можем добавить дополнительные методы для обработки логики
    func startObserving() {
        // Запуск работы с task и stream
    }
}

final class DndClassesViewModel: ObservableObject {
    @Published private(set) var classItems: [DndClassesView.ViewItem]?

    private let coordinator: DndClassesCoordinator
   // private let repository: DndClassesRepository

    private let replica: any Replica<ClassesListModel>
    private weak var observer: ReplicaObserver<ClassesListModel>?
    private var observationTask: Task<Void, Never>?
    private let sendableDndClassModel: SendableDndClassModel

    // MARK: - ReplicaObserverHost
    lazy var observerTask: Task<Void, Never> = Task { }
    var observerActive: AsyncStream<Bool>
    var observerContinuation: AsyncStream<Bool>.Continuation

    // MARK: - Initialization
    init(coordinator: DndClassesCoordinator, replica: any Replica<ClassesListModel>) {
        self.coordinator = coordinator
        self.replica = replica
        
        let (observerActiveStream, observerActiveContinuation) = AsyncStream.makeStream(of: Bool.self)
        observerActive = observerActiveStream
        observerContinuation = observerActiveContinuation
        sendableDndClassModel = SendableDndClassModel(observerTask: Task { }, observerActive: observerActiveStream)

        startObserving()
    }

    // MARK: - Private Methods
    private func startObserving() {
        observationTask = Task {
            let observer = await replica.observe(observerHost: sendableDndClassModel)
            observerContinuation.yield(true)
            self.observer = observer

            guard let stateStream = await observer.replicaStateStream else {
                return
            }
            for await state in stateStream {
                let viewItems = state.data?.value.results.map {
                    DndClassesView.ViewItem(id: $0.index, name: $0.name)
                }
                self.classItems = viewItems
            }
        }
    }

    @MainActor func handleTapOnItem(with id: String) {
        coordinator.showClassOverview(for: id)
    }

    @MainActor
    func getData() {
        Task { [weak self] in
            guard let self else {
                return
            }

            do {
//                let classes = try await repository.fetch()
//                let viewItems = classes.results.map { DndClassesView.ViewItem(id: $0.index, name: $0.name) }
//
//                await MainActor.run {
//                    self.classItems = viewItems
//                }
            } catch {
                print("error")
            }
        }
    }
}
