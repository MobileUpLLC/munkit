//
//  DNDClassModel.swift
//  munkit-example-clt
//
//  Created by Ilia Chub on 11.04.2025.
//

import Foundation

public struct DNDClassModel: Decodable, Sendable {
    public let index: String
    public let name: String
    public let url: URL

    public init(index: String, name: String, url: URL) {
        self.index = index
        self.name = name
        self.url = url
    }
}
