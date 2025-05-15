//
//  Logger.swift
//  munkit-example-clt
//
//  Created by Ilia Chub on 13.05.2025.
//

import munkit
import os

public struct Logger: MUNLoggable {
    private let logger = os.Logger(subsystem: "MUNKit", category: "general")

    public init() {}

    public func logDebug(_ message: String) {
        logger.debug("\(message)")
    }

    public func logInfo(_ message: String) {
        logger.info("\(message)")
    }

    public func logError(_ message: String) {
        logger.error("\(message)")
    }
}
