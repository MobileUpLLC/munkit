import Foundation

/// Данные, хранимые в реплике.
struct ReplicaData<T>: Sendable where T: Sendable {
    let value: T
    var isFresh: Bool
    let changingDate: Date
}
