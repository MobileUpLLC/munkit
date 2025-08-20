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

@globalActor
public actor MUNLogger {
    public static let shared = MUNLogger()

    @MUNLogger
    public static var sharedLoggable: MUNLoggable?

    private init() {}

    @MUNLogger
    public static func setupLogger(_ logger: MUNLoggable) {
        sharedLoggable = logger
    }
}
