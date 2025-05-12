//
//  DNDMonstersListModel.swift
//  munkit-example-core
//
//  Created by Ilia Chub on 12.05.2025.
//

import Foundation

struct DNDMonstersListModel: Decodable {
    let count: Int
    let results: [DNDMonsterShortModel]
}
