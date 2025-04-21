//
//  KeyedPhysicalReplica.swift
//  munkit
//
//  Created by Natalia Luzyanina on 16.04.2025.
//

import Foundation

public protocol KeyedPhysicalReplica<K, T>: KeyedReplica where K: Hashable & Sendable, T: Sendable {
    var id: String { get }
    var name: String { get }
}
