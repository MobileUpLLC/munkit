import SwiftUI
import munkit_example_core

extension ClassOverviewView {
    struct ViewItem {
        let name: String
        let hitDie: String
        let savingThrows: [String]
        let proficiencies: [String]
        let description: String?
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
    }
}

#Preview {
    ClassOverviewView(
        viewModel: ClassOverviewViewModel(
            id: "", coordinator: ClassOverviewCoordinator(), repository: DNDClassOverviewRepository()
        )
    )
}
