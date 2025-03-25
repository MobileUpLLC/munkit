import Foundation

// SequentialStorage как actor для последовательного выполнения
//actor SequentialStorage<T: AnyObject & Sendable>: Storage {
//    private let originalStorage: any Storage<T>
//    private let additionalLock: (any Storage<T>)?
//
//    init(originalStorage: any Storage<T>, additionalLock: (any Storage<T>)? = nil) {
//        self.originalStorage = originalStorage
//        self.additionalLock = additionalLock
//    }
//
//    func write(data: T) async {
//        await withLock {
//            try await originalStorage.write(data: data)
//        }
//    }
//
//    func read() async -> T? {
//        await withLock {
//            try await originalStorage.read()
//        }
//    }
//
//    func remove() async {
//        await withLock {
//            try await originalStorage.remove()
//        }
//    }
//
//    private func withLock<R>(_ block: () async -> R) async -> R {
//        if let additionalLock {
//            return await additionalLock.withLock(block)
//        } else {
//            return await block()
//        }
//    }
//}
