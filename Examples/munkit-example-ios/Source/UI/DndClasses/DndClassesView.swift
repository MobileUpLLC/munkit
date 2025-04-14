import SwiftUI

extension DndClassesView {
    struct ViewItem: Sendable {
        let id: String
        let name: String
    }
}

struct DndClassesView: View {
    @ObservedObject var viewModel: DndClassesViewModel

    var body: some View {
        VStack {
            List {
                if let items = viewModel.classItems {
                    ForEach(items, id: \.id) { item in
                        Text(item.name)
                            .onTapGesture {
                                viewModel.handleTapOnItem(with: item.id)
                            }
                    }
                }
            }

            Button {
                viewModel.clearData()
            } label: {
                Text("Clear data")
            }
            Button {
                viewModel.invalidateData()
            } label: {
                Text("Invalidate data")
            }
            Button {
                viewModel.setData()
            } label: {
                Text("Set data")
            }
            Button {
                viewModel.mutateData()
            } label: {
                Text("Mutate data")
            }
        }
        .onFirstAppear { viewModel.startObserving() }
        .onDisappear { viewModel.deinitObserver() }
    }
}
