//
//  NavigationModel.swift
//  munkit-example-ios
//
//  Created by Ilia Chub on 30.04.2025.
//

import SwiftUI

@Observable
class NavigationModel {
    var path: NavigationPath = .init() { didSet { handleNavigationPathDidSet(oldPath: oldValue) } }

    private var actionsAfterPop: [Int: () -> Void] = [:]

    func performActionAfterPop(completion: @escaping () -> Void) {
        actionsAfterPop[path.count] = completion
    }

    private func handleNavigationPathDidSet(oldPath: NavigationPath) {
        guard path.count < oldPath.count else {
            return
        }
        let actionsAfterPopKey = path.count + 1
        actionsAfterPop[actionsAfterPopKey]?()
        actionsAfterPop.removeValue(forKey: actionsAfterPopKey)
    }
}
