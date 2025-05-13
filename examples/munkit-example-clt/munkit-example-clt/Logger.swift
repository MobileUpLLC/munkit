//
//  Logger.swift
//  munkit-example-clt
//
//  Created by Ilia Chub on 13.05.2025.
//

import munkit

struct Logger: MUNLoggable {
    func logDebug(_ message: String) {
        print(message)
    }

    func logInfo(_ message: String) {
        print(message)
    }

    func logError(_ message: String) {
        print(message)
    }
}
