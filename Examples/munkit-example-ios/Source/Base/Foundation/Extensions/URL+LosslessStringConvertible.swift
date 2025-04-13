import Foundation

extension URL: @retroactive LosslessStringConvertible {
    var description: String { absoluteString }
    
    public init?(_ description: String) {
        self.init(string: description)
    }
 }
