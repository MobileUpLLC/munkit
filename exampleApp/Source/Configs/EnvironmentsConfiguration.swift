import Foundation

enum EnvironmentsConfiguration {
    enum Error: Swift.Error {
        case missingKey
        case invalidValue
        case missingValue
    }
    
    static func value<T: LosslessStringConvertible>(for key: String) throws -> T {
        guard let object = Bundle.main.object(forInfoDictionaryKey: key) else {
            throw Error.missingKey
        }
        guard let string = object as? String, string.isEmpty == false else {
            throw Error.missingValue
        }
        guard let value = T(string) else {
            throw Error.invalidValue
        }
        
        return value
    }
    
    static func checkValue(for key: String) {
        do {
            let stringValue: String = try value(for: key)
            Log.environments.debug(logEntry: .detailed(
                text: "Key was found successfully",
                parameters: [key: stringValue])
            )
        } catch EnvironmentsConfiguration.Error.missingKey {
            Log.environments.debug(logEntry: .text("Missing key: \(key). Add missing key to Info.plist file"))
        } catch EnvironmentsConfiguration.Error.missingValue {
            Log.environments.debug(logEntry: .text("Missing value for key: \(key)"))
        } catch EnvironmentsConfiguration.Error.invalidValue {
            Log.environments.debug(logEntry: .text("Invalid value for key: \(key)"))
        } catch {
            Log.environments.debug(logEntry: .text("Undefined error for key: \(key)"))
        }
    }
}
