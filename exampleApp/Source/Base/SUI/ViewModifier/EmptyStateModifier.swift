import SwiftUI

extension View {
    func emptyState(isEmpty: Bool) -> some View {
        modifier(EmptyStateModifier(isEmpty: isEmpty))
    }
}

private struct EmptyStateModifier: ViewModifier {
    let isEmpty: Bool
    
    func body(content: Content) -> some View {
        if isEmpty {
            // заменить EmptyView() на свою View
            EmptyView()
        } else {
            content
        }
    }
}
