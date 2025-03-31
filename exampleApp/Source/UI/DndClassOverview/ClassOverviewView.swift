import SwiftUI

extension ClassOverviewView {
    struct ViewItem {
        let name: String
        let hitDie: String // Например, "1d12"
        let savingThrows: [String] // Например, ["Strength", "Constitution"]
        let proficiencies: [String] // Например, ["Light Armor", "Simple Weapons"]
        let description: String? // Описание, если есть
    }
}

struct ClassOverviewView: View {
    @ObservedObject var viewModel: ClassOverviewViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if let viewItem = viewModel.viewItem {
            Text(viewItem.name)
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.horizontal)
                VStack(alignment: .leading, spacing: 12) {
                    Text("Hit Die: \(viewItem.hitDie)")
                    Text("Saving Throws: \(viewItem.savingThrows.joined(separator: ", "))")
                    Text("Proficiencies: \(viewItem.proficiencies.joined(separator: ", "))")
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                .padding(.horizontal)

                if let description = viewItem.description {
                    ScrollView {
                        Text(description)
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal)
                }
            }

            Spacer()
        }
        .onFirstAppear {
            viewModel.getData()
        }
//        .onAppear(perform: viewModel.handleViewFirstAppearance)
//        .skeleton(isLoading: viewModel.state == .loading) {
//            SkeletonClassView()
//        }
//        .errorState(isError: viewModel.state == .error) {
//            ErrorView(action: viewModel.handleViewFirstAppearance)
//        }
    }
}

#Preview {
    ClassOverviewView(
        viewModel: ClassOverviewViewModel(
            id: "", coordinator: ClassOverviewCoordinator(), repository: DndRepository()
        )
    )
}
