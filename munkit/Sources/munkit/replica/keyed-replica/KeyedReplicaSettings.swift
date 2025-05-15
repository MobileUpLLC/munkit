//
//  KeyedReplicaSettings.swift
//  munkit
//
//  Created by Ilia Chub on 14.05.2025.
//

public struct KeyedReplicaSettings: Sendable {
    let maxCount: Int

    public init(maxCount: Int) {
        self.maxCount = maxCount
    }
}
