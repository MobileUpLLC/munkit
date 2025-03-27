import Foundation

/// Данные, хранимые в реплике.
struct ReplicaData<T> {
    let value: T
    var isFresh: Bool
    let changingDate: Date
}
