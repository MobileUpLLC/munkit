import UIKit

final class ClassOverviewController: HostingController<ClassOverviewView> {
    init(viewModel: ClassOverviewViewModel) {
        super.init(rootView: ClassOverviewView(viewModel: viewModel))

        view.backgroundColor = .systemBackground
    }
}
