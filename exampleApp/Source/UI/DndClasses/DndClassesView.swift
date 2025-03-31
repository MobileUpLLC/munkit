import SwiftUI

extension DndClassesView {
    struct ViewItem {
        let id: String
        let name: String
    }
}

struct DndClassesView: View {
    @ObservedObject var viewModel: DndClassesViewModel

    var body: some View {
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
        .onFirstAppear {
           viewModel.getData()
        }
    }
}

#Preview {
    DndClassesView(
        viewModel: DndClassesViewModel(
            coordinator: DndClassesCoordinator(), repository: DndRepository()
        )
    )
}
