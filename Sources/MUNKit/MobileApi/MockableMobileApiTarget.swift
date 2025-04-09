//
//  MockableMobileApiTarget.swift
//  NetworkService
//
//  Created by Natalia Luzyanina on 01.04.2025.
//

import Foundation

protocol MockableMobileApiTarget: MUNKMobileApiTargetType {
    var isMockEnabled: Bool { get }
    
    func getMockFileName() -> String?
}

extension MockableMobileApiTarget {
    var sampleData: Data { getSampleData() }

    private func getSampleData() -> Data {
        guard let mockFileName = getMockFileName() else {
            print("💽🆓 Для запроса \(path) моковые данные не используются.")
            return Data()
        }

        return getSampleDataFromFileWithName(mockFileName)
    }
}

protocol MockablePaginationMobileApiTarget: MockableMobileApiTarget {
    var pageIndexParameterName: String { get }
    var pageSizeParameterName: String { get }
}

extension MockablePaginationMobileApiTarget {
    var sampleData: Data { getSampleData() }

    private func getSampleData() -> Data {
        guard var mockFileName = getMockFileName() else {
            print("💽🆓 Для запроса \(path) моковые данные не используются.")
            return Data()
        }

        if
            let pageIndex = parameters[pageIndexParameterName],
            let pageSize = parameters[pageSizeParameterName]
        {
            mockFileName = "\(mockFileName)&PI=\(pageIndex)&PS=\(pageSize)"
        }

        return getSampleDataFromFileWithName(mockFileName)
    }
}

extension MockableMobileApiTarget {
    func getSampleDataFromFileWithName(_ mockFileName: String) -> Data {
        let logStart = "Для запроса \(path) моковые данные"
        let mockExtension = "json"

        guard let mockFileUrl = Bundle.main.url(forResource: mockFileName, withExtension: mockExtension) else {
            print("💽🚨 \(logStart) \(mockFileName).\(mockExtension) не найдены.")
            return Data()
        }

        do {
            let data = try Data(contentsOf: mockFileUrl)
            print("💽✅ \(logStart) успешно прочитаны по URL: \(mockFileUrl).")
            return data
        } catch {
            print("💽🚨\n\(logStart) из файла \(mockFileName).\(mockExtension) невозможно прочитать.\nОшибка: \(error)")
            return Data()
        }
    }
}
