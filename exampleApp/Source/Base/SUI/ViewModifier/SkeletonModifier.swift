import SwiftUI

extension View {
    func skeleton<Content: View>(
        isLoading: Bool,
        content: @escaping () -> Content
    ) -> some View {
        modifier(SkeletonModifier(isLoading: isLoading, contentBuilder: content))
    }
}

private struct SkeletonModifier<ContentView: View>: ViewModifier {
    let isLoading: Bool
    let contentView: ContentView
    
    init(isLoading: Bool, contentBuilder: () -> ContentView) {
        self.isLoading = isLoading
        contentView = contentBuilder()
    }
    
    func body(content: Content) -> some View {
        if isLoading {
            return AnyView(contentView.shimmering(active: isLoading))
        } else {
            return AnyView(content)
        }
    }
}
