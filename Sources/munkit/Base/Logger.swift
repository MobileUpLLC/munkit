//
//  MUNLogger.swift
//  munkit
//
//  Created by Natalia Luzyanina on 06.05.2025.
//

public protocol MUNLoggable {
    func logDebug(_ message: String)
    func logInfo(_ message: String)
    func logError(_ message: String)
}

public actor MUNLogger {
    public static var shared: MUNLoggable?

    private init() {}

    public static func setupLogger(_ logger: MUNLoggable) {
        guard shared == nil else {
            return
        }
        shared = logger
    }
}
