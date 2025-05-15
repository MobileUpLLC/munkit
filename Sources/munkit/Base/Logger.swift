//
//  MUNLogger.swift
//  munkit
//
//  Created by Natalia Luzyanina on 06.05.2025.
//

import os

public protocol MUNLoggable {
    func log(type: OSLogType, _ message: String)
}

public actor MUNLogger {
    public static var shared: MUNLoggable?

    private init() {}

    public static func setupLogger(_ logger: MUNLoggable) {
        shared = logger
    }
}
