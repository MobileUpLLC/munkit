//
//  DNDClassOverviewRepository.swift
//  munkit-example-core
//
//  Created by Natalia Luzyanina on 17.04.2025.
//

import munkit
import Foundation

public actor DNDClassOverviewRepository {
    private let networkService: MUNNetworkService<DNDAPITarget>

    public let replica: any KeyedPhysicalReplica<String, DNDClassOverviewModel>

    public init(networkService: MUNNetworkService<DNDAPITarget>) async {
        self.networkService = networkService
        self.replica = await ReplicaClient.shared.createKeyedReplica(
            name: "DNDClassOverview",
            childName: { name in "DNDClassOverview \(name)" },
            fetcher:  { index in try await networkService.executeRequest(target: .classOverview(index)) }
        )
    }
}
