//
//  Logger.swift
//  munkit-example-clt
//
//  Created by Ilia Chub on 13.05.2025.
//

import munkit
import os

struct Logger: MUNLoggable {
    let logger = os.Logger(subsystem: "MUNKit", category: "general")

    func logDebug(_ message: String) {
        logger.debug("\(message)")
    }

    func logInfo(_ message: String) {
        logger.info("\(message)")
    }

    func logError(_ message: String) {
        logger.error("\(message)")
    }
}
