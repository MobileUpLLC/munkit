import SwiftUI

struct ___FILEBASENAME___: View {
    @ObservedObject var viewModel: ___VARIABLE_productName:identifier___ViewModel

    var body: some View {
        Text("___VARIABLE_productName:identifier___ module created!")
    }
}

#Preview {
    ___FILEBASENAME___(
        viewModel: ___VARIABLE_productName:identifier___ViewModel(
            coordinator: ___VARIABLE_productName:identifier___Coordinator()
        )
    )
}
