import SwiftUI

// вызовет action только при первом появлении view
extension View {
    func onFirstAppear(_ action: @escaping () -> Void) -> some View {
        modifier(FirstAppearModifier(action: action))
    }
}

private struct FirstAppearModifier: ViewModifier {
    let action: () -> Void

    @State private var hasAppeared = false
    
    func body(content: Content) -> some View {
        content.onAppear {
            guard hasAppeared == false else {
                return
            }
            
            hasAppeared = true
            action()
        }
    }
}
