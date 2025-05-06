//
//  MUDKitLoggerAdapter.swift
//  munkit-example-core
//
//  Created by Natalia Luzyanina on 06.05.2025.
//

import munkit
import MUDKit
import Foundation

public class MUDKitLoggerAdapter: MUNLoggable {
    private let mudLogger: Log

    public init() {
        let subsystem = Bundle.main.bundleIdentifier ?? ""
        self.mudLogger = Log(subsystem: subsystem, category: "NetworkService")
    }

    public func logDebug(_ message: String) {
        mudLogger.debug(logEntry: .text(message))
    }

    public func logInfo(_ message: String) {
        mudLogger.info(logEntry: .text(message))
    }

    public func logError(_ message: String) {
        mudLogger.error(logEntry: .text(message))
    }
}
