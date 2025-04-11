//
//  DNDClassesListModel.swift
//  munkit-example-clt
//
//  Created by Ilia Chub on 11.04.2025.
//

import Foundation

struct DNDClassesListModel: Decodable, Sendable {
    let count: Int
    let results: [DNDClassModel]
}
