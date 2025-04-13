import SwiftUI

struct RootView: View {
    @ObservedObject var viewModel: RootViewModel

    var body: some View {
        Button {
            viewModel.handleTapOnButton()
        } label: {
            Text("Open D&D Classes")
        }
    }
}

#Preview {
    RootView(
        viewModel: RootViewModel(
            coordinator: RootCoordinator()
        )
    )
}
