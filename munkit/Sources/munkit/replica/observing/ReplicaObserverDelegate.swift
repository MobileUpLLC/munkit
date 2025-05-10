//
//  ReplicaObserverDelegate.swift
//  munkit
//
//  Created by Ilia Chub on 29.04.2025.
//

import Foundation

protocol ReplicaObserverDelegate: Actor {
    func handleObserverAdded(observerId: UUID, isActive: Bool) async
    func handleObserverRemoved(observerId: UUID) async
    func handleObserverActivated(observerId: UUID) async
    func handleObserverDeactivated(observerId: UUID) async
}
