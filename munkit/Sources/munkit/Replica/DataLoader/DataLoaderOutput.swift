//
//  DataLoaderOutput.swift
//  munkit
//
//  Created by Ilia Chub on 16.04.2025.
//

enum DataLoaderOutput<T: Sendable> {
    /// Результат чтения из хранилища.
    enum StorageRead {
        case data(T)
        case empty
    }

    /// Результат завершения загрузки.
    enum LoadingFinished {
        case success(T)
        case error(Error)
    }

    case storageRead(StorageRead)
    case loadingFinished(LoadingFinished)
}

extension DataLoaderOutput: CustomStringConvertible {
    var description: String {
        switch self {
        case .storageRead(let read): "Storage read: (read)"
        case .loadingFinished(let finished): "Loading finished: (finished)"
        }
    }
}

extension DataLoaderOutput.StorageRead: CustomStringConvertible {
    var description: String {
        switch self {
        case .data: "Data found"
        case .empty: "No data"
        }
    }
}

extension DataLoaderOutput.LoadingFinished: CustomStringConvertible {
    var description: String {
        switch self {
        case .success: "Success"
        case .error(let error): "Error: (error)"
        }
    }
}
