//
//  LoggerPlugin.swift
//  NetworkService
//
//  Created by Natalia Luzyanina on 01.04.2025.
//

import Moya

public actor LoggerPlugin {
    public static let instance = NetworkLoggerPlugin(configuration: configuration)

    private static let configuration = NetworkLoggerPlugin.Configuration(output: defaultOutput, logOptions: .verbose)
    
    private static func defaultOutput(target: TargetType, items: [String]) {
        var logMessage = "---------------------------REQUEST START---------------------------\n"

        for item in items {
            logMessage.append(contentsOf: "\n" + item)
        }

        logMessage.append(contentsOf: "\n\n---------------------------REQUEST END-----------------------------\n\n")
        
        print(logMessage)
    }
}
