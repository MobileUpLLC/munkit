//
//  MUNMockablePaginationAPITarget.swift
//  Example
//
//  Created by Ilia Chub on 23.04.2025.
//

import Foundation

public protocol MUNMockablePaginationAPITarget: MUNAPITarget {
    var pageIndexParameterName: String { get }
    var pageSizeParameterName: String { get }
}

extension MUNMockablePaginationAPITarget {
    var sampleData: Data { getSampleData() }

    private func getSampleData() -> Data {
        guard var mockFileName else {
            MUNLogger.shared?.logDebug("🕸️💽🆓 The request \(path) does not use mock data.")
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
