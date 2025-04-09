//
//  OnceExecutor.swift
//  NetworkService
//
//  Created by Natalia Luzyanina on 01.04.2025.
//

actor OnceExecutor {
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
