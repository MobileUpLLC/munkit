//
//  Destination.swift
//  munkit-example-ios
//
//  Created by Ilia Chub on 30.04.2025.
//

enum Destination: Hashable {
    case dndClasses(DNDClassesListDestination)
}

enum DNDClassesListDestination: Hashable {
    case dndClassesList
}
