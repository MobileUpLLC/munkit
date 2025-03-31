import SwiftUI

class HostingController<T: View>: UIHostingController<T> {
    override init(rootView: T) {
        super.init(rootView: rootView)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .clear
    }
    
    @available(*, unavailable) @MainActor dynamic required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}
