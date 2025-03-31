import Foundation

enum Instance: String {
    case debug
    case dev
    case release
    case prod
    
    var isRelease: Bool { self == .release }
}

extension Instance: LosslessStringConvertible {
    var description: String { rawValue }
    
    init?(_ description: String) {
        self.init(rawValue: description)
    }
}

// swiftlint:disable all
final class Environments {
    enum ConfigKey: String, CaseIterable {
        case instance = "INSTANCE"
        case deeplinkScheme = "DEEPLINK_SCHEME"
        case mobileApiUrl = "MOBILE_API_URL"
    }
    
    static var instance: Instance { value(for: .instance)! }
    static var deeplinkScheme: String { value(for: .deeplinkScheme)! }
    static var mobileApiUrl: URL { value(for: .mobileApiUrl)! }
    
    static var isRelease: Bool { instance.isRelease }
    
    static func setup() {
        checkConfiguration()
    }
    
    static func value<T: LosslessStringConvertible>(for key: Environments.ConfigKey) -> T? {
        return try? EnvironmentsConfiguration.value(for: key.rawValue)
    }
    
    private static func checkConfiguration() {
        Log.environments.debug(logEntry: .text("Begin setup environments"))
        
        ConfigKey.allCases.forEach { key in
            EnvironmentsConfiguration.checkValue(for: key.rawValue)
        }
        
        Log.environments.debug(logEntry: .text("End setup environments"))
    }
}
// swiftlint:enable all
