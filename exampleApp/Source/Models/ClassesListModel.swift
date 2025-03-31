import Foundation

struct ClassesListModel: Decodable {
    let count: Int
    let results: [ClassModel]
}

struct ClassModel: Decodable {
    let index: String
    let name: String
    let url: URL
}
