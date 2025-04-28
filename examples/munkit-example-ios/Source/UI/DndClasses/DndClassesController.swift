import UIKit

final class DndClassesController: HostingController<DndClassesView> {
    init(viewModel: DndClassesViewModel) {
        super.init(rootView: DndClassesView(viewModel: viewModel))

        navigationItem.title = "D&D Classes"
        navigationItem.largeTitleDisplayMode = .always
        view.backgroundColor = .white
    }
}
