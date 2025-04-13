import UIKit

final class RootController: HostingController<RootView> {
    init(viewModel: RootViewModel) {
        super.init(rootView: RootView(viewModel: viewModel))

        view.backgroundColor = .white
    }
}
