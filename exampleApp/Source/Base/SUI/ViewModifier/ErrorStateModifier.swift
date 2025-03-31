import SwiftUI

extension View {
    func errorState<Content: View, T>(
        error: T?,
        content: @escaping () -> Content
    ) -> some View {
        modifier(ErrorState(isError: error != nil, errorContent: content))
    }
    
    func errorState<Content: View>(
        isError: Bool,
        content: @escaping () -> Content
    ) -> some View {
        modifier(ErrorState(isError: isError, errorContent: content))
    }
}

private struct ErrorState<ErrorContent: View>: ViewModifier {
    var isError: Bool
    let errorContent: () -> ErrorContent
    
    func body(content: Content) -> some View {
        if isError {
            errorContent()
        } else {
            content
        }
    }
}
