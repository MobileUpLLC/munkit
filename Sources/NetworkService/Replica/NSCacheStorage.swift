//
//  File.swift
//  NetworkService
//
//  Created by Natalia Luzyanina on 03.04.2025.
//

import Foundation

// Класс-обертка для хранения значений в NSCache (так как NSCache требует AnyObject)
private class CacheWrapper<T: Sendable> {
    let value: T

    init(_ value: T) {
        self.value = value
    }
}

public actor NSCacheStorage<T: Sendable>: Storage {
    private let cache: NSCache<NSString, CacheWrapper<T>>

    public init() {
        self.cache = NSCache<NSString, CacheWrapper<T>>()
        cache.countLimit = 100
        cache.totalCostLimit = 10 * 1024 * 1024
    }

    func read(key: String) async -> T? {
        let nsKey = key as NSString
        if let wrapper = cache.object(forKey: nsKey) {
            return wrapper.value
        }
        return nil
    }

    func write(_ value: T, forKey key: String) async {
        let nsKey = key as NSString
        let wrapper = CacheWrapper(value)
        cache.setObject(wrapper, forKey: nsKey)
    }

    func clear() async {
        cache.removeAllObjects()
    }

    // Для совместимости с базовым протоколом Storage
    public func read() async -> T? {
        await read(key: "defaultKey")
    }

    public func write(data: T) async throws {
        await write(data, forKey: "defaultKey")
    }

    public func remove() async throws {
        cache.removeAllObjects()
    }
}
