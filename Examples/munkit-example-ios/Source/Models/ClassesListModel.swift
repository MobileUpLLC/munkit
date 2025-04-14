import Foundation

struct ClassesListModel: Decodable, Sendable {
    let count: Int
    var results: [ClassModel]
}

struct ClassModel: Decodable, Sendable {
    let index: String
    let name: String
    let url: URL
}
