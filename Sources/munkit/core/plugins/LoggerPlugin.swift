//
//  LoggerPlugin.swift
//  MUNKit
//
//  Created by Natalia Luzyanina on 01.04.2025.
//

@preconcurrency import Moya

public actor MUNLoggerPlugin {
    public static let instance = NetworkLoggerPlugin(configuration: configuration)

    private static let configuration = NetworkLoggerPlugin.Configuration(output: defaultOutput, logOptions: .verbose)
    
    private static func defaultOutput(target: TargetType, items: [String]) {
        var logMessage = "🕸️📥📤"

        for item in items {
            logMessage.append(contentsOf: "\n" + item)
        }

        MUNLogger.shared?.log(type: .debug, logMessage)
    }
}
