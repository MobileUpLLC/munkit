import SwiftUI

extension View {
    func loadable(isLoading: Bool) -> some View {
        modifier(LoadingViewModifier(isLoading: isLoading))
    }
}

private struct LoadingViewModifier: ViewModifier {
    let isLoading: Bool

    func body(content: Content) -> some View {
        if isLoading {
            // заменить EmptyView() на свою LoadingView
            EmptyView()
        } else {
            content
        }
    }
}
