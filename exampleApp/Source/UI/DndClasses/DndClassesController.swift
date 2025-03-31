import UIKit

final class DndClassesController: HostingController<DndClassesView> {
    init(viewModel: DndClassesViewModel) {
        super.init(rootView: DndClassesView(viewModel: viewModel))

        navigationItem.title = "D&D Classes"
        navigationItem.largeTitleDisplayMode = .always
      //  navigationController?.navigationBar.prefersLargeTitles = true
//        let centralItem = NavigationBarInfoItem(item: .title("D&D Classes"))
//        navigationBarModel = NavigationBarModel(infoToolbarItem: centralItem, isLargeTitle: true)
    }
}
