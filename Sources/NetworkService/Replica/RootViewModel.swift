import Foundation

final class RootViewModel: ObservableObject {
    private let coordinator: RootCoordinator
    
    init(coordinator: RootCoordinator) {
        self.coordinator = coordinator
    }
}
