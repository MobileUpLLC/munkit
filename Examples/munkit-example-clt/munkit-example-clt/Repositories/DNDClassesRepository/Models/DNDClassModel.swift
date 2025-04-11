//
//  DNDClassModel.swift
//  munkit-example-clt
//
//  Created by Ilia Chub on 11.04.2025.
//

import Foundation

struct DNDClassModel: Decodable, Sendable {
    let index: String
    let name: String
    let url: URL
}
