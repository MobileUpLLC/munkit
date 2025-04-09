//
//  OnceExecutor.swift
//  MUNKit
//
//  Created by Natalia Luzyanina on 01.04.2025.
//

actor NetworkServiceRefreshTokenActionOnceExecutor {
    private var hasRun = false
    private var onTokenRefreshFailed: (() -> Void)?

    func executeTokenRefreshFailed() async {
        guard hasRun == false else {
            return
        }
        hasRun = true
        onTokenRefreshFailed?()

        print("NetworkService. Send onTokenRefreshFailed")
    }
}
