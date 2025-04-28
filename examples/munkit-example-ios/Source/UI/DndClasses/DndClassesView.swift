import SwiftUI

extension DndClassesView {
    struct ViewItem: Sendable {
        let id: String
        let name: String
        var isLiked: Bool
    //    var likeCount: Int
    }
}

struct DndClassesView: View {
    @ObservedObject var viewModel: DndClassesViewModel

    var body: some View {
        VStack {
            List {
                if let items = viewModel.classItems {
                    ForEach(items, id: \.id) { item in
                        HStack {
                            Text(item.name)
                                .onTapGesture { viewModel.handleTapOnItem(with: item.id) }
                            Spacer()
                            //  Text("\(item.likeCount)")
                            Button(action: {
                                viewModel.setLike(index: item.id)
                            }, label: {
                                Image(systemName: item.isLiked ? "heart.fill" : "heart")
                            })
                            .buttonStyle(PlainButtonStyle())
                        }
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
        .onAppear { viewModel.startObserving() }
        .onDisappear { viewModel.deinitObserver() }
    }
}
